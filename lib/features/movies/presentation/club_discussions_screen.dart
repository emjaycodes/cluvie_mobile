import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_thread_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A film a club has suggested, with its catalog id (discussions are keyed
/// by it).
typedef ClubFilm = ({String movieId, TmdbMovie film});

/// The films a club has suggested, newest first (`GET /communities/:id/movies`).
final clubFilmsProvider = FutureProvider.autoDispose.family<List<ClubFilm>, String>((ref, communityId) async {
  if (!isMongoId(communityId)) return const [];
  final res = await ref.read(apiClientProvider).get('/communities/$communityId/movies');
  final body = res.data;
  final list = body is List ? body : (body is Map && body['data'] is List ? body['data'] as List : const []);
  return [
    for (final m in list)
      if (m is Map && m['_id'] is String)
        (movieId: m['_id'] as String, film: TmdbMovie.fromJson(Map<String, dynamic>.from(m))),
  ];
});

/// A club's discussions (`/communities/:id/discussion`): one per film the
/// club has suggested. Each opens that film's discussion.
///
/// Gold budget: none.
class ClubDiscussionsScreen extends ConsumerWidget {
  const ClubDiscussionsScreen({super.key, required this.communityId});
  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(clubFilmsProvider(communityId));
    final notMember = ref.watch(clubMembershipProvider(communityId)) == ClubMembership.notMember;
    final bottom = MediaQuery.paddingOf(context).bottom;

    Future<void> reload() async {
      final hadFilms = ref.read(clubFilmsProvider(communityId)).hasValue;
      try {
        ref.invalidate(clubFilmsProvider(communityId));
        await ref.read(clubFilmsProvider(communityId).future);
      } catch (_) {
        // With nothing on screen the error state says it.
        if (hadFilms && context.mounted) {
          ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier discussions.", type: ClSnackbarType.error);
        }
      }
    }

    Widget scroll(List<Widget> children) => RefreshIndicator(
          onRefresh: reload,
          color: AppColors.purple,
          backgroundColor: AppColors.surfaceRaised,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
            children: children,
          ),
        );

    return Scaffold(
      appBar: ClAppBar(title: 'Discussions', frosted: true, fallbackRoute: '/communities/$communityId'),
      // With films on screen, refreshing or a failed refresh keeps them.
      // Without, a retry shows the skeleton so the tap visibly works.
      body: films.when(
        skipLoadingOnRefresh: films.hasValue,
        skipError: true,
        loading: () => Semantics(
          label: 'Loading discussions',
          liveRegion: true,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.gutter),
            children: [
              for (var i = 0; i < 4; i++) ...[const ClSkeletonRow(), const SizedBox(height: AppSpacing.lg)],
            ],
          ),
        ),
        error: (_, __) => scroll([
          const SizedBox(height: AppSpacing.xxl),
          ClErrorState(title: "Couldn't load discussions", onRetry: reload),
        ]),
        data: (list) {
          if (list.isEmpty) {
            return scroll([
              const SizedBox(height: AppSpacing.xxl),
              ClEmptyState(
                illustration: ClIllustration.discussions,
                title: 'No discussions yet',
                message: notMember
                    ? 'Each film the club suggests gets a discussion. Join the club to suggest one.'
                    : 'Each film the club suggests gets a discussion. Suggest one to start.',
                actionLabel: notMember ? 'Open club' : 'Suggest a film',
                onAction: () => context.push(notMember ? '/communities/$communityId' : '/communities/$communityId/suggest'),
              ),
            ]);
          }
          return scroll([
            Text(
              'One discussion for each film the club has suggested.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (i, f) in list.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              ClEntrance(index: i, child: _FilmRow(entry: f)),
            ],
          ]);
        },
      ),
    );
  }
}

class _FilmRow extends StatelessWidget {
  const _FilmRow({required this.entry});
  final ClubFilm entry;

  @override
  Widget build(BuildContext context) {
    final film = entry.film;
    // Above 1.6× text the poster and the "Open" hint step aside so long
    // titles fit without breaking words (the whole row opens it anyway).
    final roomy = MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.6;
    return ClCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ClPressable(
        onTap: () => context.push(
          '/discussionThread',
          extra: DiscussionThreadScreen.extraFor(
            movieId: entry.movieId,
            title: film.title,
            posterUrl: film.posterUrl('w185'),
            tmdbId: film.id,
          ),
        ),
        semanticLabel: '${film.title}${film.year != null ? ', ${film.year}' : ''}. Open discussion',
        excludeChildSemantics: true,
        borderRadius: AppRadius.mdAll,
        child: Row(children: [
          if (roomy) ...[
            ClPosterImage(url: film.posterUrl('w185'), width: 48, height: 72, radius: AppRadius.sm, decorative: true),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FitWordsText(film.title, styles: const [AppTextStyles.title, AppTextStyles.label, AppTextStyles.bodySm]),
              if (film.year != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(film.year!, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              ],
            ]),
          ),
          if (roomy) Text('Open', style: AppTextStyles.label.copyWith(color: AppColors.purpleText)),
        ]),
      ),
    );
  }
}
