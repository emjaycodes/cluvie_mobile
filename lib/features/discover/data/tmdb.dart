import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A film from the backend's TMDB proxy (`/tmdb/*`).
///
/// Every field but [title] can be missing; the UI shows nothing rather than
/// inventing a value (no placeholder poster, no made-up year).
class TmdbMovie {
  const TmdbMovie({required this.title, this.id, this.posterPath, this.releaseDate, this.rating});

  /// TMDB id. Null means the film can't be opened or suggested.
  final int? id;
  final String title;
  final String? posterPath;
  final String? releaseDate;
  final double? rating;

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['tmdbId'];
    final rating = json['vote_average'] ?? json['voteAverage'];
    String? str(Object? v) => v is String && v.isNotEmpty ? v : null;
    return TmdbMovie(
      id: rawId is int ? rawId : int.tryParse('${rawId ?? ''}'),
      title: str(json['title']) ?? str(json['name']) ?? 'Untitled',
      posterPath: str(json['poster_path']) ?? str(json['posterPath']) ?? str(json['poster']),
      releaseDate: str(json['release_date']) ?? str(json['releaseDate']),
      rating: rating is num ? rating.toDouble() : null,
    );
  }

  /// Full poster URL at TMDB [size] (w185, w342, w500…), or null.
  String? posterUrl([String size = 'w342']) {
    final p = posterPath;
    if (p == null) return null;
    if (p.startsWith('http')) return p;
    return 'https://image.tmdb.org/t/p/$size$p';
  }

  /// Release year, or null when unknown.
  String? get year {
    final d = releaseDate;
    return d != null && d.length >= 4 ? d.substring(0, 4) : null;
  }

  @override
  bool operator ==(Object other) => other is TmdbMovie && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);
}

/// Accepts a bare list or `{results: [...]}` (and the proxy's named keys).
List<TmdbMovie> parseMovies(Object? data, [List<String> keys = const ['results']]) {
  Object? list = data;
  if (data is Map) {
    list = null;
    for (final k in keys) {
      if (data[k] is List) {
        list = data[k];
        break;
      }
    }
  }
  if (list is! List) return const [];
  return [
    for (final m in list)
      if (m is Map) TmdbMovie.fromJson(Map<String, dynamic>.from(m)),
  ];
}

class TmdbRepository {
  TmdbRepository(this._ref);
  final Ref _ref;

  Future<List<TmdbMovie>> trending() async =>
      parseMovies((await _ref.read(apiClientProvider).get('/tmdb/trending')).data, const ['results', 'trending']);

  Future<List<TmdbMovie>> popular() async =>
      parseMovies((await _ref.read(apiClientProvider).get('/tmdb/popular')).data, const ['results', 'popular']);

  Future<List<TmdbMovie>> search(String query) async =>
      parseMovies((await _ref.read(apiClientProvider).get('/tmdb/search', params: {'query': query})).data);
}

final tmdbRepositoryProvider = Provider<TmdbRepository>(TmdbRepository.new);

/// Discover's browse content. Not auto-disposed, so switching tabs doesn't
/// refetch; pull-to-refresh invalidates it.
final discoverFeedProvider = FutureProvider<({List<TmdbMovie> trending, List<TmdbMovie> popular})>((ref) async {
  final repo = ref.read(tmdbRepositoryProvider);
  final results = await Future.wait([repo.trending(), repo.popular()]);
  return (trending: results[0], popular: results[1]);
});

/// Search results per query. Keyed by query, so a slow response for an old
/// query can never replace the results for the current one.
final movieSearchProvider = FutureProvider.autoDispose.family<List<TmdbMovie>, String>(
  (ref, query) => ref.read(tmdbRepositoryProvider).search(query),
);

/// Searches start at this many characters.
const kMinSearchLength = 2;

/// The search debounce (a behaviour contract; see design/ux-audit.md §0).
const kSearchDebounce = Duration(milliseconds: 300);

/// Discover's current search, kept outside the screen so it survives tab
/// switches (the shell rebuilds tabs).
final discoverQueryProvider = StateProvider<String>((ref) => '');
