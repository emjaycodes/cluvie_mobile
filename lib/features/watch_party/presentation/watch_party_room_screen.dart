import 'dart:async';

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/watch_party/data/party_room.dart';
import 'package:cluvie_mobile/features/watch_party/data/watch_parties.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/widgets/party_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The reactions anyone in the room can send: key, emoji, spoken name.
const kRoomReactions = [
  ('popcorn', '🍿', 'popcorn'),
  ('laugh', '😂', 'laughing'),
  ('wow', '😮', 'wow'),
  ('cry', '😢', 'crying'),
  ('love', '❤️', 'love'),
  ('clap', '👏', 'applause'),
];

enum _Link { connecting, inRoom, reconnecting, forbidden, failed, signedOut, deleted }

typedef _Reaction = ({int n, String userId, String emoji, String name});

/// A party's live room (`/watch-parties/:id/live`), over the backend's
/// socket (`watchparty:join`, presence, party updates).
///
/// * Shows who's in the room now. The server announces joins and leaves;
///   people already here answer a newcomer's join so it sees them too.
/// * Reactions go to everyone in the room.
/// * The host starts the party (status live) and ends it.
/// * There's no shared video or chat: the backend has no events for them.
///
/// Gold budget: "Start the party" for the host, when shown.
class WatchPartyRoomScreen extends ConsumerStatefulWidget {
  const WatchPartyRoomScreen({super.key, required this.partyId});
  final String partyId;

  @override
  ConsumerState<WatchPartyRoomScreen> createState() => _WatchPartyRoomScreenState();
}

class _WatchPartyRoomScreenState extends ConsumerState<WatchPartyRoomScreen> {
  RoomLink? _link;
  StreamSubscription<RoomEvent>? _sub;
  _Link _state = _Link.connecting;
  final _here = <String>{};
  final _reactions = <_Reaction>[];
  int _n = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _state = _Link.connecting);
    final link = await ref.read(roomLinkFactoryProvider)(widget.partyId);
    if (!mounted) {
      link?.close();
      return;
    }
    if (link == null) {
      setState(() => _state = _Link.signedOut);
      return;
    }
    _link = link;
    _sub = link.events.listen(_on);
    link.connect();
  }

  Future<void> _on(RoomEvent e) async {
    final link = _link;
    if (link == null || !mounted) return;
    switch (e) {
      case RoomConnected():
        final result = await link.join();
        if (!mounted) return;
        setState(() {
          _state = switch (result) {
            RoomJoinResult.ok => _Link.inRoom,
            RoomJoinResult.forbidden => _Link.forbidden,
            RoomJoinResult.failed => _Link.failed,
          };
          _here.clear();
        });
      case RoomDisconnected():
        if (_state == _Link.inRoom) setState(() => _state = _Link.reconnecting);
      case RoomConnectFailed(:final unauthorized):
        if (_state == _Link.connecting || _state == _Link.reconnecting) {
          setState(() => _state = unauthorized ? _Link.signedOut : _Link.failed);
        }
      case RoomPresence(:final userId, :final action):
        if (action == 'left') {
          setState(() => _here.remove(userId));
        } else {
          final isNew = !_here.contains(userId);
          setState(() => _here.add(userId));
          // Let a newcomer know we're here: the server only tells them
          // about people who join after them.
          if (action == 'joined' && isNew) link.here();
          if (action.startsWith(kReactPrefix)) _show(userId, action.substring(kReactPrefix.length));
        }
      case RoomPartyChanged():
        ref.invalidate(watchPartyProvider(widget.partyId));
      case RoomPartyDeleted():
        setState(() => _state = _Link.deleted);
    }
  }

  String _nameOf(String userId) {
    final me = ref.read(currentUserIdProvider).valueOrNull;
    if (userId == me) return 'You';
    final party = ref.read(watchPartyProvider(widget.partyId)).valueOrNull;
    return party?.participantNames[userId] ?? 'A club member';
  }

  void _show(String userId, String key) {
    final r = kRoomReactions.where((r) => r.$1 == key).firstOrNull;
    if (r == null) return;
    final item = (n: _n++, userId: userId, emoji: r.$2, name: _nameOf(userId));
    setState(() {
      _reactions.insert(0, item);
      if (_reactions.length > 6) _reactions.removeLast();
    });
  }

  void _react(String key) {
    if (_state != _Link.inRoom) return;
    _link?.react(key);
    _show(ref.read(currentUserIdProvider).valueOrNull ?? 'me', key);
  }

  Future<void> _setStatus(String status, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    final (ok, refusal) = await setPartyStatus(ref, widget.partyId, status);
    if (!mounted) return;
    setState(() => _busy = false);
    ClSnackbar.show(
      context,
      message: switch (refusal) {
        null => ok?.refreshed == false ? "$done Couldn't refresh the party yet." : done,
        PartyRefusal.notHost => 'Only the host can change this party.',
        _ => "Couldn't update the party. Try again.",
      },
      type: refusal == null ? ClSnackbarType.success : ClSnackbarType.error,
    );
  }

  void _confirmEnd() => showClDialog(
        context: context,
        title: 'End the party?',
        message: 'It will show as ended for everyone.',
        confirmText: 'End party',
        closeText: 'Keep going',
        showConfirm: true,
        destructive: true,
        onConfirm: () => _setStatus('ended', 'Party ended.'),
      );

  void _retry() {
    _sub?.cancel();
    _link?.close();
    _link = null;
    _open();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _link?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final party = ref.watch(watchPartyProvider(widget.partyId));
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: ClAppBar(title: 'Live room', frosted: true, fallbackRoute: '/watch-parties/${widget.partyId}'),
      body: party.when(
        skipLoadingOnRefresh: true,
        skipError: party.hasValue,
        loading: () => const Center(child: ClSkeleton(height: 120, width: 240)),
        error: (e, _) => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
          const SizedBox(height: AppSpacing.xxl),
          if (e is PartyNotFound)
            ClEmptyState(
              illustration: ClIllustration.parties,
              title: "This watch party doesn't exist",
              message: 'It may have been deleted, or the link is wrong.',
              actionLabel: 'See watch parties',
              actionVariant: ClButtonVariant.secondary,
              onAction: () => context.go('/watch-parties'),
            )
          else
            ClErrorState(title: "Couldn't load this watch party", onRetry: () => ref.invalidate(watchPartyProvider(widget.partyId))),
        ]),
        data: (p) {
          final status = switch (_state) {
            _Link.connecting => const _Banner(text: 'Joining the room…', loading: true),
            _Link.reconnecting => const _Banner(text: 'Connection lost. Reconnecting…', loading: true),
            _ => null,
          };
          if (_state == _Link.deleted) {
            return _Gone(
              title: 'This party was deleted',
              message: 'The host removed it.',
              action: 'See watch parties',
              onAction: () => context.go('/watch-parties'),
            );
          }
          if (_state == _Link.forbidden) {
            return _Gone(
              title: 'Only club members can come in',
              message: 'Join ${p.clubName ?? 'the club'} to be part of its watch parties.',
              action: 'Open club',
              onAction: p.clubId == null ? null : () => context.push('/communities/${p.clubId}'),
            );
          }
          if (_state == _Link.failed || _state == _Link.signedOut) {
            return ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
              const SizedBox(height: AppSpacing.xxl),
              ClErrorState(
                title: _state == _Link.signedOut ? 'Log in to join the room' : "Couldn't join the room",
                message: _state == _Link.signedOut ? 'Your session ended.' : 'Check your connection and try again.',
                onRetry: _state == _Link.signedOut ? null : _retry,
              ),
            ]);
          }

          final inRoom = _state == _Link.inRoom;
          final present = <String>[
            if (me != null && inRoom) me,
            for (final id in _here)
              if (id != me) id,
          ];
          final host = p.isHost(me);
          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
            children: [
              if (status != null) ...[status, const SizedBox(height: AppSpacing.lg)],
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (MediaQuery.textScalerOf(context).scale(1) <= 1.6) ...[
                  ClPosterImage(url: p.film?.posterUrl('w342'), width: 72, height: 108, radius: AppRadius.md),
                  const SizedBox(width: AppSpacing.lg),
                ],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (partyBadge(p, me) case final badge?) ...[badge, const SizedBox(height: AppSpacing.sm)],
                    Semantics(
                      header: true,
                      child: FitWordsText(p.title, styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      p.status == PartyStatus.live ? 'Started · ${partyWhen(p.scheduledAt)}' : 'Starts ${partyWhen(p.scheduledAt)}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                    ),
                  ]),
                ),
              ]),
              if (host && !p.isOver()) ...[
                const SizedBox(height: AppSpacing.xl),
                if (p.status == PartyStatus.scheduled)
                  ClButton(
                    label: 'Start the party',
                    icon: AppIcons.play,
                    variant: ClButtonVariant.primary,
                    isLoading: _busy,
                    onPressed: _busy ? null : () => _setStatus('live', "You're live. Everyone in the room can see it."),
                  )
                else
                  ClButton(
                    label: 'End party',
                    variant: ClButtonVariant.danger,
                    isLoading: _busy,
                    onPressed: _busy ? null : _confirmEnd,
                  ),
              ] else if (p.isOver()) ...[
                const SizedBox(height: AppSpacing.xl),
                ClStatusBanner(
                  type: ClStatusType.warning,
                  message: p.status == PartyStatus.cancelled ? 'This party was cancelled.' : 'This party has ended.',
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(inRoom ? 'In the room (${present.length})' : 'In the room', style: AppTextStyles.h3),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.md, children: [
                for (final id in present)
                  Semantics(
                    label: _nameOf(id),
                    excludeSemantics: true,
                    child: SizedBox(
                      width: 72,
                      child: Column(children: [
                        ClAvatar(name: _nameOf(id), radius: 24, ring: id == p.hostId),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _nameOf(id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: AppSpacing.section),
              Semantics(header: true, child: Text('React', style: AppTextStyles.h3)),
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                for (final (key, emoji, spoken) in kRoomReactions)
                  ClPressable(
                    semanticLabel: 'Send $spoken',
                    onTap: inRoom ? () => _react(key) : null,
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Opacity(opacity: inRoom ? 1 : 0.4, child: Text(emoji, style: const TextStyle(fontSize: 24))),
                    ),
                  ),
              ]),
              if (_reactions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  liveRegion: true,
                  label: '${_reactions.first.name} sent ${_reactions.first.emoji}',
                  excludeSemantics: true,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final r in _reactions)
                      ClEntrance(
                        key: ValueKey(r.n),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text('${r.emoji}  ${r.name}', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                        ),
                      ),
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              Text(
                "There's no shared video yet: start the film together, and react here.",
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.loading = false});
  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: ClStatusBanner(type: loading ? ClStatusType.loading : ClStatusType.warning, message: text),
      );
}

class _Gone extends StatelessWidget {
  const _Gone({required this.title, required this.message, required this.action, this.onAction});
  final String title;
  final String message;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
        const SizedBox(height: AppSpacing.xxl),
        ClEmptyState(
          illustration: ClIllustration.parties,
          title: title,
          message: message,
          actionLabel: onAction == null ? null : action,
          actionVariant: ClButtonVariant.secondary,
          onAction: onAction,
        ),
      ]);
}
