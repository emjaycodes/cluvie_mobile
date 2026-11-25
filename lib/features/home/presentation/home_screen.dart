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
    final unread = ref.watch(unreadCountProvider);

    final Widget body;
    if (feed != null) {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, ClBottomNavBar.contentPadding(context)),
        sliver: SliverList.list(children: _sections(context, feed)),
      );
    } else if (async.hasError && !async.isLoading) {
      // While a retry is in flight Riverpod still carries the old error, so
      // check isLoading first: the skeleton is the retry's feedback.
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
              expandedHeight: pick == null ? null : _heroHeight(context, pick),
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

  /// The hero's text block is bottom-anchored on a content-tied panel (see
  /// _Hero). By default the hero is about 58% of the screen, growing with
  /// text scale, so the next section peeks above the fold. Legibility wins
  /// over the peek: the hero is never shorter than the toolbar plus the
  /// whole text block, so no line can slide under the logo or off screen.
  static double _heroHeight(BuildContext context, FeaturedPick pick) {
    final size = MediaQuery.sizeOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final stacked = _HeroActions.stacks(context, size.width - AppSpacing.gutter * 2);
    final peek = math.min(
      (size.height * 0.58).clamp(420.0, 540.0) + (scale - 1) * 300 + (stacked ? 56 : 0),
      size.height - MediaQuery.paddingOf(context).top - 96,
    );
    // expandedHeight excludes the status bar, which the toolbar sits below.
    final fits = kToolbarHeight + AppSpacing.lg + _Hero.fade + _Hero.blockHeight(context, pick);
    return math.max(peek, fits);
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
          subtitle: poll == null ? null : '${poll.club} · closes in ${poll.closesInLabel}',
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
  static const double fade = 48;

  static const _pickBadge = "This week's pick";

  /// Height of the text panel (badges, title, when, buttons, padding) at the
  /// current text scale. Mirrors the layout in [build]; a small margin covers
  /// rounding. The hero test checks the rendered block against the toolbar.
  static double blockHeight(BuildContext context, FeaturedPick pick) {
    final width = MediaQuery.sizeOf(context).width - AppSpacing.gutter * 2;
    final scaler = MediaQuery.textScalerOf(context);
    double measure(String text, TextStyle style, {int? maxLines, bool wide = false}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textScaler: scaler,
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
      )..layout(maxWidth: wide ? double.infinity : width);
      final v = wide ? painter.width : painter.height;
      painter.dispose();
      return v;
    }

    // Badges: overline text + 4dp vertical / 9dp horizontal padding + border.
    final badge = AppTextStyles.overline;
    final badgeH = measure('A', badge) + 8 + 2;
    final badgesW = [_pickBadge, pick.meta].map((t) => measure(t.toUpperCase(), badge, wide: true) + 20).toList();
    final badgeRows = badgesW[0] + AppSpacing.sm + badgesW[1] > width ? 2 : 1;
    final badges = badgeH * badgeRows + (badgeRows - 1) * AppSpacing.sm;
    final title = measure(pick.title, AppTextStyles.display, maxLines: 2);
    final when = measure(pick.when, AppTextStyles.body);
    final actions = _HeroActions.stacks(context, width) ? 48 * 2 + AppSpacing.sm : 48.0;
    return badges +
        AppSpacing.md +
        title +
        AppSpacing.sm +
        when +
        AppSpacing.lg +
        actions +
        AppSpacing.xl +
        AppSpacing.sm; // margin
  }

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
                  height: fade,
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
                        children: [const ClBadge(_pickBadge), ClBadge(pick.meta, tone: ClBadgeTone.glass)],
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
    return [_ctaLabel, _discussLabel].any((l) => ClButton.intrinsicWidth(context, l, hasIcon: true) > half);
  }

  @override
  Widget build(BuildContext context) {
    final cta = ClButton(
      label: _ctaLabel,
      semanticLabel: 'RSVP to the ${pick.title} watch party',
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

/// Two lines for names (films, clubs) above 1.3× text, so the name isn't the
/// part that gets cut.
int _nameLines(BuildContext context) => MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 2 : 1;

/// At very large text (above 1.6×), rows drop side-by-side extras (thumbnails,
/// right-hand figures) so words get the full width instead of breaking mid-word.
bool _compact(BuildContext context) => MediaQuery.textScalerOf(context).scale(1) > 1.6;

/// Inline meta icons (beside caption / bodySm text). tokens.md: 16.
const double _metaIcon = 16;

// ── Poll ─────────────────────────────────────────────────────────────────────

class _PollCard extends StatelessWidget {
  const _PollCard({required this.poll});

  final Poll poll;

  static const _voteLabel = 'Cast your vote';

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
          LayoutBuilder(
            builder: (context, c) {
              final footer = Text('$total of ${poll.members} members voted', style: AppTextStyles.caption);
              final vote = ClButton(
                label: _voteLabel,
                variant: ClButtonVariant.inverse,
                size: ClButtonSize.sm,
                expand: false,
                // Pass the poll so the vote screen shows these same options.
                onPressed: () => context.push('/communities/${poll.communityId}/vote', extra: poll.voteExtra),
              );
              // Side by side while the button takes at most half the width;
              // otherwise the count goes above a full-width button.
              if (ClButton.intrinsicWidth(context, _voteLabel, size: ClButtonSize.sm) <= c.maxWidth / 2) {
                return Row(children: [Expanded(child: footer), vote]);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [footer, const SizedBox(height: AppSpacing.sm), vote],
              );
            },
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
    // Very large text: no thumbnail or right-hand %, so the title gets the
    // row's full width; rank and share move into the votes line.
    final compact = _compact(context);
    final pctStyle = AppTextStyles.caption.copyWith(
      color: leading ? AppColors.purpleText : AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
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
                  if (!compact) ...[
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
                  ],
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
                              if (compact) TextSpan(text: '#$rank  ·  '),
                              TextSpan(text: '${option.votes} votes'),
                              if (compact) ...[const TextSpan(text: '  ·  '), TextSpan(text: '$pct%', style: pctStyle)],
                              if (leading) ...[
                                const TextSpan(text: '  ·  '),
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(AppIcons.crown, size: _metaIcon, color: AppColors.purpleText),
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
                  if (!compact) const SizedBox(width: AppSpacing.sm),
                  if (!compact)
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
    final ring = ClProgressRing(
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
    );
    final title = Text(party.title, style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis);
    // Club on its own line so it never gets cut for the count.
    final club = Text(party.club, style: AppTextStyles.bodySm, maxLines: _nameLines(context), overflow: TextOverflow.ellipsis);
    final watching = Text('${party.attending} watching', style: AppTextStyles.caption);
    return ClCard(
      child: LayoutBuilder(
        builder: (context, c) {
          // Wide enough: ring left, text and button right. Otherwise (narrow
          // phones, large text) the ring sits beside the badge and count, and
          // the title, club and button take the card's full width.
          final inline =
              ClButton.intrinsicWidth(context, _joinLabel, size: ClButtonSize.sm, hasIcon: true) <=
              c.maxWidth - _ring - AppSpacing.lg;
          if (inline) {
            return Row(
              children: [
                ring,
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ClBadge('Live', tone: ClBadgeTone.error),
                      const SizedBox(height: AppSpacing.sm),
                      title,
                      const SizedBox(height: AppSpacing.xxs),
                      club,
                      watching,
                      const SizedBox(height: AppSpacing.sm),
                      join,
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ring,
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ClBadge('Live', tone: ClBadgeTone.error),
                        const SizedBox(height: AppSpacing.sm),
                        watching,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              title,
              const SizedBox(height: AppSpacing.xxs),
              club,
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: join),
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

  /// Above 1.3× text the title moves off the poster (two lines wouldn't fit
  /// under the badge) into the text area below it.
  static bool _titleBelow(BuildContext context) => MediaQuery.textScalerOf(context).scale(1) > 1.3;

  /// List height: the poster is fixed, the text below grows with text scale.
  static double height(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return _poster + 160 * scale + (_titleBelow(context) ? 48 * scale : 0);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final titleBelow = _titleBelow(context);
    final title = Text(
      party.title,
      // Off the poster at large text, the body title style keeps whole words
      // on a line within the fixed card width.
      style: titleBelow ? AppTextStyles.title : AppTextStyles.h3,
      maxLines: _nameLines(context),
      overflow: TextOverflow.ellipsis,
    );
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
                  if (!titleBelow)
                    Positioned(left: AppSpacing.md, right: AppSpacing.md, bottom: AppSpacing.sm, child: title),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (titleBelow) ...[title, const SizedBox(height: AppSpacing.xs)],
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
                  // At very large text the count would be cut next to RSVP;
                  // the avatars (and their spoken label) carry it then.
                  Expanded(
                    child:
                        scale >= 1.6
                            ? const SizedBox.shrink()
                            : ExcludeSemantics(
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
                    semanticLabel: 'RSVP, ${party.title}',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: _metaIcon, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySm, maxLines: _nameLines(context), overflow: TextOverflow.ellipsis),
        ),
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
    final meta = AppTextStyles.caption.copyWith(color: AppColors.textMuted);
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
                // Full width for the film; the Pinned badge sits on the meta row.
                Text(
                  d.title,
                  style: AppTextStyles.title,
                  maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.15 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(d.prompt, style: AppTextStyles.bodySm, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.chat, size: _metaIcon, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${d.replies} replies', style: meta),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.clock, size: _metaIcon, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Text(d.ago, style: meta),
                      ],
                    ),
                    if (d.pinned) const ClBadge('Pinned', icon: AppIcons.pin),
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
