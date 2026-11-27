import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/utils/relative_time.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/clubs/presentation/join_feedback.dart';
import 'package:cluvie_mobile/features/clubs/presentation/widgets/club_tile.dart';
import 'package:cluvie_mobile/features/discover/presentation/movie_poster_tile.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart';
import 'package:cluvie_mobile/features/movies/presentation/club_discussions_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The club hub (`/communities/:id`): who the club is, its open vote and the
/// films it has suggested.
///
/// * Club from `GET /communities/:id`, vote from `/polls/active`, films from
///   `/communities/:id/movies`. Each section loads, fails and retries on
///   its own; a failed refresh keeps what's on screen.
/// * Non-members get one "Join club" action; suggest needs membership. While
///   membership is unknown, neither shows.
/// * Members are ids only on the backend, so the screen shows counts, not
///   names.
///
/// Gold budget: "Join club" for non-members, "Suggest a film" for members.
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.communityId});
  final String communityId;

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  bool _joining = false;

  String get _id => widget.communityId;

  Future<void> _refresh() async {
    // A section that fails keeps its earlier data on screen; say so once.
    // A section with nothing to keep shows its own error card instead.
    final had = [
      ref.read(communityProvider(_id)).hasValue,
      ref.read(activePollsProvider(_id)).hasValue,
      ref.read(clubFilmsProvider(_id)).hasValue,
    ];
    ref.invalidate(communityProvider(_id));
    ref.invalidate(activePollsProvider(_id));
    ref.invalidate(clubFilmsProvider(_id));
    Future<bool> ok(Future<Object?> f) => f.then((_) => true, onError: (_) => false);
    final results = await Future.wait([
      ok(ref.read(communityProvider(_id).future)),
      ok(ref.read(activePollsProvider(_id).future)),
      ok(ref.read(clubFilmsProvider(_id).future)),
    ]);
    final stale = [for (var i = 0; i < 3; i++) had[i] && !results[i]].any((x) => x);
    if (stale && mounted) {
      ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier details.", type: ClSnackbarType.error);
    }
  }

  Future<void> _join(Community club) async {
    if (_joining) return;
    setState(() => _joining = true);
    // Stays busy until the club is refetched, so Join can't be sent twice.
    final (done, refusal) = await joinClub(ref, _id);
    if (!mounted) return;
    setState(() => _joining = false);
    showJoinResult(context, club.displayName, done, refusal);
  }

  void _openMenu(Community club, ClubMembership membership) {
    showClSheet<void>(
      context,
      title: club.displayName,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _MenuRow(
          icon: AppIcons.info,
          label: 'About this club',
          onTap: () {
            Navigator.pop(context);
            context.push('/communities/$_id/about');
          },
        ),
        _MenuRow(
          icon: AppIcons.chats,
          label: 'Discussions',
          onTap: () {
            Navigator.pop(context);
            context.push('/communities/$_id/discussion');
          },
        ),
        if (membership != ClubMembership.notMember)
          _MenuRow(
            icon: AppIcons.chat,
            label: 'Club chat',
            onTap: () {
              Navigator.pop(context);
              context.push('/communities/$_id/chat');
            },
          ),
        if (membership == ClubMembership.member)
          _MenuRow(
            icon: AppIcons.ticket,
            label: 'Plan a watch party',
            onTap: () {
              Navigator.pop(context);
              context.push('/communities/$_id/watch-party/new');
            },
          ),
        if (membership == ClubMembership.member)
          _MenuRow(
            icon: AppIcons.settings,
            label: 'Membership',
            onTap: () {
              Navigator.pop(context);
              context.push('/communities/$_id/settings');
            },
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(communityProvider(_id));
    final club = clubAsync.valueOrNull;
    final membership = club == null ? ClubMembership.unknown : membershipIn(ref, club);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: ClAppBar(
        title: club?.displayName ?? 'Club',
        frosted: true,
        fallbackRoute: '/communities',
        actions: [
          if (club != null)
            ClIconButton(icon: AppIcons.more, tooltip: 'Club menu', onPressed: () => _openMenu(club, membership)),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: clubAsync.when(
        skipLoadingOnRefresh: clubAsync.hasValue,
        skipError: clubAsync.hasValue,
        loading: () => Semantics(
          label: 'Loading club',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: const [
              Row(children: [
                ClSkeleton(width: 72, height: 72, circle: true),
                SizedBox(width: AppSpacing.lg),
                Expanded(child: ClSkeleton(height: 28)),
              ]),
              SizedBox(height: AppSpacing.xl),
              ClSkeleton(height: 48),
              SizedBox(height: AppSpacing.xl),
              ClSkeleton(height: 140),
            ],
          ),
        ),
        error: (e, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            if (e is ClubNotFound)
              ClEmptyState(
                illustration: ClIllustration.clubs,
                title: "This club doesn't exist",
                message: 'It may have been removed, or the link is wrong.',
                actionLabel: 'Browse clubs',
                actionVariant: ClButtonVariant.secondary,
                onAction: () => context.go('/communities'),
              )
            else
              ClErrorState(title: "Couldn't load this club", onRetry: () => ref.invalidate(communityProvider(_id))),
          ],
        ),
        data: (club) => RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.purple,
          backgroundColor: AppColors.surfaceRaised,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxl + bottom),
            children: [
              Padding(padding: AppSpacing.screen, child: _Header(club: club, membership: membership, me: ref.watch(currentUserIdProvider).valueOrNull)),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: AppSpacing.screen,
                child: switch (membership) {
                  ClubMembership.notMember => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ClButton(
                        label: 'Join club',
                        icon: AppIcons.add,
                        variant: ClButtonVariant.primary,
                        isLoading: _joining,
                        onPressed: _joining ? null : () => _join(club),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Join to suggest films and vote on what the club watches.',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ClubMembership.member => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ClButton(
                        label: 'Suggest a film',
                        icon: AppIcons.popcorn,
                        variant: ClButtonVariant.primary,
                        onPressed: () => context.push('/communities/$_id/suggest'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClButton(
                        label: 'Club chat',
                        icon: AppIcons.chat,
                        variant: ClButtonVariant.secondary,
                        onPressed: () => context.push('/communities/$_id/chat'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClButton(
                        label: 'Plan a watch party',
                        icon: AppIcons.ticket,
                        variant: ClButtonVariant.secondary,
                        onPressed: () => context.push('/communities/$_id/watch-party/new'),
                      ),
                    ]),
                  ClubMembership.unknown => _MembershipUnknown(communityId: _id),
                },
              ),
              const SizedBox(height: AppSpacing.section),
              _VoteSection(communityId: _id, clubName: club.displayName, membership: membership),
              const SizedBox(height: AppSpacing.section),
              _FilmsSection(communityId: _id, membership: membership),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.club, required this.membership, required this.me});
  final Community club;
  final ClubMembership membership;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final since = club.createdAt;
    final description = club.description;
    // Above 1.3× text the monogram sits above the name, giving it the
    // full width.
    final roomy = MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.3;
    final avatar = ClAvatar(name: club.displayName, radius: 32, ring: true);
    final title = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        header: true,
        child: FitWordsText(club.displayName, styles: const [AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        [clubStats(club), if (since != null) 'Since ${DateFormat.yMMM().format(since)}'].join(' · '),
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (roomy)
        Row(children: [avatar, const SizedBox(width: AppSpacing.lg), Expanded(child: title)])
      else ...[
        avatar,
        const SizedBox(height: AppSpacing.md),
        title,
      ],
      if (membership == ClubMembership.member) ...[
        const SizedBox(height: AppSpacing.md),
        if (club.isOwner(me))
          const ClBadge('You run this club', tone: ClBadgeTone.purple, icon: AppIcons.crown, uppercase: false)
        else if (club.isAdmin(me))
          const ClBadge('You’re an admin', tone: ClBadgeTone.purple, icon: AppIcons.crown, uppercase: false)
        else
          const ClBadge('You’re a member', tone: ClBadgeTone.success, icon: AppIcons.check, uppercase: false),
      ],
      if (description != null) ...[
        const SizedBox(height: AppSpacing.md),
        Text(description, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), maxLines: 4, overflow: TextOverflow.ellipsis),
      ],
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ClSectionHeader(
        title: title,
        actionLabel: actionLabel,
        onAction: onAction,
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
      );
}

/// The club's open vote, soonest to close first.
class _VoteSection extends ConsumerWidget {
  const _VoteSection({required this.communityId, required this.clubName, required this.membership});
  final String communityId;
  final String clubName;
  final ClubMembership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final polls = ref.watch(activePollsProvider(communityId));
    void openVote() => context.push('/communities/$communityId/vote', extra: {'club': clubName});

    final body = polls.when(
      skipLoadingOnRefresh: polls.hasValue,
      skipError: polls.hasValue,
      loading: () => const ClSkeleton(height: 120),
      error: (_, __) => ClErrorState(
        title: "Couldn't load the vote",
        compact: true,
        onRetry: () => ref.invalidate(activePollsProvider(communityId)),
      ),
      data: (list) {
        final now = DateTime.now();
        final open = list.where((p) => p.isOpenAt(now)).toList();
        if (open.isEmpty) {
          return ClCard(
            child: Row(children: [
              const Icon(AppIcons.poll, color: AppColors.textSecondary, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('No vote open', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'When the club opens a vote on its suggestions, it shows here.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ]),
              ),
            ]),
          );
        }
        final poll = open.first;
        final leader = poll.leader;
        final left = timeLeft(poll.expiresAt, now: now);
        final total = poll.totalVotes;
        return ClCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              if (left != null) ClBadge('Closes in $left', tone: ClBadgeTone.purple, icon: AppIcons.clock, uppercase: false),
              if (open.length > 1) ClBadge('${open.length} votes open', tone: ClBadgeTone.glass, uppercase: false),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text(poll.question, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              leader == null
                  ? '${poll.options.length} film${poll.options.length == 1 ? '' : 's'} · no votes yet'
                  : '${leader.title} leads · $total vote${total == 1 ? '' : 's'}',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            ClButton(
              label: membership == ClubMembership.member ? 'Vote' : 'See the vote',
              icon: AppIcons.poll,
              variant: ClButtonVariant.inverse,
              onPressed: openVote,
            ),
          ]),
        );
      },
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _SectionTitle('Vote'),
      Padding(padding: AppSpacing.screen, child: body),
    ]);
  }
}

/// Films the club has suggested; each opens its discussion.
class _FilmsSection extends ConsumerWidget {
  const _FilmsSection({required this.communityId, required this.membership});
  final String communityId;
  final ClubMembership membership;

  static const _width = 112.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(clubFilmsProvider(communityId));
    final hasFilms = films.valueOrNull?.isNotEmpty ?? false;

    final Widget body = films.when(
      skipLoadingOnRefresh: films.hasValue,
      skipError: films.hasValue,
      loading: () => SizedBox(
        height: _width * 3 / 2,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppSpacing.screen,
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              const ClSkeleton(width: _width, height: _width * 3 / 2),
            ],
          ],
        ),
      ),
      error: (_, __) => Padding(
        padding: AppSpacing.screen,
        child: ClErrorState(
          title: "Couldn't load the club's films",
          compact: true,
          onRetry: () => ref.invalidate(clubFilmsProvider(communityId)),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: AppSpacing.screen,
            child: ClCard(
              child: ClEmptyState(
                compact: true,
                illustration: ClIllustration.discussions,
                title: 'No films yet',
                message: membership == ClubMembership.member
                    ? 'Suggest the first one. Each film gets its own discussion.'
                    : 'Films the club suggests show here, each with its own discussion.',
              ),
            ),
          );
        }
        return SizedBox(
          height: _width * 3 / 2 + MoviePosterTile.textHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.screen,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final entry = list[i];
              return MoviePosterTile(
                movie: entry.film,
                width: _width,
                onTap: () => context.push(
                  '/discussionThread',
                  extra: DiscussionThreadScreen.extraFor(
                    movieId: entry.movieId,
                    title: entry.film.title,
                    posterUrl: entry.film.posterUrl('w185'),
                    tmdbId: entry.film.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SectionTitle(
        'Club films',
        actionLabel: hasFilms ? 'Discussions' : null,
        onAction: hasFilms ? () => context.push('/communities/$communityId/discussion') : null,
      ),
      body,
    ]);
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ClPressable(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        semanticLabel: label,
        excludeChildSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch + 8),
          child: Row(children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            const Icon(AppIcons.forward, color: AppColors.textMuted, size: 18),
          ]),
        ),
      );
}

/// Shown where Join or Suggest would be while membership is unknown: nothing
/// while it loads, a retry when it couldn't be checked.
class _MembershipUnknown extends ConsumerWidget {
  const _MembershipUnknown({required this.communityId});
  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref.watch(joinedCommunitiesProvider).hasError || ref.watch(currentUserIdProvider).hasError;
    if (!failed) return const SizedBox.shrink();
    return ClErrorState(
      compact: true,
      title: "Couldn't check your membership",
      onRetry: () {
        ref.invalidate(joinedCommunitiesProvider);
        ref.invalidate(currentUserIdProvider);
        ref.invalidate(communityProvider(communityId));
      },
    );
  }
}
