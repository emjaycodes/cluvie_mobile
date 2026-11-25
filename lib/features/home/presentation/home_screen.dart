import 'dart:math' as math;

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home feed: this week's pick → active poll → live now → upcoming watch
/// parties → recent discussions.
///
/// Gold budget (tokens.md): the hero's RSVP CTA is the only gold content
/// owner. Poll leader, badges and the live ring are purple; card CTAs
/// ("Join live", RSVP) are white (`inverse`). Pull-to-refresh is purple.
///
/// Data comes from [homeFeedProvider] (demo data until the feed API exists).
/// Loading shows skeletons, a failed load shows a retry, and each section has
/// its own empty state. Every control opens the thing it names.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      ref.invalidate(homeFeedProvider);
      await ref.read(homeFeedProvider.future);
    } catch (_) {
      // The feed already on screen stays; say the refresh failed.
      if (context.mounted) {
        ClSnackbar.show(context, message: "Couldn't refresh. Check your connection.", type: ClSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeFeedProvider);
    final feed = async.valueOrNull;
    final pick = feed?.pick;
    final reduced = AppMotion.of(context).reduced;
    final unread = feed?.unread ?? 0;

    final Widget body;
    if (feed != null) {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, ClBottomNavBar.contentPadding(context)),
        sliver: SliverList.list(children: _sections(context, feed)),
      );
    } else if (async.hasError) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: ClBottomNavBar.contentPadding(context)),
          child: ClErrorState(
            title: "Couldn't load your feed",
            onRetry: () => ref.invalidate(homeFeedProvider),
          ),
        ),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsets.only(bottom: ClBottomNavBar.contentPadding(context)),
        sliver: const SliverToBoxAdapter(child: _HomeSkeleton()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        color: AppColors.purple,
        backgroundColor: AppColors.surfaceRaised,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: !reduced && pick != null,
              expandedHeight: pick == null ? null : _heroHeight(context),
              backgroundColor: AppColors.bg,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: AppSpacing.gutter,
              title: const ClLogo(size: 28),
              actions: [
                ClIconButton(
                  icon: AppIcons.bell,
                  tooltip: 'Notifications',
                  badge: unread > 0,
                  badgeLabel: '$unread unread',
                  onPressed: () => context.push('/notifications'),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              flexibleSpace:
                  pick == null
                      ? null
                      : FlexibleSpaceBar(
                        collapseMode: reduced ? CollapseMode.pin : CollapseMode.parallax,
                        stretchModes: const [StretchMode.zoomBackground],
                        background: _Hero(pick: pick),
                      ),
            ),
            body,
          ],
        ),
      ),
    );
  }

  /// The text block's cover is tied to its content (see _Hero), so a taller
  /// block would eat the poster. Grow the hero with text scale, and by one
  /// button row when the CTAs stack, but keep the next section peeking above
  /// the fold.
  static double _heroHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final stacked = _HeroActions.stacks(context, size.width - AppSpacing.gutter * 2);
    return math.min(
      (size.height * 0.58).clamp(420.0, 540.0) + (scale - 1) * 300 + (stacked ? 56 : 0),
      size.height - MediaQuery.paddingOf(context).top - 96,
    );
  }

  List<Widget> _sections(BuildContext context, HomeFeed feed) {
    final poll = feed.poll;
    final live = feed.live;
    final pick = feed.pick;
    var i = 0;
    return [
      ClEntrance(
        index: i++,
        child: _Section(
          title: 'Active poll',
          subtitle: poll == null ? null : '${poll.club} · closes in ${poll.closesIn}',
          child:
              poll == null
                  ? ClCard(
                    child: ClEmptyState(
                      compact: true,
                      illustration: ClIllustration.polls,
                      message: 'No active polls — suggest a film!',
                      actionLabel: 'Suggest a film',
                      onAction: () => context.go('/suggest'),
                    ),
                  )
                  : _PollCard(poll: poll),
        ),
      ),
      // Hidden when nothing is live: an empty "Live now" is noise.
      if (live != null) ClEntrance(index: i++, child: _Section(title: 'Live now', child: _LiveCard(party: live))),
      ClEntrance(
        index: i++,
        child: _Section(
          title: 'Watch parties',
          subtitle: 'RSVP so hosts can plan',
          actionLabel: feed.parties.isEmpty ? null : 'See all',
          onAction: () => context.push('/watch-parties'),
          padChild: false,
          child:
              feed.parties.isEmpty
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
                    height: _PartyCard.height(context),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.screen,
                      itemCount: feed.parties.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, i) => _PartyCard(party: feed.parties[i]),
                    ),
                  ),
        ),
      ),
      ClEntrance(
        index: i++,
        child: _Section(
          title: 'Recent discussions',
          subtitle: 'Join the conversation',
          child:
              feed.discussions.isEmpty
                  ? ClCard(
                    child: ClEmptyState(
                      compact: true,
                      illustration: ClIllustration.discussions,
                      message: 'Be the first to start a thread about what your club watched.',
                      // Opens the pick's thread, so the label names the film.
                      actionLabel: pick == null ? null : 'Discuss ${pick.title}',
                      onAction:
                          pick == null ? null : () => context.push('/discussionThread', extra: pick.threadExtra),
                    ),
                  )
                  : Column(
                    children: [
                      for (final d in feed.discussions) ...[
                        _DiscussionCard(discussion: d),
                        if (d != feed.discussions.last) const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
        ),
      ),
    ];
  }
}

/// First-load placeholder shaped like the feed: hero, poll card, party cards.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your feed',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const ClSkeleton(height: 320, radius: AppRadius.lg),
              const SizedBox(height: AppSpacing.section),
              const ClSkeleton(height: 20, width: 140),
              const SizedBox(height: AppSpacing.md),
              const ClSkeleton(height: 200, radius: AppRadius.lg),
              const SizedBox(height: AppSpacing.section),
              const ClSkeleton(height: 20, width: 160),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: const [
                  Expanded(child: ClSkeleton(height: 180, radius: AppRadius.lg)),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: ClSkeleton(height: 180, radius: AppRadius.lg)),
                ],
              ),
            ],
          ),
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
          // Separate containers so the heading is never merged into a card's
          // button node (round 4b, B4).
          Semantics(
            container: true,
            child: ClSectionHeader(
              title: title,
              subtitle: subtitle,
              actionLabel: actionLabel,
              onAction: onAction,
              padding: AppSpacing.screen,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(container: true, child: padChild ? Padding(padding: AppSpacing.screen, child: child) : child),
        ],
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.pick});

  final FeaturedPick pick;

  /// Height of the fade between bare poster and the text panel.
  static const double _fade = 48;

  @override
  Widget build(BuildContext context) {
    final topCover = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Decorative: the title below already names the film.
        ClPosterImage(url: pick.posterUrl, radius: 0, scrim: ClScrim.bottom, decorative: true),
        // Top scrim sized to the real inset (tokens.md `scrimTop`): solid at
        // ≥ 0.85 under the status bar and toolbar, then fades out over 24dp,
        // so the logo and bell stay legible on a white poster.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topCover + AppSpacing.lg,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bg.withValues(alpha: AppColors.scrimSolid),
                    AppColors.bg.withValues(alpha: AppColors.scrimSolid),
                    AppColors.bg.withValues(alpha: 0),
                  ],
                  stops: [0, topCover / (topCover + AppSpacing.lg), 1],
                ),
              ),
            ),
          ),
        ),
        // Text block. Its cover is tied to the content, not the screen: a
        // `bg` panel at ≥ 0.85 behind every line, with a fade above it, so
        // larger text sizes can never push a line onto bare poster.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: Container(
                  height: _fade,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.bg.withValues(alpha: 0), AppColors.bg.withValues(alpha: AppColors.scrimSolid)],
                    ),
                  ),
                ),
              ),
              ColoredBox(
                color: AppColors.bg.withValues(alpha: AppColors.scrimSolid),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl),
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
                      Semantics(
                        header: true,
                        child: Text(pick.title, style: AppTextStyles.display, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(pick.when, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.lg),
                      _HeroActions(pick: pick),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "RSVP" (the screen's one gold CTA; opens the pick's watch party) and
/// "Discuss" (opens the pick's thread). Side by side when the CTA label fits at
/// half width; stacked, CTA first, when it doesn't (narrow phones, larger text).
class _HeroActions extends StatelessWidget {
  const _HeroActions({required this.pick});

  final FeaturedPick pick;

  static const _ctaLabel = 'RSVP';

  static const _discussLabel = 'Discuss';

  /// Whether either label would truncate at half of [width].
  static bool stacks(BuildContext context, double width) {
    final half = (width - AppSpacing.md) / 2;
    return [_ctaLabel, _discussLabel].any((l) => _buttonWidth(context, l) > half);
  }

  @override
  Widget build(BuildContext context) {
    final cta = ClButton(
      label: _ctaLabel,
      icon: AppIcons.ticket,
      variant: ClButtonVariant.primary,
      onPressed: () => context.push('/watch-parties', extra: pick.party.focusExtra),
    );
    final discuss = ClButton(
      label: _discussLabel,
      icon: AppIcons.chat,
      variant: ClButtonVariant.secondary,
      onPressed: () => context.push('/discussionThread', extra: pick.threadExtra),
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (!stacks(context, c.maxWidth)) {
          return Row(children: [Expanded(child: cta), const SizedBox(width: AppSpacing.md), Expanded(child: discuss)]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [cta, const SizedBox(height: AppSpacing.sm), discuss],
        );
      },
    );
  }
}

/// Width a [ClButton] with an icon needs to show [label] without truncating,
/// at the current text scale. Mirrors ClButton's padding, icon and gap.
double _buttonWidth(BuildContext context, String label, {bool small = false}) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: AppTextStyles.button.copyWith(fontSize: small ? 14 : 15)),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = painter.width + (small ? AppSpacing.lg : AppSpacing.xl) * 2 + (small ? 18 : 20) + AppSpacing.sm;
  painter.dispose();
  return width + 1; // rounding headroom
}

// ── Poll ─────────────────────────────────────────────────────────────────────

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll});

  final Poll poll;

  @override
  Widget build(BuildContext context) {
    final ranked = poll.ranked;
    final total = poll.totalVotes;
    return ClCard(
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
              Expanded(child: Text('$total of ${poll.members} members voted', style: AppTextStyles.caption)),
              ClButton(
                label: 'Cast your vote',
                variant: ClButtonVariant.inverse,
                size: ClButtonSize.sm,
                expand: false,
                // Pass the poll so the vote screen shows these same options.
                onPressed: () => context.push('/communities/${poll.communityId}/vote', extra: poll.voteExtra),
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
  final PollOption option;
  final double share;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final pct = (share * 100).round();
    // Long titles get a second line at larger text instead of losing the film.
    final titleLines = MediaQuery.textScalerOf(context).scale(1) > 1.15 ? 2 : 1;
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
                      ClPosterImage(
                        url: option.posterUrl,
                        width: 36,
                        height: 52,
                        radius: AppRadius.sm,
                        decorative: true,
                      ),
                      Positioned(
                        top: -AppSpacing.xs,
                        left: -AppSpacing.xs,
                        // Grows with the digit at large text instead of clipping it.
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: leading ? AppColors.purpleBadge : AppColors.surfaceRaised,
                            border: leading ? null : Border.all(color: AppColors.borderStrong),
                          ),
                          child: Text(
                            '$rank',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
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
                          style: AppTextStyles.label,
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        // Inline text so it can wrap at large text sizes; a badge can't
                        // shrink below its own width (round 4b, B6).
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${option.votes} votes'),
                              if (leading) ...[
                                const TextSpan(text: '  ·  '),
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(AppIcons.crown, size: 12, color: AppColors.purpleText),
                                ),
                                TextSpan(
                                  text: ' Leading',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.purpleText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$pct%',
                    style: AppTextStyles.title.copyWith(
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

  final Party party;

  static const double _ring = 84;
  static const _joinLabel = 'Join live';

  @override
  Widget build(BuildContext context) {
    final join = ClButton(
      label: _joinLabel,
      icon: AppIcons.play,
      variant: ClButtonVariant.inverse,
      size: ClButtonSize.sm,
      expand: false,
      onPressed: () => context.push('/watchParty', extra: party.roomExtra),
    );
    return ClCard(
      child: LayoutBuilder(
        builder: (context, c) {
          // The button sits under the text; when that column is too narrow for
          // its label (narrow phones, large text) it moves below the ring.
          final inline = _buttonWidth(context, _joinLabel, small: true) <= c.maxWidth - _ring - AppSpacing.lg;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClBadge('Live', tone: ClBadgeTone.error),
              const SizedBox(height: AppSpacing.sm),
              Text(party.title, style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.xxs),
              // Club on its own line so it never gets cut for the count.
              Text(party.club, style: AppTextStyles.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${party.attending} watching', style: AppTextStyles.caption),
              if (inline) ...[const SizedBox(height: AppSpacing.sm), join],
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClProgressRing(
                    value: party.progress,
                    size: _ring,
                    strokeWidth: 6,
                    // The fill is time watched; the countdown says it all.
                    semanticLabel: '${party.minutesLeft} minutes left',
                    semanticValue: '',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${party.minutesLeft}m', style: AppTextStyles.title),
                        Text('left', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: info),
                ],
              ),
              if (!inline) ...[const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: join)],
            ],
          );
        },
      ),
    );
  }
}

// ── Watch parties ────────────────────────────────────────────────────────────

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.party});

  final Party party;

  static const double _poster = 128;

  /// List height: the poster is fixed, the text below grows with text scale.
  static double height(BuildContext context) => _poster + 160 * MediaQuery.textScalerOf(context).scale(1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 264,
      child: ClCard(
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _poster,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClPosterImage(url: party.posterUrl, radius: 0, scrim: ClScrim.bottom, decorative: true),
                  if (party.badge != null)
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: ClBadge(party.badge!, tone: ClBadgeTone.purpleSolid),
                    ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.sm,
                    child: Text(party.title, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // When and where on separate lines, so neither is cut.
                  _MetaLine(icon: AppIcons.calendar, text: party.when),
                  const SizedBox(height: AppSpacing.xxs),
                  _MetaLine(icon: AppIcons.clubs, text: party.club),
                ],
              ),
            ),
            const Spacer(),
            const ClTicketDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xxs, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  // The stack's semantics already say who and how many.
                  ClAvatarStack(people: party.people, total: party.attending, showCaption: false),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        '${party.attending} going',
                        style: AppTextStyles.bodySm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ClButton(
                    label: 'RSVP',
                    variant: ClButtonVariant.inverse,
                    size: ClButtonSize.sm,
                    expand: false,
                    // Opens the list with this party first and outlined.
                    onPressed: () => context.push('/watch-parties', extra: party.focusExtra),
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodySm, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

// ── Discussions ──────────────────────────────────────────────────────────────

class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.discussion});

  final Discussion discussion;

  @override
  Widget build(BuildContext context) {
    final d = discussion;
    const meta = TextStyle(color: AppColors.textMuted);
    return ClCard(
      onTap: () => context.push('/discussionThread', extra: d.threadExtra),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClPosterImage(url: d.posterUrl, width: 48, height: 70, radius: AppRadius.sm, decorative: true),
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
                    const SizedBox(width: AppSpacing.xs),
                    Text('${d.replies} replies', style: AppTextStyles.caption.merge(meta)),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(AppIcons.clock, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(d.ago, style: AppTextStyles.caption.merge(meta)),
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
