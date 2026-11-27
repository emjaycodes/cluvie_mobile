import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:flutter/material.dart';

/// Poster (2:3) with title and year below. Used by Discover's rows and grids
/// and by Suggest's picker.
///
/// [onTap] null makes the tile inert (e.g. a film with no id). [selected]
/// draws a purple ring and check (Suggest); purple, not gold, per the gold
/// budget.
class MoviePosterTile extends StatelessWidget {
  const MoviePosterTile({super.key, required this.movie, this.onTap, this.selected, this.width});

  final TmdbMovie movie;
  final VoidCallback? onTap;

  /// Null: not selectable. True/false: shows and announces the state.
  final bool? selected;

  /// Fixed width (horizontal rows); null fills the grid cell.
  final double? width;

  /// Height of the text under the poster at the current text scale, so grids
  /// can size their cells: title (2 lines) + gap + year.
  static double textHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return scaler.scale(AppTextStyles.label.fontSize! * AppTextStyles.label.height!) * 2 +
        AppSpacing.xs +
        scaler.scale(AppTextStyles.caption.fontSize! * AppTextStyles.caption.height!) +
        AppSpacing.xs;
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = selected ?? false;
    final year = movie.year;
    final poster = AspectRatio(
      aspectRatio: 2 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClPosterImage(url: movie.posterUrl(), radius: AppRadius.md, decorative: true),
          if (isSelected) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.purpleText, width: 3),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: AppColors.purpleBadge, shape: BoxShape.circle),
                child: const Icon(AppIcons.check, size: 16, color: AppColors.onPurpleBadge),
              ),
            ),
          ],
        ],
      ),
    );
    final tile = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        poster,
        const SizedBox(height: AppSpacing.xs),
        Text(movie.title, style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (year != null) Text(year, style: AppTextStyles.caption),
      ],
    );
    return SizedBox(
      width: width,
      child: ClPressable(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        selected: selected,
        isButton: onTap != null,
        semanticLabel: [movie.title, if (year != null) year].join(', '),
        excludeChildSemantics: true,
        child: tile,
      ),
    );
  }
}

/// Grid of [MoviePosterTile]s as a sliver, sized so the text under each
/// poster always fits at the current text scale.
class MoviePosterGrid extends StatelessWidget {
  const MoviePosterGrid({super.key, required this.movies, required this.onTap, this.isSelected});

  final List<TmdbMovie> movies;

  /// Called for films with an id; films without one are inert.
  final void Function(TmdbMovie movie) onTap;
  final bool Function(TmdbMovie movie)? isSelected;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, c) {
        final width = c.crossAxisExtent - AppSpacing.gutter * 2;
        // Three columns on wider phones, two on small ones or at large text.
        final columns = width >= 340 && MediaQuery.textScalerOf(context).scale(1) <= 1.3 ? 3 : 2;
        final tileW = (width - AppSpacing.md * (columns - 1)) / columns;
        final tileH = tileW * 3 / 2 + MoviePosterTile.textHeight(context);
        return SliverPadding(
          padding: AppSpacing.screen,
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.lg,
              mainAxisExtent: tileH,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final m = movies[i];
              return MoviePosterTile(
                movie: m,
                selected: isSelected?.call(m),
                onTap: m.id == null ? null : () => onTap(m),
              );
            }, childCount: movies.length),
          ),
        );
      },
    );
  }
}

/// Skeleton for a poster grid while loading.
class MoviePosterGridSkeleton extends StatelessWidget {
  const MoviePosterGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading films',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: AppSpacing.screen,
          child: LayoutBuilder(
            builder: (context, c) {
              final tileW = (c.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.lg,
                children: [
                  for (var i = 0; i < count; i++) ClSkeleton(width: tileW, height: tileW * 3 / 2, radius: AppRadius.md),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
