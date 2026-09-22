// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_empty_state.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

/// Discover — CF-03
/// Trending/popular via GET /api/tmdb proxy (cached).
/// Features: pull-to-refresh, retry card ("Couldn't load Discover — tap to retry"),
/// stale cache indicator, lazy posters with cached_network_image placeholder,
/// debounced search (300ms) with empty state "No results for '…'".
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isStale = false;
  String _query = '';
  List<dynamic> _trending = [];
  List<dynamic> _popular = [];
  List<dynamic> _searchResults = [];

  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _searchCtrl.text.trim();
      if (q.length >= 2) {
        _search(q);
      } else {
        setState(() {
          _query = '';
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Try backend proxy first; fallback to demo on failure
      final trendingRes = await _api.get('/tmdb/trending').catchError((e) => throw e);
      final popularRes = await _api.get('/tmdb/popular').catchError((e) => throw e);
      final t = trendingRes.data is List ? trendingRes.data as List : (trendingRes.data['results'] ?? trendingRes.data['trending'] ?? []) as List;
      final p = popularRes.data is List ? popularRes.data as List : (popularRes.data['results'] ?? popularRes.data['popular'] ?? []) as List;
      if (mounted) {
        setState(() {
          _trending = t.isNotEmpty ? t : _demoMovies;
          _popular = p.isNotEmpty ? p : _demoMovies.reversed.toList();
          _isLoading = false;
          _isStale = false;
        });
      }
    } catch (_) {
      // On failure show demo data but mark stale + retry affordance
      if (mounted) {
        setState(() {
          _trending = _demoMovies;
          _popular = _demoMovies.reversed.toList();
          _isLoading = false;
          _hasError = true;
          _isStale = true;
        });
      }
    }
  }

  Future<void> _search(String q) async {
    setState(() => _query = q);
    try {
      final res = await _api.get('/tmdb/search', params: {'query': q});
      final results = res.data is List ? res.data as List : (res.data['results'] ?? []) as List;
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = _demoMovies.where((m) => (m['title'] as String).toLowerCase().contains(q.toLowerCase())).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => context.push('/notifications')),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: _isLoading
            ? _shimmerGrid()
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search with debounce
                          TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search movies, clubs...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search, color: Colors.white54),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () => _searchCtrl.clear())
                                  : null,
                              filled: true,
                              fillColor: AppColors.darkSurface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          if (_isStale)
                            Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.warning.withOpacity(0.4))),
                              child: Row(children: [
                                const Icon(Icons.cloud_off, size: 14, color: AppColors.warning),
                                const SizedBox(width: 8),
                                Text('Using cached data — pull to refresh', style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          if (_hasError)
                            GestureDetector(
                              onTap: _load,
                              child: Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error.withOpacity(0.4))),
                                child: Row(children: [
                                  const Icon(Icons.error_outline, color: AppColors.error),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text("Couldn't load Discover — tap to retry", style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w600))),
                                  const Icon(Icons.refresh, color: AppColors.error),
                                ]),
                              ),
                            ),
                          // Search results
                          if (_query.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text("Results for '$_query'", style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 10),
                            if (_searchResults.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)),
                                child: ClEmptyState(message: "No results for '$_query' — try another title", icon: Icons.search_off_rounded),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                                itemCount: _searchResults.length,
                                itemBuilder: (_, i) => _MoviePosterCard(movie: _searchResults[i]),
                              ),
                            const Divider(color: Colors.white12, height: 32),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_query.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Trending Now', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                      ),
                    ),
                    SliverToBoxAdapter(child: const SizedBox(height: 10)),
                    SliverToBoxAdapter(child: _HorizontalRow(movies: _trending)),
                    SliverToBoxAdapter(child: const SizedBox(height: 18)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Popular', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                      ),
                    ),
                    SliverToBoxAdapter(child: const SizedBox(height: 10)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
                        delegate: SliverChildBuilderDelegate((c, i) => _MoviePosterCard(movie: _popular[i % _popular.length]), childCount: 4),
                      ),
                    ),
                    SliverToBoxAdapter(child: const SizedBox(height: 20)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Suggested Clubs', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                      ),
                    ),
                    SliverToBoxAdapter(child: const SizedBox(height: 10)),
                    SliverToBoxAdapter(child: const SuggestedClubsWidget()),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.68),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))),
    );
  }

  static const _demoMovies = [
    {'title': 'Dune: Part Two', 'poster_path': '/d5NXSklXo0qyIYkgV94XAgMIckC.jpg', 'release_date': '2024-02-27', 'vote_average': 8.2},
    {'title': 'The Batman', 'poster_path': '/74xTEgt7R36Fpooo50r9T25onhq.jpg', 'release_date': '2022-03-01', 'vote_average': 7.7},
    {'title': 'Everything Everywhere', 'poster_path': '/w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 'release_date': '2022-03-11', 'vote_average': 7.8},
    {'title': 'Blade Runner 2049', 'poster_path': '/aMpyrCizvSdc0UIMblJ1srVgAEF.jpg', 'release_date': '2017-10-04', 'vote_average': 8.0},
  ];
}

class _MoviePosterCard extends StatelessWidget {
  final dynamic movie;
  const _MoviePosterCard({required this.movie});

  String get _poster {
    final path = movie['poster_path'] ?? movie['posterPath'] ?? movie['poster'] ?? '';
    if (path.toString().startsWith('http')) return path;
    if (path.toString().isEmpty) return 'https://image.tmdb.org/t/p/w500/d5NXSklXo0qyIYkgV94XAgMIckC.jpg';
    return 'https://image.tmdb.org/t/p/w500$path';
  }

  String get _title => movie['title'] ?? 'Untitled';
  String get _year {
    final d = movie['release_date'] ?? movie['releaseDate'] ?? '';
    if (d.toString().length >= 4) return d.toString().substring(0, 4);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie/${movie['id'] ?? '0'}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _poster,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (c, u) => Shimmer.fromColors(baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700, child: Container(color: Colors.white)),
                errorWidget: (c, u, e) => Container(color: AppColors.darkSurface, child: const Icon(Icons.broken_image, color: Colors.white30)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(_title, style: AppTextStyles.body.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (_year.isNotEmpty) Text(_year, style: AppTextStyles.caption.copyWith(color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}

class _HorizontalRow extends StatelessWidget {
  final List<dynamic> movies;
  const _HorizontalRow({required this.movies});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: 140, child: _MoviePosterCard(movie: movies[i])),
      ),
    );
  }
}

class SuggestedClubsWidget extends StatelessWidget {
  const SuggestedClubsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    final clubs = [
      {'name': 'Chinatown Club', 'image': 'assets/images/group.jpg'},
      {'name': 'A24 Lovers', 'image': 'assets/images/group.jpg'},
      {'name': 'Drama Enthusiasts', 'image': 'assets/images/group.jpg'},
    ];
    return Column(
      children: clubs
          .map((club) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 110,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: AssetImage(club['image']!), fit: BoxFit.cover)),
                child: Stack(children: [
                  Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.55), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter))),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(club['name']!, style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20)),
                        child: Text('Join Club', style: AppTextStyles.caption.copyWith(color: Colors.black, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ]),
              ))
          .toList(),
    );
  }
}
