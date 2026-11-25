import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home feed: this week's pick → active poll → live now → upcoming watch
/// parties → recent discussions.
///
/// Gold budget (tokens.md): the hero's "Watch party" CTA is the only gold
/// content owner. Poll leader, badges and "Join live" are purple; card CTAs
/// are white (`inverse`).
///
/// Content is still demo data (no feed API yet); every control navigates to
/// a real route. Empty states render from the data, not from a QA toggle.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Bumped on refresh so sections replay their entrance.
  int _generation = 0;

  Future<void> _refresh() async {
    // TODO(api): replace with the home feed request once it exists.
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final heroHeight = (size.height * 0.58).clamp(420.0, 540.0);
    final reduced = AppMotion.of(context).reduced;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: CustomScrollView(
          key: ValueKey(_generation),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: !reduced,
              expandedHeight: heroHeight,
              backgroundColor: AppColors.bg,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: AppSpacing.gutter,
              title: const ClLogo(size: 28),
              actions: [
                ClIconButton(
                  icon: AppIcons.bell,
                  tooltip: 'Notifications',
                  badge: _demoUnread > 0,
                  badgeLabel: '$_demoUnread unread',
                  onPressed: () => context.push('/notifications'),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: reduced ? CollapseMode.pin : CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: _Hero(pick: _demoPick),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, MediaQuery.paddingOf(context).bottom + AppSpacing.lg),
              sliver: SliverList.list(
                children: [
                  // Active poll
                  ClEntrance(
                    index: 0,
                    child: _Section(
                      title: 'Active poll',
                      subtitle:
                          _demoPolls.isEmpty
                              ? null
                              : '${_demoPolls.first.club} · closes in ${_demoPolls.first.closesIn}',
                      child:
                          _demoPolls.isEmpty
                              ? ClCard(
                                child: ClEmptyState(
                                  compact: true,
                                  illustration: ClIllustration.polls,
                                  message: 'No active polls — suggest a film!',
                                  actionLabel: 'Suggest a film',
                                  onAction: () => context.go('/suggest'),
                                ),
                              )
                              : _PollCard(poll: _demoPolls.first),
                    ),
                  ),
                  // Live now
                  ClEntrance(index: 1, child: _Section(title: 'Live now', child: _LiveCard(party: _demoLive))),
                  // Upcoming watch parties
                  ClEntrance(
                    index: 2,
                    child: _Section(
                      title: 'Watch parties',
                      subtitle: 'RSVP so hosts can plan',
                      actionLabel: _demoParties.isEmpty ? null : 'See all',
                      onAction: () => context.push('/watch-parties'),
                      padChild: false,
                      child:
                          _demoParties.isEmpty
                              ? const Padding(
                                padding: AppSpacing.screen,
                                child: ClCard(
                                  child: ClEmptyState(
                                    compact: true,
                                    illustration: ClIllustration.parties,
                                    message: 'No watch parties planned yet.',
                                  ),
                                ),
                              )
                              : SizedBox(
                                height: 268,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: AppSpacing.screen,
                                  itemCount: _demoParties.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                                  itemBuilder: (context, i) => _PartyCard(party: _demoParties[i]),
                                ),
                              ),
                    ),
                  ),
                  // Recent discussions
                  ClEntrance(
                    index: 3,
                    child: _Section(
                      title: 'Recent discussions',
                      subtitle: 'Join the conversation',
                      child:
                          _demoDiscussions.isEmpty
                              ? ClCard(
                                child: ClEmptyState(
                                  compact: true,
                                  illustration: ClIllustration.discussions,
                                  message: 'Be the first to start a thread about what your club watched.',
                                  actionLabel: 'Start a thread',
                                  onAction: () => context.push('/discussionThread'),
                                ),
                              )
                              : Column(
                                children: [
                                  for (final d in _demoDiscussions) ...[
                                    _DiscussionCard(discussion: d),
                                    if (d != _demoDiscussions.last) const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Layout ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padChild = true,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  /// False for horizontally scrolling children that manage their own gutter.
  final bool padChild;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSectionHeader(
            title: title,
            subtitle: subtitle,
            actionLabel: actionLabel,
            onAction: onAction,
            padding: AppSpacing.screen,
          ),
          const SizedBox(height: AppSpacing.md),
          padChild ? Padding(padding: AppSpacing.screen, child: child) : child,
        ],
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.pick});

  final _Pick pick;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClPosterImage(url: pick.posterUrl, radius: 0, scrim: ClScrim.both, semanticLabel: '${pick.title} poster'),
        Positioned(
          left: AppSpacing.gutter,
          right: AppSpacing.gutter,
          bottom: AppSpacing.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [const ClBadge("This week's pick"), ClBadge(pick.meta, tone: ClBadgeTone.glass)],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(pick.title, style: AppTextStyles.display, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.sm),
              Text(pick.when, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: ClButton(
                      label: 'Watch party',
                      icon: AppIcons.ticket,
                      onPressed: () => context.push('/watch-parties'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ClButton(
                      label: 'Discuss',
                      icon: AppIcons.chat,
                      variant: ClButtonVariant.secondary,
                      onPressed: () => context.push('/discussionThread'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Poll ─────────────────────────────────────────────────────────────────────

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll});

  final _Poll poll;

  @override
  Widget build(BuildContext context) {
    final ranked = poll.ranked;
    final total = poll.totalVotes;
    return ClCard(
      onTap: () => context.push('/communities/${poll.communityId}/vote'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < ranked.length; i++) ...[
            _PollRow(
              rank: i + 1,
              option: ranked[i],
              share: total == 0 ? 0 : ranked[i].votes / total,
              leading: i == 0 && ranked[i].votes > 0,
            ),
            if (i < ranked.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('$total votes · ${poll.voters} of ${poll.members} members', style: AppTextStyles.caption),
              ),
              ClButton(
                label: 'Cast your vote',
                variant: ClButtonVariant.inverse,
                size: ClButtonSize.sm,
                expand: false,
                onPressed: () => context.push('/communities/${poll.communityId}/vote'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PollRow extends StatelessWidget {
  const _PollRow({required this.rank, required this.option, required this.share, required this.leading});

  final int rank;
  final _PollOption option;
  final double share;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final pct = (share * 100).round();
    return Semantics(
      label: '${option.title}, ${option.votes} votes, $pct percent${leading ? ', leading' : ''}',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Stack(
          children: [
            // Vote-share bar behind the row.
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: share),
                  duration: motion.slow,
                  curve: AppMotion.emphasized,
                  builder:
                      (_, v, __) => FractionallySizedBox(
                        widthFactor: v.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: ColoredBox(color: leading ? AppColors.purpleContainer : AppColors.glassFlat),
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClPosterImage(url: option.posterUrl, width: 36, height: 52, radius: AppRadius.sm),
                      Positioned(
                        top: -5,
                        left: -5,
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: leading ? AppColors.purpleBadge : AppColors.surfaceRaised,
                            border: leading ? null : Border.all(color: AppColors.borderStrong),
                          ),
                          child: Text(
                            '$rank',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: leading ? AppColors.onPurpleBadge : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: AppTextStyles.title.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Wrap: the badge drops below on narrow phones / large text.
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('${option.votes} votes', style: AppTextStyles.caption),
                            if (leading) const ClBadge('Leading', icon: AppIcons.crown),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$pct%',
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 15,
                      color: leading ? AppColors.purpleText : AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live now ─────────────────────────────────────────────────────────────────

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.party});

  final _Party party;

  @override
  Widget build(BuildContext context) {
    return ClCard(
      onTap: () => context.push('/watchParty'),
      child: Row(
        children: [
          ClProgressRing(
            value: party.progress,
            size: 84,
            strokeWidth: 6,
            semanticLabel: '${party.remaining} remaining',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(party.remaining, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                Text('left', style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ClBadge('Live', tone: ClBadgeTone.error),
                const SizedBox(height: AppSpacing.sm),
                Text(party.title, style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${party.club} · ${party.attending} watching',
                  style: AppTextStyles.bodySm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                ClButton(
                  label: 'Join live',
                  icon: AppIcons.play,
                  variant: ClButtonVariant.purple,
                  size: ClButtonSize.sm,
                  expand: false,
                  onPressed: () => context.push('/watchParty'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Watch parties ────────────────────────────────────────────────────────────

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.party});

  final _Party party;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 264,
      child: ClCard(
        padding: EdgeInsets.zero,
        clip: true,
        onTap: () => context.push('/watch-parties'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 128,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClPosterImage(url: party.posterUrl, radius: 0, scrim: ClScrim.bottom),
                  if (party.badge != null)
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: ClBadge(party.badge!, tone: ClBadgeTone.purpleSolid),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: AppSpacing.sm,
                    child: Text(party.title, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  const Icon(AppIcons.calendar, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${party.when} · ${party.club}',
                      style: AppTextStyles.bodySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const ClTicketDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 10, 8),
              child: Row(
                children: [
                  // Avatars show who; a short count avoids truncating names next to RSVP.
                  ClAvatarStack(people: party.people, total: party.attending, showCaption: false),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${party.attending} going',
                      style: AppTextStyles.bodySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ClButton(
                    label: 'RSVP',
                    variant: ClButtonVariant.inverse,
                    size: ClButtonSize.sm,
                    expand: false,
                    onPressed: () => context.push('/watch-parties'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Discussions ──────────────────────────────────────────────────────────────

class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.discussion});

  final _Discussion discussion;

  @override
  Widget build(BuildContext context) {
    final d = discussion;
    return ClCard(
      onTap: () => context.push('/discussionThread'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClPosterImage(url: d.posterUrl, width: 48, height: 70, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(d.title, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (d.pinned) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const ClBadge('Pinned', icon: AppIcons.pin),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(d.prompt, style: AppTextStyles.bodySm, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(AppIcons.chat, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${d.replies} replies', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(AppIcons.clock, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(d.ago, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demo data (replace with providers when the feed API exists) ─────────────

const _tmdb = 'https://image.tmdb.org/t/p/w342';

class _Pick {
  const _Pick({required this.title, required this.meta, required this.when, required this.posterUrl});
  final String title;
  final String meta;
  final String when;
  final String posterUrl;
}

class _PollOption {
  const _PollOption(this.title, this.votes, this.posterUrl, this.order);
  final String title;
  final int votes;
  final String posterUrl;

  /// Suggestion order; ties go to the earliest suggestion.
  final int order;
}

class _Poll {
  const _Poll({
    required this.communityId,
    required this.club,
    required this.closesIn,
    required this.options,
    required this.voters,
    required this.members,
  });
  final String communityId;
  final String club;
  final String closesIn;
  final List<_PollOption> options;
  final int voters;
  final int members;

  int get totalVotes => options.fold(0, (a, o) => a + o.votes);

  /// Most votes first; ties go to the earliest suggestion.
  List<_PollOption> get ranked =>
      [...options]..sort((a, b) => b.votes != a.votes ? b.votes.compareTo(a.votes) : a.order.compareTo(b.order));
}

class _Party {
  const _Party({
    required this.title,
    required this.club,
    required this.when,
    required this.posterUrl,
    required this.attending,
    required this.people,
    this.badge,
    this.progress = 0,
    this.remaining = '',
  });
  final String title;
  final String club;
  final String when;
  final String posterUrl;
  final int attending;
  final List<({String name, String? imageUrl})> people;
  final String? badge;
  final double progress;
  final String remaining;
}

class _Discussion {
  const _Discussion(this.title, this.prompt, this.posterUrl, this.replies, this.ago, {this.pinned = false});
  final String title;
  final String prompt;
  final String posterUrl;
  final int replies;
  final String ago;
  final bool pinned;
}

const _demoUnread = 3;

const _demoPick = _Pick(
  title: 'Past Lives',
  meta: 'Drama · 2023',
  when: 'Cinema Sundays · Watch party Sun 8:00 PM',
  posterUrl: 'https://image.tmdb.org/t/p/w780/kAellTx1ukNtc42BP1kcnHPCG5e.jpg',
);

const _demoPolls = [
  _Poll(
    communityId: 'demo',
    club: 'A24 Lovers',
    closesIn: '2 days',
    voters: 22,
    members: 31,
    // Posters limited to ones whose films are confirmed elsewhere in the app.
    options: [
      _PollOption('Oppenheimer', 8, '$_tmdb/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', 1),
      _PollOption('Everything Everywhere All at Once', 11, '$_tmdb/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 0),
      _PollOption('Mission: Impossible — Fallout', 5, '$_tmdb/74xTEgt7R36Fpooo50r9T25onhq.jpg', 2),
    ],
  ),
];

const _ada = (name: 'Ada Obi', imageUrl: null);
const _tunde = (name: 'Tunde Bello', imageUrl: null);
const _mira = (name: 'Mira Chen', imageUrl: null);
const _sam = (name: 'Sam Reyes', imageUrl: null);

const _demoLive = _Party(
  title: 'Mission: Impossible — Fallout',
  club: 'Action Heads',
  when: 'Now',
  posterUrl: '$_tmdb/74xTEgt7R36Fpooo50r9T25onhq.jpg',
  attending: 12,
  people: [_sam, _ada],
  progress: 0.72,
  remaining: '41m',
);

const _demoParties = [
  _Party(
    title: 'Oppenheimer',
    club: 'Nolan Nerds',
    when: 'Tonight 8:00 PM',
    posterUrl: '$_tmdb/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    attending: 9,
    people: [_ada, _tunde, _mira],
    badge: 'Tonight',
  ),
  _Party(
    title: 'Past Lives',
    club: 'Cinema Sundays',
    when: 'Sun 8:00 PM',
    posterUrl: '$_tmdb/kAellTx1ukNtc42BP1kcnHPCG5e.jpg',
    attending: 14,
    people: [_mira, _sam, _tunde],
  ),
  _Party(
    title: 'Everything Everywhere All at Once',
    club: 'A24 Lovers',
    when: 'Fri 7:30 PM',
    posterUrl: '$_tmdb/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg',
    attending: 6,
    people: [_tunde, _ada],
  ),
];

const _demoDiscussions = [
  _Discussion(
    'Oppenheimer',
    "Christopher Nolan's magnum opus. Did the three timelines work for you?",
    '$_tmdb/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    12,
    '2h',
    pinned: true,
  ),
  _Discussion(
    'Mission: Impossible — Fallout',
    'Most thrilling practical stunt ever filmed? Make your case.',
    '$_tmdb/74xTEgt7R36Fpooo50r9T25onhq.jpg',
    5,
    '5h',
  ),
];
