import 'dart:async';

import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/discover/presentation/movie_poster_tile.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Discover (tab 1): search films, browse trending and popular, find clubs.
///
/// * Search is debounced ([kSearchDebounce]) and starts at
///   [kMinSearchLength] characters; it shows searching, error-with-retry,
///   "No results for '…' — try another title", and results.
/// * Browse content comes from [discoverFeedProvider]; a failure shows one
///   retry card. There is no demo fallback.
/// * The search survives tab switches ([discoverQueryProvider]).
///
/// Gold budget: none. Discover has no single primary action.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  late final _search = TextEditingController(text: ref.read(discoverQueryProvider));
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(kSearchDebounce, () {
      if (mounted) ref.read(discoverQueryProvider.notifier).state = text.trim();
    });
    // Rebuild for the "keep typing" hint.
    setState(() {});
  }

  void _submitNow(String text) {
    _debounce?.cancel();
    ref.read(discoverQueryProvider.notifier).state = text.trim();
  }

  Future<void> _refresh(String query) async {
    try {
      if (query.length >= kMinSearchLength) {
        ref.invalidate(movieSearchProvider(query));
        await ref.read(movieSearchProvider(query).future);
      } else {
        ref.invalidate(discoverFeedProvider);
        await ref.read(discoverFeedProvider.future);
      }
    } catch (_) {
      // With nothing cached the error state says it; with earlier results on
      // screen, say the refresh failed rather than stopping silently.
      if (mounted && _hasCached(query)) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier results.", type: ClSnackbarType.error);
      }
    }
  }

  bool _hasCached(String query) =>
      query.length >= kMinSearchLength
          ? ref.read(movieSearchProvider(query)).hasValue
          : ref.read(discoverFeedProvider).hasValue;

  void _open(TmdbMovie m) => context.push('/movie/${m.id}');

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(discoverQueryProvider);
    final searching = query.length >= kMinSearchLength;
    final typed = _search.text.trim();
    final tooShort = typed.isNotEmpty && typed.length < kMinSearchLength;
    final unread = ref.watch(unreadCountProvider);
    final searchBusy = searching && ref.watch(movieSearchProvider(query)).isLoading;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(query),
        color: AppColors.purple,
        backgroundColor: AppColors.surfaceRaised,
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.bg,
              scrolledUnderElevation: 0,
              titleSpacing: AppSpacing.gutter,
              title: Semantics(header: true, child: Text('Discover', style: AppTextStyles.h2)),
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
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
              sliver: SliverToBoxAdapter(
                child: ClSearchField(
                  controller: _search,
                  hintText: 'Search films',
                  busy: searchBusy,
                  onChanged: _onChanged,
                  onSubmitted: _submitNow,
                  onCleared: () => _submitNow(''),
                ),
              ),
            ),
            if (tooShort)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'Keep typing: search starts at $kMinSearchLength letters.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            if (searching) ..._results(query) else ..._browse(),
            // Same clearance above the floating nav as Home.
            SliverToBoxAdapter(child: SizedBox(height: ClBottomNavBar.contentPadding(context) + AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(String query) {
    final results = ref.watch(movieSearchProvider(query));
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: AppSpacing.screen,
          child: Semantics(header: true, child: Text("Results for '$query'", style: AppTextStyles.h3)),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      // A retry after an error shows the skeleton (Riverpod keeps the old
      // error while reloading), and a failed refresh keeps earlier results.
      ...(results.isLoading && results.hasError && !results.hasValue
          ? const <Widget>[SliverToBoxAdapter(child: MoviePosterGridSkeleton())]
          : results.when(
            skipLoadingOnReload: true,
            skipError: true,
            loading: () => [const SliverToBoxAdapter(child: MoviePosterGridSkeleton())],
            error:
                (_, __) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: AppSpacing.screen,
                      child: ClCard(
                        child: ClErrorState(
                          compact: true,
                          title: "Search didn't go through",
                          onRetry: () => ref.invalidate(movieSearchProvider(query)),
                        ),
                      ),
                    ),
                  ),
                ],
            data:
                (movies) =>
                    movies.isEmpty
                        ? [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: AppSpacing.screen,
                              child: ClCard(
                                child: ClEmptyState(
                                  compact: true,
                                  illustration: ClIllustration.search,
                                  message: "No results for '$query' — try another title",
                                ),
                              ),
                            ),
                          ),
                        ]
                        : [MoviePosterGrid(movies: movies, onTap: _open)],
          )),
    ];
  }

  List<Widget> _browse() {
    final feed = ref.watch(discoverFeedProvider);
    final data = feed.valueOrNull;
    if (data == null && feed.hasError && !feed.isLoading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screen,
            child: _RetryCard(onRetry: () => ref.invalidate(discoverFeedProvider)),
          ),
        ),
      ];
    }
    if (data == null) {
      return const [SliverToBoxAdapter(child: _BrowseSkeleton())];
    }
    return [
      if (data.trending.isNotEmpty) ...[
        const SliverToBoxAdapter(child: _Header('Trending now', subtitle: 'What everyone is watching this week')),
        SliverToBoxAdapter(child: _TrendingRow(movies: data.trending, onTap: _open)),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
      ],
      if (data.popular.isNotEmpty) ...[
        const SliverToBoxAdapter(child: _Header('Popular in clubs', subtitle: 'The films clubs have voted for most')),
        MoviePosterGrid(movies: data.popular, onTap: _open),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
      ],
      if (data.trending.isEmpty && data.popular.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.screen,
            child: ClCard(
              child: ClEmptyState(
                compact: true,
                illustration: ClIllustration.search,
                message: 'Nothing to browse yet. Search for a film above.',
              ),
            ),
          ),
        ),
      const SliverToBoxAdapter(child: SuggestedClubsWidget()),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: ClSectionHeader(title: title, subtitle: subtitle, padding: AppSpacing.screen),
  );
}

/// The one failure state for browse content. The whole card is the retry
/// control, so the copy can say "tap to retry" honestly.
class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: ClCard(
        onTap: onRetry,
        child: Row(
          children: [
            const Icon(AppIcons.offline, size: 24, color: AppColors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text("Couldn't load Discover — tap to retry", style: AppTextStyles.title)),
          ],
        ),
      ),
    );
  }
}

class _TrendingRow extends StatelessWidget {
  const _TrendingRow({required this.movies, required this.onTap});

  final List<TmdbMovie> movies;
  final void Function(TmdbMovie) onTap;

  static const double _width = 132;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _width * 3 / 2 + MoviePosterTile.textHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screen,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final m = movies[i];
          return MoviePosterTile(movie: m, width: _width, onTap: m.id == null ? null : () => onTap(m));
        },
      ),
    );
  }
}

class _BrowseSkeleton extends StatelessWidget {
  const _BrowseSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading films',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClSkeleton(height: 20, width: 150),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      const ClSkeleton(width: 132, height: 198, radius: AppRadius.md),
                      const SizedBox(width: AppSpacing.md),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              const ClSkeleton(height: 20, width: 100),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Clubs to join": real clubs the user isn't in yet, from the club API.
/// Each card opens the club, where joining happens. Hidden while loading,
/// on error, or when there's nothing to suggest, so it never shows fake clubs.
class SuggestedClubsWidget extends ConsumerWidget {
  const SuggestedClubsWidget({super.key, this.max = 3});

  final int max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allCommunitiesProvider).valueOrNull;
    final joined = ref.watch(joinedCommunitiesProvider).valueOrNull;
    if (all == null || joined == null) return const SizedBox.shrink();
    final mine = {for (final c in joined) c.id};
    final clubs = all.where((c) => c.id != null && !mine.contains(c.id)).take(max).toList();
    if (clubs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header('Clubs to join', subtitle: 'Open a club to see what it watches'),
        Padding(
          padding: AppSpacing.screen,
          child: Column(
            children: [
              for (final c in clubs) ...[
                _ClubCard(club: c),
                if (c != clubs.last) const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});

  final Community club;

  @override
  Widget build(BuildContext context) {
    final name = club.name ?? 'Club';
    final members = club.members.length;
    final description = club.description;
    return ClCard(
      onTap: () => context.push('/communities/${club.id}'),
      child: Row(
        children: [
          ClAvatar(name: name, radius: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('$members member${members == 1 ? '' : 's'}', style: AppTextStyles.caption),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(description, style: AppTextStyles.bodySm, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
