import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/watch_party/data/watch_parties.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/widgets/party_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One watch party (`/watch-parties/:id`): what, when, which club, who's
/// going, and your RSVP.
///
/// * "I'm going" / "Can't make it" are `POST /watchparties/:id/join|leave`.
///   Only club members can join (403 → a prompt to join the club).
/// * The host can't leave; they can cancel the party instead.
/// * Demo ids (not Mongo ids) say the party doesn't exist, without a request.
///
/// * Once the room is open ([canEnterRoom]: live, starting within 30
///   minutes, or you're the host), people going get "Enter live room".
///
/// Gold budget: "I'm going" or "Enter live room", never both.
class WatchPartyDetailScreen extends ConsumerStatefulWidget {
  const WatchPartyDetailScreen({super.key, required this.partyId});
  final String partyId;

  @override
  ConsumerState<WatchPartyDetailScreen> createState() => _WatchPartyDetailScreenState();
}

class _WatchPartyDetailScreenState extends ConsumerState<WatchPartyDetailScreen> {
  bool _busy = false;
  bool _refusedNotMember = false;

  /// Runs an RSVP or host action. Busy until the party has reloaded, so
  /// the old action can't be tapped again in between (R10-S4).
  Future<void> _run(Future<PartyResult> Function() action, String success, WatchParty party) async {
    if (_busy) return;
    setState(() => _busy = true);
    final (done, refusal) = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (refusal == PartyRefusal.notMember) _refusedNotMember = true;
    });
    final club = party.clubName ?? 'the club';
    final (message, type) = switch (refusal) {
      null when done?.refreshed == false => ("$success Couldn't refresh the party yet.", ClSnackbarType.warning),
      null => (success, ClSnackbarType.success),
      PartyRefusal.notMember => ('Only members of $club can RSVP. Join the club first.', ClSnackbarType.warning),
      PartyRefusal.notHost => ('Only the host can change this party.', ClSnackbarType.warning),
      PartyRefusal.hostCannotLeave => ("You're hosting, so you can't drop out. Cancel the party instead.", ClSnackbarType.warning),
      PartyRefusal.closed => ('This party has already ended or was cancelled.', ClSnackbarType.warning),
      PartyRefusal.notFound => ('This party no longer exists.', ClSnackbarType.error),
      PartyRefusal.failed => ("Couldn't update the party. Try again.", ClSnackbarType.error),
    };
    ClSnackbar.show(context, message: message, type: type);
    if (refusal == PartyRefusal.closed || refusal == PartyRefusal.notFound) {
      ref.invalidate(watchPartyProvider(widget.partyId));
    }
  }

  void _confirmCancel(WatchParty party) => showClDialog(
        context: context,
        title: 'Cancel ${party.title}?',
        message: "Everyone who's going will see it as cancelled. You can't undo this.",
        confirmText: 'Cancel party',
        closeText: 'Keep it',
        showConfirm: true,
        destructive: true,
        onConfirm: () => _run(() => cancelParty(ref, party.id), 'Party cancelled.', party),
      );

  Future<void> _refresh() async {
    final had = ref.read(watchPartyProvider(widget.partyId)).hasValue;
    ref.invalidate(watchPartyProvider(widget.partyId));
    try {
      await ref.read(watchPartyProvider(widget.partyId).future);
    } catch (_) {
      if (had && mounted) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier details.", type: ClSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final party = ref.watch(watchPartyProvider(widget.partyId));
    return Scaffold(
      appBar: const ClAppBar(title: 'Watch party', frosted: true, fallbackRoute: '/watch-parties'),
      body: party.when(
        skipLoadingOnRefresh: party.hasValue,
        skipError: party.hasValue,
        loading: () => Semantics(
          label: 'Loading watch party',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: const [
              ClSkeleton(height: 180),
              SizedBox(height: AppSpacing.lg),
              ClSkeleton(height: 28, width: 220),
              SizedBox(height: AppSpacing.md),
              ClSkeleton(height: 72),
            ],
          ),
        ),
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
            ClErrorState(
              title: "Couldn't load this watch party",
              onRetry: () => ref.invalidate(watchPartyProvider(widget.partyId)),
            ),
        ]),
        data: (p) => RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.purple,
          backgroundColor: AppColors.surfaceRaised,
          child: _Body(
            party: p,
            busy: _busy,
            refusedNotMember: _refusedNotMember,
            onGoing: () => _run(() => joinParty(ref, p.id), "You're going. See you there!", p),
            onNotGoing: () => _run(() => leaveParty(ref, p.id), "Got it. You're not going.", p),
            onCancel: () => _confirmCancel(p),
            onEnd: () => showClDialog(
              context: context,
              title: 'End ${p.title}?',
              message: 'It will show as ended for everyone.',
              confirmText: 'End party',
              closeText: 'Keep going',
              showConfirm: true,
              destructive: true,
              onConfirm: () => _run(() => setPartyStatus(ref, p.id, 'ended'), 'Party ended.', p),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.party,
    required this.busy,
    required this.refusedNotMember,
    required this.onGoing,
    required this.onNotGoing,
    required this.onCancel,
    required this.onEnd,
  });

  final WatchParty party;
  final bool busy;
  final bool refusedNotMember;
  final VoidCallback onGoing;
  final VoidCallback onNotGoing;
  final VoidCallback onCancel;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = party;
    final meAsync = ref.watch(currentUserIdProvider);
    final me = meAsync.valueOrNull;
    final clubId = p.clubId;
    final membership = clubId == null ? ClubMembership.unknown : ref.watch(clubMembershipProvider(clubId));
    final notMember = refusedNotMember || membership == ClubMembership.notMember;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final badge = partyBadge(p, me);
    final roomy = MediaQuery.textScalerOf(context).scale(1) <= 1.6;

    final names = [
      for (final id in p.participantIds)
        if (id == me) 'You' else if (p.participantNames[id] case final n?) n,
    ];
    final unnamed = p.participantIds.length - names.length;

    final Widget? enterRoom = canEnterRoom(p, me)
        ? ClButton(
            label: 'Enter live room',
            icon: AppIcons.play,
            variant: ClButtonVariant.primary,
            onPressed: () => context.push('/watch-parties/${p.id}/live'),
          )
        : null;
    final Widget action;
    if (p.isOver()) {
      action = ClStatusBanner(
        type: ClStatusType.warning,
        message: p.status == PartyStatus.cancelled ? 'This party was cancelled.' : 'This party has ended.',
      );
    } else if (me == null || me.isEmpty) {
      // Without your id we can't tell host from guest: offer nothing
      // rather than a wrong RSVP (R10-S6).
      action = meAsync.isLoading
          ? const ClSkeleton(height: 48)
          : ClErrorState(
              title: "Couldn't check your RSVP",
              compact: true,
              onRetry: () => ref.invalidate(currentUserIdProvider),
            );
    } else if (p.isHost(me)) {
      action = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text("You're hosting this party.", style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        if (enterRoom != null) ...[enterRoom, const SizedBox(height: AppSpacing.sm)],
        // A party in progress is ended, not cancelled (R11-N7).
        if (p.status == PartyStatus.live)
          ClButton(label: 'End party', variant: ClButtonVariant.danger, isLoading: busy, onPressed: busy ? null : onEnd)
        else
          ClButton(
            label: 'Cancel party',
            variant: ClButtonVariant.danger,
            isLoading: busy,
            onPressed: busy ? null : onCancel,
          ),
      ]);
    } else if (p.isGoing(me)) {
      final notGoing = ClButton(
        label: "Can't make it",
        variant: ClButtonVariant.secondary,
        isLoading: busy,
        onPressed: busy ? null : onNotGoing,
      );
      action = enterRoom == null
          ? notGoing
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              enterRoom,
              const SizedBox(height: AppSpacing.sm),
              notGoing,
            ]);
    } else if (notMember && clubId != null) {
      action = ClCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            'Only members of ${p.clubName ?? 'this club'} can RSVP.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          ClButton(
            label: 'Open club',
            icon: AppIcons.clubs,
            variant: ClButtonVariant.secondary,
            onPressed: () => context.push('/communities/$clubId'),
          ),
        ]),
      );
    } else {
      action = ClButton(
        label: "I'm going",
        icon: AppIcons.ticket,
        variant: ClButtonVariant.primary,
        isLoading: busy,
        onPressed: busy ? null : onGoing,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (roomy) ...[
            ClPosterImage(url: p.film?.posterUrl('w342'), width: 96, height: 144, radius: AppRadius.md),
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (badge != null) ...[badge, const SizedBox(height: AppSpacing.sm)],
              Semantics(
                header: true,
                child: FitWordsText(p.title, styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
              ),
              if (p.film != null && p.film!.title != p.title) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(p.film!.title, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        ClCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: Column(children: [
            _Fact(icon: AppIcons.calendar, label: 'When', value: partyWhen(p.scheduledAt)),
            if (p.clubName != null || clubId != null) ...[
              const Divider(height: 1, color: AppColors.border),
              _Fact(
                icon: AppIcons.clubs,
                label: 'Club',
                value: p.clubName ?? 'Open club',
                onTap: clubId == null ? null : () => context.push('/communities/$clubId'),
              ),
            ],
            if (p.hostName != null) ...[
              const Divider(height: 1, color: AppColors.border),
              _Fact(icon: AppIcons.crown, label: 'Host', value: p.isHost(me) ? 'You' : p.hostName!),
            ],
            if (p.isPrivate) ...[
              const Divider(height: 1, color: AppColors.border),
              const _Fact(icon: AppIcons.lock, label: 'Visibility', value: 'Club members only'),
            ],
          ]),
        ),
        if (p.description != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(p.description!, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: AppSpacing.xl),
        action,
        const SizedBox(height: AppSpacing.section),
        Semantics(
          header: true,
          child: Text('${p.participantIds.length} going', style: AppTextStyles.h3),
        ),
        const SizedBox(height: AppSpacing.md),
        if (names.isEmpty && unnamed == 0)
          Text('No one yet. Be the first.', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary))
        else
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            for (final n in names) ClChip(label: n),
            if (unnamed > 0) ClChip(label: names.isEmpty ? '$unnamed people' : '+$unnamed more'),
          ]),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value, this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.purpleText),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            Text(value, style: AppTextStyles.label),
          ]),
        ),
        if (onTap != null) const Icon(AppIcons.forward, size: 18, color: AppColors.textSecondary),
      ]),
    );
    if (onTap == null) return Semantics(label: '$label: $value', excludeSemantics: true, child: row);
    return ClPressable(semanticLabel: '$label: $value', onTap: onTap, child: row);
  }
}
