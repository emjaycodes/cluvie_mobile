import 'dart:async';

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/utils/relative_time.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A club's vote (`/communities/:id/vote`): its open polls from
/// `GET /polls/active`.
///
/// * One vote per poll (unless the poll allows several), and a vote can't be
///   changed; the screen says so above the options.
/// * Voting is optimistic and rolls back on failure. "Already voted" and
///   "poll closed" reload the poll and say why.
/// * Rows keep their order while the screen is open, so a row never jumps
///   from under a finger; pull to refresh re-ranks them.
/// * The countdown ticks; at zero the poll shows as closed.
/// * Tapping a film opens Movie Detail.
///
/// Gold budget: the leading film's badge.
class VoteSummaryScreen extends ConsumerStatefulWidget {
  const VoteSummaryScreen({super.key, required this.communityId, this.clubName});

  final String communityId;

  /// Club name for the title, when the opener knew it.
  final String? clubName;

  @override
  ConsumerState<VoteSummaryScreen> createState() => _VoteSummaryScreenState();
}

class _VoteSummaryScreenState extends ConsumerState<VoteSummaryScreen> {
  Timer? _tick;

  /// Polls with votes cast here, until the next reload.
  final _local = <String, Poll>{};

  /// Row order per poll, fixed at load so rows don't jump.
  final _order = <String, List<String>>{};
  final _voting = <String>{};

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// Refetches the polls. With polls on screen they stay put while this
  /// runs, and stay if it fails (with a snackbar saying so); local votes and
  /// the frozen row order reset only once fresh data arrives.
  Future<void> _reload() async {
    final provider = activePollsProvider(widget.communityId);
    final hadPolls = ref.read(provider).hasValue;
    try {
      ref.invalidate(provider);
      await ref.read(provider.future);
      if (!mounted) return;
      setState(() {
        _local.clear();
        _order.clear();
      });
    } catch (_) {
      // With nothing on screen the error state says it.
      if (mounted && hadPolls) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing the earlier vote.", type: ClSnackbarType.error);
      }
    }
  }

  Poll _current(Poll p) => _local[p.id] ?? p;

  List<PollOption> _rows(Poll poll) {
    final order = _order.putIfAbsent(poll.id, () => [for (final o in poll.ranked) o.id]);
    final byId = {for (final o in poll.options) o.id: o};
    return [for (final id in order) if (byId[id] != null) byId[id]!];
  }

  bool _joining = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    final refusal = await joinClub(ref, widget.communityId);
    if (!mounted) return;
    setState(() => _joining = false);
    final club = widget.clubName ?? 'the club';
    ClSnackbar.show(
      context,
      message: refusal == null ? 'You joined $club. Cast your vote.' : "Couldn't join $club. Try again.",
      type: refusal == null ? ClSnackbarType.success : ClSnackbarType.error,
    );
  }

  Future<void> _vote(Poll poll, PollOption option) async {
    final me = ref.read(currentUserIdProvider).valueOrNull;
    if (me == null) {
      ClSnackbar.show(context, message: 'Sign in to vote', type: ClSnackbarType.info);
      return;
    }
    final before = _current(poll);
    setState(() {
      _voting.add(poll.id);
      _local[poll.id] = before.replaceOption(option.withVote(me));
    });
    final refusal = await castVote(ref, pollId: poll.id, optionId: option.id);
    if (!mounted) return;
    setState(() => _voting.remove(poll.id));
    switch (refusal) {
      case null:
        ClSnackbar.show(context, message: 'Voted for ${option.title}', type: ClSnackbarType.success);
      case VoteRefusal.alreadyVoted:
        // Refused: undo the optimistic vote now, in case the reload fails.
        setState(() => _local[poll.id] = before);
        ClSnackbar.show(context, message: 'You already voted in this poll', type: ClSnackbarType.info);
        await _reload();
      case VoteRefusal.closed:
        setState(() => _local[poll.id] = before);
        ClSnackbar.show(context, message: 'This poll has closed', type: ClSnackbarType.warning);
        await _reload();
      case VoteRefusal.notMember:
        setState(() => _local[poll.id] = before);
        final club = widget.clubName;
        ClSnackbar.show(
          context,
          message: club == null ? 'Join this club to vote' : 'Join $club to vote',
          type: ClSnackbarType.info,
          actionLabel: 'Open club',
          onAction: () {
            if (mounted) context.push('/communities/${widget.communityId}');
          },
        );
      case VoteRefusal.failed:
        setState(() => _local[poll.id] = before);
        ClSnackbar.show(
          context,
          message: "Couldn't count your vote. Try again.",
          type: ClSnackbarType.error,
          actionLabel: 'Retry',
          // The snackbar can outlive the screen; then there's nothing to retry.
          onAction: () {
            if (mounted) _vote(poll, option);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final polls = ref.watch(activePollsProvider(widget.communityId));
    final meAsync = ref.watch(currentUserIdProvider);
    final me = meAsync.valueOrNull;
    // Until we know who's voting, voting waits (no false "Sign in to vote",
    // no Vote buttons flashing for people who already voted).
    final resolvingMe = meAsync.isLoading && !meAsync.hasValue;
    final title = widget.clubName != null ? '${widget.clubName} vote' : 'Club vote';
    // Non-members get one "Join" card instead of Vote buttons that can only
    // be refused. Unknown (loading, failed) keeps the buttons: the server
    // still answers 403 with "Join … to vote".
    final notMember = ref.watch(clubMembershipProvider(widget.communityId)) == ClubMembership.notMember;
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget scroll(List<Widget> children) => RefreshIndicator(
          onRefresh: _reload,
          color: AppColors.purple,
          backgroundColor: AppColors.surfaceRaised,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
            children: children,
          ),
        );

    return Scaffold(
      appBar: ClAppBar(title: title, frosted: true, fallbackRoute: '/communities/${widget.communityId}'),
      // With polls on screen, refreshing or a failed refresh keeps them.
      // Without, a retry shows the skeleton so the tap visibly works.
      body: polls.when(
        skipLoadingOnRefresh: polls.hasValue,
        skipError: true,
        loading: () => Semantics(
          label: 'Loading the vote',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              const ClSkeleton(width: 220, height: 24),
              const SizedBox(height: AppSpacing.md),
              const ClSkeleton(width: 160, height: 14),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < 3; i++) ...[
                const ClSkeletonRow(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
        error: (_, __) => scroll([
          const SizedBox(height: AppSpacing.xxl),
          ClErrorState(title: "Couldn't load the vote", onRetry: _reload),
        ]),
        data: (list) {
          if (list.isEmpty) {
            return scroll([
              const SizedBox(height: AppSpacing.xxl),
              ClEmptyState(
                illustration: ClIllustration.polls,
                title: 'No vote running',
                message: 'No active polls — suggest a film!',
                actionLabel: 'Suggest a film',
                actionVariant: ClButtonVariant.secondary,
                onAction: () => context.push('/communities/${widget.communityId}/suggest'),
              ),
            ]);
          }
          return scroll([
            if (notMember) ...[
              _JoinToVote(clubName: widget.clubName, joining: _joining, onJoin: _join),
              const SizedBox(height: AppSpacing.section),
            ],
            for (final (i, p) in list.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.section),
              _PollSection(
                poll: _current(p),
                rows: _rows(_current(p)),
                me: me,
                busy: _voting.contains(p.id) || resolvingMe,
                member: !notMember,
                onVote: (o) => _vote(p, o),
                showGold: i == 0,
              ),
            ],
          ]);
        },
      ),
    );
  }
}

class _PollSection extends StatelessWidget {
  const _PollSection({
    required this.poll,
    required this.rows,
    required this.me,
    required this.busy,
    required this.onVote,
    required this.showGold,
    this.member = true,
  });

  final Poll poll;
  final List<PollOption> rows;
  final String? me;
  final bool busy;
  final ValueChanged<PollOption> onVote;

  /// False when the user is known not to be in the club: no Vote buttons.
  final bool member;

  /// Only the first poll's leader gets the gold badge (gold budget).
  final bool showGold;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final open = poll.isOpenAt(now);
    final left = timeLeft(poll.expiresAt, now: now);
    final voted = poll.hasVoted(me);
    final leader = poll.leader;
    final total = poll.totalVotes;

    final String rule;
    if (!open) {
      rule = 'Voting has closed.';
    } else if (!member) {
      rule = 'Only club members can vote.';
    } else if (poll.allowMultiple) {
      rule = 'Vote for as many films as you like. Votes are final.';
    } else if (voted) {
      rule = "You've voted. Votes are final.";
    } else {
      rule = 'You get one vote, and it’s final.';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(header: true, child: FitWordsText(poll.question, styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title])),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (open && left != null)
            ClBadge('Closes in $left', tone: ClBadgeTone.purple, icon: AppIcons.clock, uppercase: false)
          else
            const ClBadge('Closed', tone: ClBadgeTone.glass, uppercase: false),
          Text(
            '$total ${total == 1 ? 'vote' : 'votes'}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      if (open) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ends ${dayAndTime(poll.expiresAt, now: now, use24h: MediaQuery.alwaysUse24HourFormatOf(context))}',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      Semantics(
        liveRegion: true,
        child: Text(rule, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      ),
      const SizedBox(height: AppSpacing.lg),
      for (final (i, o) in rows.indexed) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        _OptionRow(
          option: o,
          share: total == 0 ? 0 : o.voteCount / total,
          isLeader: leader?.id == o.id,
          leaderLabel: open ? 'Leading' : 'Winner',
          gold: showGold,
          mine: me != null && o.voterIds.contains(me),
          canVote: open && !busy && (poll.allowMultiple ? !(me != null && o.voterIds.contains(me)) : !voted),
          showVote: member && open && (poll.allowMultiple || !voted),
          onVote: () => onVote(o),
        ),
      ],
      if (leader?.movieId != null) ...[
        const SizedBox(height: AppSpacing.lg),
        ClButton(
          label: 'Discuss ${leader!.title}',
          icon: AppIcons.chat,
          variant: ClButtonVariant.ghost,
          onPressed: () => context.push(
            '/discussionThread',
            extra: DiscussionThreadScreen.extraFor(
              movieId: leader.movieId!,
              title: leader.title,
              posterUrl: leader.posterUrl,
              tmdbId: leader.tmdbId,
            ),
          ),
        ),
      ],
    ]);
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.share,
    required this.isLeader,
    required this.leaderLabel,
    required this.gold,
    required this.mine,
    required this.canVote,
    required this.showVote,
    required this.onVote,
  });

  final PollOption option;
  final double share;
  final bool isLeader;
  final String leaderLabel;
  final bool gold;
  final bool mine;
  final bool canVote;
  final bool showVote;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final votes = option.voteCount;
    final votesText = '$votes ${votes == 1 ? 'vote' : 'votes'}';
    // Starts with the visible title (label in name). No rank: none is shown,
    // and the rows keep their order while live counts move.
    final spoken = [
      option.title,
      votesText,
      if (isLeader) leaderLabel,
      if (mine) 'your vote',
    ].join(', ');

    // Above 1.6× text the decorative poster steps aside so long words fit.
    final showPoster = MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.6;
    final details = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showPoster) ...[
        ClPosterImage(url: option.posterUrl, width: 56, height: 84, radius: AppRadius.sm, decorative: true),
        const SizedBox(width: AppSpacing.md),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FitWordsText(option.title, styles: const [AppTextStyles.title, AppTextStyles.label, AppTextStyles.bodySm]),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(votesText, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              if (isLeader)
                ClBadge(leaderLabel, tone: gold ? ClBadgeTone.gold : ClBadgeTone.purpleSolid, icon: AppIcons.crown, uppercase: false),
              if (mine) const ClBadge('Your vote', tone: ClBadgeTone.success, icon: AppIcons.check, uppercase: false),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              backgroundColor: AppColors.surfaceRaised,
              color: mine || isLeader ? AppColors.purple : AppColors.textMuted,
            ),
          ),
        ]),
      ),
    ]);

    return ClCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: mine ? AppColors.purple : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        option.tmdbId == null
            ? Semantics(label: spoken, excludeSemantics: true, child: details)
            : ClPressable(
                onTap: () => context.push('/movie/${option.tmdbId}'),
                semanticLabel: '$spoken. Open film details',
                excludeChildSemantics: true,
                borderRadius: AppRadius.mdAll,
                child: details,
              ),
        if (showVote) ...[
          const SizedBox(height: AppSpacing.md),
          ClButton(
            label: 'Vote',
            semanticLabel: 'Vote for ${option.title}',
            icon: AppIcons.poll,
            variant: ClButtonVariant.secondary,
            onPressed: canVote ? onVote : null,
          ),
        ],
      ]),
    );
  }
}

class _JoinToVote extends StatelessWidget {
  const _JoinToVote({required this.clubName, required this.joining, required this.onJoin});
  final String? clubName;
  final bool joining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final club = clubName ?? 'this club';
    return ClCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Join $club to vote', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Members vote on which suggested film the club watches.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClButton(
          label: 'Join club',
          semanticLabel: 'Join $club',
          icon: AppIcons.add,
          variant: ClButtonVariant.purple,
          isLoading: joining,
          onPressed: joining ? null : onJoin,
        ),
      ]),
    );
  }
}
