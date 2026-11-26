import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/utils/relative_time.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/movies/data/discussions.dart';
import 'package:cluvie_mobile/features/movies/data/film.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_thread_screen.dart';
import 'package:cluvie_mobile/features/suggest/presentation/suggest_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Movie Detail (`/movie/:id`, where id is the TMDB id).
///
/// * Everything shown comes from `GET /tmdb/:id`. Fields TMDB doesn't have
///   are left out, never invented.
/// * Primary action: "Suggest to a club", which opens the shared suggest
///   sheet (club picker and note).
/// * The discussion preview appears once the film is in Cluvie's catalog
///   (a club has suggested it); discussions are keyed by the catalog id.
/// * The watchlist toggle waits on the API ([kWatchlistAvailable]).
///
/// Gold budget: the "Suggest to a club" button.
class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key, this.movieId});

  /// TMDB id from the route. Null or non-numeric shows "not found".
  final String? movieId;

  int? get _tmdbId => int.tryParse(movieId ?? '');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = _tmdbId;
    if (id == null) return const _NotFound();
    final film = ref.watch(filmDetailProvider(id));
    return film.when(
      skipLoadingOnRefresh: false,
      data: (f) => _Loaded(film: f),
      loading: () => const _Loading(),
      error: (e, _) => e is FilmNotFound
          ? const _NotFound()
          : _Failed(onRetry: () => ref.invalidate(filmDetailProvider(id))),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.film});
  final FilmDetail film;

  /// The sheet refreshes the catalog itself, so the discussion preview
  /// below picks the film up; this confirms it.
  Future<void> _suggest(BuildContext context) async {
    final club = await showSuggestSheet(context, film.toTmdbMovie());
    if (club == null || !context.mounted) return;
    ClSnackbar.show(
      context,
      message: 'Suggested ${film.title} to ${club.name ?? 'your club'}.',
      type: ClSnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = (width * 1.1).clamp(320.0, 520.0);
    final hero = film.backdropUrl() ?? film.posterUrl();
    final meta = [film.year, film.runtimeLabel].whereType<String>().join(' · ');
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: heroHeight,
            backgroundColor: AppColors.bg,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: const ClBackButton(fallbackRoute: '/discover'),
            // The title shows only once the hero has scrolled away.
            title: _CollapsedTitle(title: film.title, expandedHeight: heroHeight),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: ClPosterImage(
                url: hero,
                radius: 0,
                scrim: ClScrim.both,
                decorative: true,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.xxl + bottom),
            sliver: SliverList.list(children: [
              Semantics(
                header: true,
                child: FitWordsText(film.title, styles: const [AppTextStyles.h1, AppTextStyles.h2, AppTextStyles.h3, AppTextStyles.title]),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(meta, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ],
              if (film.genres.isNotEmpty || film.rating != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (film.rating != null) _RatingPill(rating: film.rating!),
                    for (final g in film.genres) ClBadge(g, tone: ClBadgeTone.glass, uppercase: false),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ClButton(
                label: 'Suggest to a club',
                icon: AppIcons.popcorn,
                variant: ClButtonVariant.primary,
                size: ClButtonSize.lg,
                onPressed: () => _suggest(context),
              ),
              if (kWatchlistAvailable) ...[
                const SizedBox(height: AppSpacing.md),
                ClButton(
                  label: 'Add to watchlist',
                  icon: AppIcons.bookmark,
                  variant: ClButtonVariant.secondary,
                  onPressed: () {},
                ),
              ],
              if (film.tagline != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  film.tagline!,
                  style: AppTextStyles.title.copyWith(color: AppColors.purpleText, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Semantics(header: true, child: Text('Story', style: AppTextStyles.h3)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                film.overview ?? 'TMDB has no synopsis for this film yet.',
                style: AppTextStyles.body.copyWith(
                  color: film.overview == null ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              _DiscussionPreview(film: film),
              const SizedBox(height: AppSpacing.section),
              Text(
                'Film data from TMDB.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// The app-bar title, faded in once the hero is mostly scrolled away.
class _CollapsedTitle extends StatelessWidget {
  const _CollapsedTitle({required this.title, required this.expandedHeight});
  final String title;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    var t = 0.0;
    if (settings != null) {
      final range = settings.maxExtent - settings.minExtent;
      t = range <= 0 ? 1 : (1 - (settings.currentExtent - settings.minExtent) / range).clamp(0.0, 1.0);
    }
    final visible = t > 0.85;
    return ExcludeSemantics(
      excluding: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppMotion.of(context).quick,
        child: Text(title, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final value = rating.toStringAsFixed(1);
    return Semantics(
      container: true,
      label: 'Rated $value out of 10 on TMDB',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + AppSpacing.xxs),
        decoration: const BoxDecoration(
          color: AppColors.glassFlat,
          borderRadius: AppRadius.pillAll,
          border: Border.fromBorderSide(BorderSide(color: AppColors.borderStrong)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(AppIcons.star, size: 16, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.xs),
          Text('$value TMDB', style: AppTextStyles.label),
        ]),
      ),
    );
  }
}

/// The film's discussion: the latest posts and a way in.
class _DiscussionPreview extends ConsumerWidget {
  const _DiscussionPreview({required this.film});
  final FilmDetail film;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogFilmProvider(film.tmdbId));
    final header = Semantics(header: true, child: Text('Discussion', style: AppTextStyles.h3));

    Widget body(Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, const SizedBox(height: AppSpacing.md), child],
        );

    // Retrying after an error shows the skeleton, so the tap visibly works.
    return catalog.when(
      skipLoadingOnRefresh: false,
      loading: () => body(const ClSkeletonRow(thumbWidth: 40, thumbHeight: 40)),
      error: (_, __) => body(ClErrorState(
        compact: true,
        title: "Couldn't load the discussion",
        onRetry: () => ref.invalidate(catalogProvider),
      )),
      data: (entry) {
        if (entry == null) {
          return body(ClCard(
            child: Text(
              'No club has suggested this film yet. Suggest it to start the discussion.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ));
        }
        final posts = ref.watch(discussionProvider(entry.id));
        void open() => context.push(
              '/discussionThread',
              extra: DiscussionThreadScreen.extraFor(
                movieId: entry.id,
                title: film.title,
                posterUrl: film.posterUrl('w185'),
                tmdbId: film.tmdbId,
              ),
            );
        return body(posts.when(
          skipLoadingOnRefresh: false,
          loading: () => const ClSkeletonRow(thumbWidth: 40, thumbHeight: 40),
          error: (_, __) => ClErrorState(
            compact: true,
            title: "Couldn't load the discussion",
            onRetry: () => ref.invalidate(discussionProvider(entry.id)),
          ),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (list.isEmpty)
                Text('No posts yet. Start the conversation.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))
              else
                for (final p in list.take(2)) ...[
                  _PostSnippet(post: p),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.md),
              ClButton(
                label: list.isEmpty
                    ? 'Start the discussion'
                    : 'Open discussion (${list.length} ${list.length == 1 ? 'post' : 'posts'})',
                icon: AppIcons.chat,
                variant: ClButtonVariant.secondary,
                onPressed: open,
              ),
            ],
          ),
        ));
      },
    );
  }
}

class _PostSnippet extends StatelessWidget {
  const _PostSnippet({required this.post});
  final DiscussionPost post;

  @override
  Widget build(BuildContext context) {
    final name = post.authorName ?? 'Cluvie member';
    return ClCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Above 1.6× text the avatar steps aside so long names fit.
        if (MediaQuery.textScalerOf(context).scale(16) / 16 <= 1.6) ...[
          ClAvatar(name: name, radius: 16),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: name, style: AppTextStyles.label),
                TextSpan(
                  text: '  ${timeAgo(post.createdAt)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(post.text, style: AppTextStyles.bodySm, maxLines: 3, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: const ClAppBar(title: '', transparent: true, fallbackRoute: '/discover'),
      extendBodyBehindAppBar: true,
      body: Semantics(
        label: 'Loading film',
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            ClSkeleton(height: (width * 1.1).clamp(320.0, 520.0), radius: 0),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.gutter),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClSkeleton(width: 240, height: 28),
                SizedBox(height: AppSpacing.md),
                ClSkeleton(width: 140, height: 16),
                SizedBox(height: AppSpacing.xl),
                ClSkeleton(height: 52, radius: AppRadius.pill),
                SizedBox(height: AppSpacing.xl),
                ClSkeleton(height: 14),
                SizedBox(height: AppSpacing.sm),
                ClSkeleton(height: 14),
                SizedBox(height: AppSpacing.sm),
                ClSkeleton(width: 200, height: 14),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClAppBar(title: '', fallbackRoute: '/discover'),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: ClErrorState(title: "Couldn't load this film", onRetry: onRetry),
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ClAppBar(title: '', fallbackRoute: '/discover'),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: ClEmptyState(
            title: "We couldn't find this film",
            message: 'The link may be broken, or the film was removed from TMDB.',
            actionLabel: 'Browse films',
            onAction: () => context.go('/discover'),
          ),
        ),
      ),
    );
  }
}
