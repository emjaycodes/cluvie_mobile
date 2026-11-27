import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/utils/relative_time.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/club_chat.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Club chat (`/communities/:id/chat`): stored messages, members only.
///
/// * History: `GET /communities/:id/messages`, newest at the bottom, with
///   "Load older" for earlier pages.
/// * Live: the socket's `club:message` / `club:message_deleted`. After a
///   reconnect the latest page is fetched again, so nothing is missed.
/// * Send and delete go over REST, so they work while the socket is
///   reconnecting. The sender or a club admin can delete (long press).
///
/// Gold budget: none (the Send button is purple, like the party room).
class ClubChatScreen extends ConsumerWidget {
  const ClubChatScreen({super.key, required this.communityId});
  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClubScaffold(
      communityId: communityId,
      title: 'Club chat',
      builder: (context, club) => membershipIn(ref, club) == ClubMembership.notMember
          ? _MembersOnly(club: club)
          : _ChatBody(club: club),
    );
  }
}

class _MembersOnly extends StatelessWidget {
  const _MembersOnly({required this.club});
  final Community club;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
        const SizedBox(height: AppSpacing.xxl),
        ClEmptyState(
          illustration: ClIllustration.discussions,
          title: 'Chat is for members',
          message: 'Join ${club.displayName} to talk with the club.',
          actionLabel: 'Open club',
          actionVariant: ClButtonVariant.secondary,
          onAction: () => context.pushReplacement('/communities/${club.id}'),
        ),
      ]);
}

enum _Load { loading, ready, failed, forbidden }

enum _Live { connecting, live, reconnecting, off }

class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({required this.club});
  final Community club;

  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody> {
  /// Newest first (the list is reversed, so newest shows at the bottom).
  final _messages = <ClubMessage>[];
  _Load _load = _Load.loading;
  _Live _live = _Live.connecting;
  bool _hasMore = false;
  bool _loadingOlder = false;
  bool _wasLive = false;
  bool _sending = false;
  bool _opening = false;
  int _joinRound = 0;
  ClubChatLink? _link;
  StreamSubscription<ClubChatEvent>? _sub;
  final _text = TextEditingController();
  final _focus = FocusNode();

  String get _id => widget.club.id!;
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _loadLatest();
  }

  @override
  void dispose() {
    _closeLink();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ---- History ----

  /// Adds messages (deduped by id) and keeps newest first.
  void _merge(Iterable<ClubMessage> incoming) {
    final known = {for (final m in _messages) m.id};
    _messages.addAll(incoming.where((m) => known.add(m.id)));
    _messages.sort((a, b) {
      final t = b.createdAt.compareTo(a.createdAt);
      return t != 0 ? t : b.id.compareTo(a.id);
    });
  }

  /// The newest page. First time: the whole list. After a reconnect: merged
  /// in, so anything sent while offline shows up.
  Future<void> _loadLatest() async {
    final first = _messages.isEmpty && _load != _Load.ready;
    if (first) setState(() => _load = _Load.loading);
    try {
      final page = await fetchClubMessages(_api, _id);
      if (!mounted) return;
      setState(() {
        if (first) _hasMore = page.hasMore;
        _merge(page.messages);
        _load = _Load.ready;
      });
      // Live updates start once history is in, so a non-member (403) never
      // opens a socket.
      if (_link == null && _live == _Live.connecting) unawaited(_openLink());
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        setState(() => _load = _Load.forbidden);
      } else if (first) {
        setState(() => _load = _Load.failed);
      }
    } catch (_) {
      if (mounted && first) setState(() => _load = _Load.failed);
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || !_hasMore || _messages.isEmpty) return;
    setState(() => _loadingOlder = true);
    try {
      final page = await fetchClubMessages(_api, _id, before: _messages.last.id);
      if (!mounted) return;
      setState(() {
        _merge(page.messages);
        _hasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) ClSnackbar.show(context, message: "Couldn't load older messages.", type: ClSnackbarType.error);
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  // ---- Live ----

  Future<void> _openLink() async {
    if (_link != null || _opening) return;
    _opening = true;
    final link = await ref.read(clubChatLinkFactoryProvider)(_id);
    _opening = false;
    if (!mounted) {
      link?.close();
      return;
    }
    if (link == null) {
      setState(() => _live = _Live.off);
      return;
    }
    _link = link;
    _sub = link.events.listen(_on);
    link.connect();
  }

  void _closeLink() {
    _sub?.cancel();
    _sub = null;
    _link?.close();
    _link = null;
  }

  Future<void> _on(ClubChatEvent e) async {
    final link = _link;
    if (link == null || !mounted) return;
    switch (e) {
      case ChatConnected():
        // Only the latest join counts (a slow answer from before a reconnect
        // must not overwrite a newer one).
        final round = ++_joinRound;
        final status = await link.join();
        if (!mounted || round != _joinRound) return;
        switch (status) {
          case ChatJoinStatus.ok:
            final catchUp = _wasLive;
            _wasLive = true;
            setState(() => _live = _Live.live);
            if (catchUp) unawaited(_loadLatest());
          case ChatJoinStatus.forbidden:
            setState(() => _load = _Load.forbidden);
            _closeLink();
          case ChatJoinStatus.failed:
            setState(() => _live = _Live.reconnecting);
        }
      case ChatDisconnected():
        if (_live == _Live.live) setState(() => _live = _Live.reconnecting);
      case ChatConnectFailed(:final unauthorized):
        if (unauthorized) {
          setState(() => _live = _Live.off);
          _closeLink();
          ApiClient.onSessionEnded?.call(ApiException(message: 'Socket unauthorized', statusCode: 401));
        } else if (_wasLive) {
          setState(() => _live = _Live.reconnecting);
        }
      case ChatIncoming(:final message):
        setState(() => _merge([message]));
      case ChatDeleted(:final messageId):
        setState(() => _messages.removeWhere((m) => m.id == messageId));
    }
  }

  // ---- Actions ----

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending || _load != _Load.ready) return;
    setState(() => _sending = true);
    try {
      final m = await sendClubMessage(_api, _id, text);
      if (!mounted) return;
      _text.clear();
      setState(() => _merge([m]));
    } on ApiException catch (e) {
      if (!mounted) return;
      final code = e.responseBody is Map ? (e.responseBody as Map)['code'] : null;
      if (e.statusCode == 403) {
        setState(() => _load = _Load.forbidden);
        return;
      }
      ClSnackbar.show(
        context,
        message: code == 'MESSAGE_TOO_LONG'
            ? 'Messages can be up to $kClubMessageMax characters.'
            : "Couldn't send. Check your connection and try again.",
        type: ClSnackbarType.error,
      );
    } catch (_) {
      if (mounted) ClSnackbar.show(context, message: "Couldn't send. Check your connection and try again.", type: ClSnackbarType.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _confirmDelete(ClubMessage m) {
    showClDialog(
      context: context,
      title: 'Delete this message?',
      message: 'It will be removed for everyone in the club.',
      confirmText: 'Delete',
      closeText: 'Cancel',
      showConfirm: true,
      destructive: true,
      onConfirm: () => _delete(m),
    );
  }

  Future<void> _delete(ClubMessage m) async {
    final index = _messages.indexWhere((x) => x.id == m.id);
    if (index < 0) return;
    setState(() => _messages.removeAt(index));
    try {
      await deleteClubMessage(_api, _id, m.id);
    } on ApiException catch (e) {
      // Already gone counts as deleted.
      if (e.statusCode == 404) return;
      _undoDelete(m);
    } catch (_) {
      _undoDelete(m);
    }
  }

  void _undoDelete(ClubMessage m) {
    if (!mounted) return;
    setState(() => _merge([m]));
    ClSnackbar.show(context, message: "Couldn't delete the message. Try again.", type: ClSnackbarType.error);
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    final admin = widget.club.isAdmin(me);

    final Widget body = switch (_load) {
      _Load.loading => Semantics(
          label: 'Loading messages',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: const [
              ClSkeleton(height: 48, width: 220),
              SizedBox(height: AppSpacing.md),
              Align(alignment: Alignment.centerRight, child: ClSkeleton(height: 48, width: 180)),
              SizedBox(height: AppSpacing.md),
              ClSkeleton(height: 64, width: 260),
            ],
          ),
        ),
      _Load.failed => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
          const SizedBox(height: AppSpacing.xxl),
          ClErrorState(title: "Couldn't load the chat", onRetry: _loadLatest),
        ]),
      _Load.forbidden => _MembersOnly(club: widget.club),
      _Load.ready => _messages.isEmpty
          ? ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
              const SizedBox(height: AppSpacing.xxl),
              ClEmptyState(
                illustration: ClIllustration.discussions,
                title: 'No messages yet',
                message: 'Say hi to ${widget.club.displayName}.',
              ),
            ])
          : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
              itemCount: _messages.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Center(
                      child: ClButton(
                        label: 'Load older messages',
                        variant: ClButtonVariant.ghost,
                        size: ClButtonSize.sm,
                        expand: false,
                        isLoading: _loadingOlder,
                        onPressed: _loadingOlder ? null : _loadOlder,
                      ),
                    ),
                  );
                }
                final m = _messages[i];
                final mine = m.userId != null && m.userId == me;
                // The name shows on the first of a run of messages from one sender
                // (the list is reversed, so "previous" on screen is i + 1).
                final prev = i + 1 < _messages.length ? _messages[i + 1] : null;
                final showName = !mine && (prev == null || prev.userId != m.userId);
                return _Bubble(
                  message: m,
                  mine: mine,
                  showName: showName,
                  onDelete: mine || admin ? () => _confirmDelete(m) : null,
                );
              },
            ),
    };

    return Column(children: [
      if (_live == _Live.reconnecting && _load == _Load.ready)
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
          child: ClStatusBanner(type: ClStatusType.loading, message: 'Reconnecting. New messages will appear when you\'re back.'),
        ),
      Expanded(child: body),
      if (_load != _Load.forbidden)
        ClChatComposer(
          controller: _text,
          focusNode: _focus,
          enabled: _load == _Load.ready,
          sending: _sending,
          onSend: _send,
          hintText: 'Message the club',
          disabledHint: _load == _Load.failed ? 'Chat unavailable' : 'Loading…',
          maxLength: kClubMessageMax,
        ),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, required this.showName, this.onDelete});
  final ClubMessage message;
  final bool mine;
  final bool showName;

  /// Null when the viewer can't delete it.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final name = mine ? 'You' : (message.username ?? 'Deleted account');
    final when = timeAgo(message.createdAt);
    final bubble = Container(
      // Large text gets the full width, so long words don't break mid-word.
      constraints: BoxConstraints(
        maxWidth: MediaQuery.textScalerOf(context).scale(1) >= 1.5 ? double.infinity : MediaQuery.sizeOf(context).width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: mine ? AppColors.purpleBadge : AppColors.surfaceRaised,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(
          breakableTokens(message.text),
          style: AppTextStyles.body.copyWith(color: mine ? AppColors.onPurpleBadge : AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          when,
          style: AppTextStyles.caption.copyWith(color: mine ? AppColors.onPurpleBadge : AppColors.textSecondary),
        ),
      ]),
    );

    return Padding(
      padding: EdgeInsets.only(top: showName ? AppSpacing.md : AppSpacing.xs),
      child: Semantics(
        container: true,
        label: '$name, ${timeAgoSpoken(message.createdAt)}: ${message.text}',
        excludeSemantics: true,
        onLongPressHint: onDelete == null ? null : 'Delete message',
        onLongPress: onDelete,
        child: GestureDetector(
          onLongPress: onDelete,
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showName)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xxs),
                  child: Text(name, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ),
              bubble,
            ],
          ),
        ),
      ),
    );
  }
}
