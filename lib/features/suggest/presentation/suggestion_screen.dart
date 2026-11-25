import 'dart:async';

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/discover/presentation/movie_poster_tile.dart';
import 'package:cluvie_mobile/features/suggest/presentation/suggest_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Suggest a film to a club.
///
/// Step 1 (this screen): find the film. Trending films show until you search;
/// search is debounced ([kSearchDebounce]) from [kMinSearchLength] letters.
/// Step 2 ([showSuggestSheet]): tap a film to pick the club, add a note and
/// submit.
///
/// The Suggest tab opens it with no [communityId]. A club's "Suggest a film"
/// (`/communities/:id/suggest`) opens it with one: the screen gets a back
/// button and the sheet preselects that club.
///
/// Gold budget: the sheet's submit button is the only gold.
class SuggestMovieScreen extends ConsumerStatefulWidget {
  const SuggestMovieScreen({super.key, this.communityId});

  final String? communityId;

  @override
  ConsumerState<SuggestMovieScreen> createState() => _SuggestMovieScreenState();
}

class _SuggestMovieScreenState extends ConsumerState<SuggestMovieScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(kSearchDebounce, () {
      if (mounted) setState(() => _query = text.trim());
    });
    setState(() {}); // the "keep typing" hint
  }

  void _submitNow(String text) {
    _debounce?.cancel();
    setState(() => _query = text.trim());
  }

  Future<void> _suggest(TmdbMovie movie) async {
    final club = await showSuggestSheet(context, movie, communityId: widget.communityId);
    if (club == null || !mounted) return;
    ClSnackbar.show(context, message: 'Suggested ${movie.title} to ${club.name ?? 'your club'}.');
    // From a club's page: done, go back to it. From the tab: ready for another.
    if (widget.communityId != null && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _search.clear();
    _submitNow('');
  }

  Future<void> _refresh() async {
    try {
      if (_query.length >= kMinSearchLength) {
        ref.invalidate(movieSearchProvider(_query));
        await ref.read(movieSearchProvider(_query).future);
      } else {
        ref.invalidate(discoverFeedProvider);
        await ref.read(discoverFeedProvider.future);
      }
    } catch (_) {
      // With earlier results on screen, say the refresh failed.
      final cached =
          _query.length >= kMinSearchLength
              ? ref.read(movieSearchProvider(_query)).hasValue
              : ref.read(discoverFeedProvider).hasValue;
      if (mounted && cached) {
        ClSnackbar.show(context, message: "Couldn't refresh. Showing earlier results.", type: ClSnackbarType.error);
      }
    }
  }

  /// "to Cinema Sundays" on a club's deep link, once its name is known.
  String? get _clubName {
    final id = widget.communityId;
    if (id == null) return null;
    for (final c in ref.watch(joinedCommunitiesProvider).valueOrNull ?? const []) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.length >= kMinSearchLength;
    final typed = _search.text.trim();
    final tooShort = typed.isNotEmpty && typed.length < kMinSearchLength;
    final busy = searching && ref.watch(movieSearchProvider(_query)).isLoading;
    final deepLink = widget.communityId != null;
    final clubName = _clubName;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
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
              leading: deepLink ? const ClBackButton() : null,
              backgroundColor: AppColors.bg,
              scrolledUnderElevation: 0,
              titleSpacing: deepLink ? 0 : AppSpacing.gutter,
              title: Semantics(header: true, child: Text('Suggest a film', style: AppTextStyles.h2)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: Text(
                  clubName != null
                      ? 'Pick a film for $clubName. It goes into the club’s next poll.'
                      : 'Pick a film, then choose the club. It goes into that club’s next poll.',
                  style: AppTextStyles.bodySm,
                ),
              ),
            ),
            SliverPadding(
              padding: AppSpacing.screen,
              sliver: SliverToBoxAdapter(
                child: ClSearchField(
                  controller: _search,
                  hintText: 'Search films',
                  busy: busy,
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
            ...(searching ? _results() : _trending()),
            // Same clearance above the floating nav as Home.
            SliverToBoxAdapter(child: SizedBox(height: ClBottomNavBar.contentPadding(context) + AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _header(String title, {String? subtitle}) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClSectionHeader(title: title, subtitle: subtitle, padding: AppSpacing.screen),
    ),
  );

  Widget _card(Widget child) =>
      SliverToBoxAdapter(child: Padding(padding: AppSpacing.screen, child: ClCard(child: child)));

  List<Widget> _results() {
    final results = ref.watch(movieSearchProvider(_query));
    return [
      _header("Results for '$_query'", subtitle: 'Tap a film to suggest it'),
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
                  _card(
                    ClErrorState(
                      compact: true,
                      title: "Search didn't go through",
                      onRetry: () => ref.invalidate(movieSearchProvider(_query)),
                    ),
                  ),
                ],
            data:
                (movies) =>
                    movies.isEmpty
                        ? [
                          _card(
                            ClEmptyState(
                              compact: true,
                              illustration: ClIllustration.search,
                              message: "No results for '$_query' — try another title",
                            ),
                          ),
                        ]
                        : [MoviePosterGrid(movies: movies, onTap: _suggest)],
          )),
    ];
  }

  List<Widget> _trending() {
    final feed = ref.watch(discoverFeedProvider);
    final data = feed.valueOrNull;
    if (data == null && feed.hasError && !feed.isLoading) {
      return [
        _card(
          ClErrorState(
            compact: true,
            title: "Couldn't load trending films",
            message: 'Search for a film above, or try again.',
            onRetry: () => ref.invalidate(discoverFeedProvider),
          ),
        ),
      ];
    }
    if (data == null) return const [SliverToBoxAdapter(child: MoviePosterGridSkeleton())];
    if (data.trending.isEmpty) {
      return [
        _card(
          const ClEmptyState(
            compact: true,
            illustration: ClIllustration.search,
            message: 'Search for any film above to suggest it.',
          ),
        ),
      ];
    }
    return [
      _header('Trending to suggest', subtitle: 'Tap a film to suggest it'),
      MoviePosterGrid(movies: data.trending, onTap: _suggest),
    ];
  }
}
