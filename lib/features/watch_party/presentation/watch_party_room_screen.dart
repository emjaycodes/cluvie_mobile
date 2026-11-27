import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
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

enum _Link { connecting, inRoom, reconnecting, forbidden, signedOut, deleted }

/// A line in the room's feed: a chat message or a reaction.
typedef _Line = ({String key, String userId, String? text, String? emoji});

/// A party's live room (`/watch-parties/:id/live`), over the backend's
/// socket.
///
/// * Who's in the room comes from the join's roster, then joins and leaves.
/// * Reactions (`watchparty:reaction`) and chat (`watchparty:message`, not
///   stored, 500 characters) go to everyone in the room.
/// * The host starts the party and ends it.
/// * A dropped connection keeps retrying with a banner; only a refused
///   token ends the room, and it signs the app out like any expired
///   session.
/// * An ended or cancelled party has no room: it says so and doesn't
///   connect.
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
  bool _unreachable = false;
  bool _opened = false;
  final _here = <String>{};
  final _names = <String, String>{};
  final _lines = <_Line>[];
  int _joinRound = 0;
  int _n = 0;
  bool _busy = false;
  bool _sending = false;
  final _chat = TextEditingController();
  final _chatFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _chat.addListener(() => setState(() {}));
  }

  /// Connects once the party is known to be open (R11-N5).
  void _openIfAllowed(WatchParty p) {
    if (_opened || p.isOver()) return;
    _opened = true;
    scheduleMicrotask(_open);
  }

  Future<void> _open() async {
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

  void _closeLink() {
    _sub?.cancel();
    _sub = null;
    _link?.close();
    _link = null;
  }

  Future<void> _on(RoomEvent e) async {
    final link = _link;
    if (link == null || !mounted) return;
    switch (e) {
      case RoomConnected():
        // Only the latest join counts: a slow answer from before a
        // reconnect must not overwrite a newer one (R11-N1).
        final round = ++_joinRound;
        final join = await link.join();
        if (!mounted || round != _joinRound) return;
        setState(() {
          _unreachable = false;
          switch (join.status) {
            case RoomJoinStatus.ok:
              _state = _Link.inRoom;
              _here
                ..clear()
                ..addAll(join.roster.map((m) => m.userId));
              for (final m in join.roster) {
                if (m.username case final n?) _names[m.userId] = n;
              }
            case RoomJoinStatus.forbidden:
              _state = _Link.forbidden;
            case RoomJoinStatus.failed:
              // Joined again on the next connect; meanwhile, retrying.
              _state = _Link.reconnecting;
          }
        });
      case RoomDisconnected():
        if (_state == _Link.inRoom) setState(() => _state = _Link.reconnecting);
      case RoomConnectFailed(:final unauthorized):
        if (unauthorized) {
          setState(() => _state = _Link.signedOut);
          _closeLink();
          // Same as any expired or revoked session (R11-N4).
          ApiClient.onSessionEnded?.call(ApiException(message: 'Socket unauthorized', statusCode: 401));
        } else if (_state == _Link.connecting || _state == _Link.reconnecting) {
          // The socket keeps retrying by itself; don't give up (R11-S1).
          setState(() => _unreachable = true);
        }
      case RoomPresence(:final userId, :final action, :final username):
        setState(() {
          if (username != null) _names[userId] = username;
          action == 'left' ? _here.remove(userId) : _here.add(userId);
        });
      case RoomReaction(:final userId, :final key):
        _addReaction(userId, key);
      case RoomChat(:final message):
        setState(() {
          if (message.username case final n?) _names[message.userId] = n;
          _addLine((key: message.id, userId: message.userId, text: message.text, emoji: null));
        });
      case RoomPartyChanged():
        ref.invalidate(watchPartyProvider(widget.partyId));
      case RoomPartyDeleted():
        setState(() => _state = _Link.deleted);
        _closeLink();
    }
  }

  void _addLine(_Line line) {
    if (_lines.any((l) => l.key == line.key)) return;
    _lines.insert(0, line);
    if (_lines.length > 100) _lines.removeLast();
  }

  String _nameOf(String userId) {
    final me = ref.read(currentUserIdProvider).valueOrNull;
    if (userId == me) return 'You';
    return _names[userId] ??
        ref.read(watchPartyProvider(widget.partyId)).valueOrNull?.participantNames[userId] ??
        'Someone';
  }

  /// Whether we know a real name for [userId]; an unknown one gets a neutral
  /// avatar with no initials (R11-N3).
  bool _isNamed(String userId) {
    if (userId == ref.read(currentUserIdProvider).valueOrNull) return true;
    return _names.containsKey(userId) ||
        ref.read(watchPartyProvider(widget.partyId)).valueOrNull?.participantNames.containsKey(userId) == true;
  }

  void _addReaction(String userId, String key) {
    final r = kRoomReactions.where((r) => r.$1 == key).firstOrNull;
    if (r == null) return;
    setState(() => _addLine((key: 'r${_n++}', userId: userId, text: null, emoji: r.$2)));
  }

  Future<void> _react(String key) async {
    final link = _link;
    if (_state != _Link.inRoom || link == null) return;
    final error = await link.react(key);
    if (!mounted) return;
    if (error == null) {
      _addReaction(ref.read(currentUserIdProvider).valueOrNull ?? 'me', key);
    } else if (error == 'rate_limited') {
      ClSnackbar.show(context, message: 'Easy there. Give it a second.', type: ClSnackbarType.warning);
    }
  }

  Future<void> _send() async {
    final link = _link;
    final text = _chat.text.trim();
    if (_state != _Link.inRoom || link == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final error = await link.send(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _chat.clear();
      return;
    }
    ClSnackbar.show(
      context,
      message: switch (error) {
        'rate_limited' => "You're sending fast. Wait a moment, then try again.",
        'too_long' => 'Messages can be up to $kRoomMessageMax characters.',
        _ => "Couldn't send. Check your connection and try again.",
      },
      type: ClSnackbarType.error,
    );
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

  @override
  void dispose() {
    _closeLink();
    _chat.dispose();
    _chatFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final party = ref.watch(watchPartyProvider(widget.partyId));
    final me = ref.watch(currentUserIdProvider).valueOrNull;
    if (party.valueOrNull case final p?) _openIfAllowed(p);
    return Scaffold(
      appBar: ClAppBar(title: 'Live room', frosted: true, fallbackRoute: '/watch-parties/${widget.partyId}'),
      body: party.when(
        skipLoadingOnRefresh: true,
        skipError: party.hasValue,
        loading: () => const Center(child: ClSkeleton(height: 120, width: 240)),
        error: (e, _) => _gone(
          title: e is PartyNotFound ? "This watch party doesn't exist" : "Couldn't load this watch party",
          message: e is PartyNotFound ? 'It may have been deleted, or the link is wrong.' : 'Check your connection and try again.',
          action: e is PartyNotFound ? 'See watch parties' : 'Try again',
          onAction: e is PartyNotFound
              ? () => context.go('/watch-parties')
              : () => ref.invalidate(watchPartyProvider(widget.partyId)),
        ),
        data: (p) {
          if (p.isOver()) {
            // A finished party has no room; leave if we were in one.
            if (_link != null) scheduleMicrotask(_closeLink);
            return _gone(
              title: p.status == PartyStatus.cancelled ? 'This party was cancelled' : 'This party has ended',
              message: 'Its live room is closed.',
              action: 'Open the party',
              onAction: () => context.pushReplacement('/watch-parties/${p.id}'),
            );
          }
          return switch (_state) {
            _Link.deleted => _gone(
                title: 'This party was deleted',
                message: 'The host removed it.',
                action: 'See watch parties',
                onAction: () => context.go('/watch-parties'),
              ),
            _Link.forbidden => _gone(
                title: 'Only club members can come in',
                message: 'Join ${p.clubName ?? 'the club'} to be part of its watch parties.',
                action: 'Open club',
                onAction: p.clubId == null ? null : () => context.push('/communities/${p.clubId}'),
              ),
            _Link.signedOut => _gone(
                title: 'Log in to join the room',
                message: 'Your session ended.',
                action: 'Log in',
                onAction: () => context.go('/login'),
              ),
            _ => _room(context, p, me),
          };
        },
      ),
    );
  }

  Widget _gone({required String title, required String message, required String action, VoidCallback? onAction}) =>
      ListView(padding: const EdgeInsets.all(AppSpacing.gutter), children: [
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

  Widget _room(BuildContext context, WatchParty p, String? me) {
    final inRoom = _state == _Link.inRoom;
    final present = <String>[
      if (me != null && inRoom) me,
      for (final id in _here)
        if (id != me) id,
    ];
    final status = switch (_state) {
      _Link.connecting => _unreachable ? "Can't reach the room. Retrying…" : 'Joining the room…',
      _Link.reconnecting => _unreachable ? "Can't reach the room. Retrying…" : 'Connection lost. Reconnecting…',
      _ => null,
    };
    final list = ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.lg),
      children: [
        if (status != null) ...[
          Semantics(liveRegion: true, child: ClStatusBanner(type: ClStatusType.loading, message: status)),
          const SizedBox(height: AppSpacing.lg),
        ],
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
                // The backend records no start time, so say what's true (R11-N6).
                p.status == PartyStatus.live ? 'Live now' : 'Starts ${partyWhen(p.scheduledAt)}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              ),
            ]),
          ),
        ]),
        if (p.isHost(me)) ...[
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
            ClButton(label: 'End party', variant: ClButtonVariant.danger, isLoading: _busy, onPressed: _busy ? null : _confirmEnd),
        ],
        const SizedBox(height: AppSpacing.section),
        Semantics(
          header: true,
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
                  ClAvatar(
                    name: _isNamed(id) ? _nameOf(id) : null,
                    neutral: !_isNamed(id),
                    radius: 24,
                    ring: id == p.hostId,
                  ),
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
        // Reactions only while in the room, so there's no dimmed state (R11-N13).
        if (inRoom) ...[
          const SizedBox(height: AppSpacing.section),
          Semantics(header: true, child: Text('React', style: AppTextStyles.h3)),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            for (final (key, emoji, spoken) in kRoomReactions)
              ClPressable(
                semanticLabel: 'Send $spoken',
                onTap: () => _react(key),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(emoji, style: AppTextStyles.h3),
                ),
              ),
          ]),
        ],
        const SizedBox(height: AppSpacing.section),
        Semantics(header: true, child: Text('Chat', style: AppTextStyles.h3)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Messages aren't saved. There's no shared video: start the film together.",
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_lines.isEmpty)
          Text('No messages yet. Say hi.', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary))
        else
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final l in _lines.take(40)) _ChatLine(name: _nameOf(l.userId), line: l, mine: l.userId == me),
          ]),
      ],
    );
    return Column(children: [
      Expanded(child: list),
      ClChatComposer(
        controller: _chat,
        focusNode: _chatFocus,
        enabled: inRoom,
        sending: _sending,
        onSend: _send,
        hintText: 'Message the room',
        maxLength: kRoomMessageMax,
      ),
    ]);
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.name, required this.line, required this.mine});
  final String name;
  final _Line line;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final text = line.emoji ?? line.text!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: line.emoji != null ? '$name reacted ${line.emoji}' : '$name: ${line.text}',
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '$name  ',
              style: AppTextStyles.label.copyWith(color: mine ? AppColors.purpleText : AppColors.textPrimary),
            ),
            TextSpan(text: breakableTokens(text), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}
