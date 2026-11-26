import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A film from the backend: its TMDB proxy (`/tmdb/*`, `/movies/trending`)
/// or its own catalog (`/movies/list`).
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

/// Accepts a bare list or a `{data: [...]}` / `{results: [...]}` envelope.
/// The backend wraps most lists in `{success, data}`.
List<TmdbMovie> parseMovies(Object? data, [List<String> keys = const ['data', 'results']]) {
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

  /// TMDB's weekly trending list (`GET /movies/trending`).
  Future<List<TmdbMovie>> trending() async =>
      parseMovies((await _ref.read(apiClientProvider).get('/movies/trending')).data);

  Future<List<TmdbMovie>> search(String query) async =>
      parseMovies((await _ref.read(apiClientProvider).get('/tmdb/search', params: {'query': query})).data);
}

final tmdbRepositoryProvider = Provider<TmdbRepository>(TmdbRepository.new);

/// Cluvie's film catalog (`GET /movies/list`): every film any club has
/// suggested, as raw Mongo documents (`{_id, tmdbId, title, posterPath…}`).
///
/// Fetched once and shared by Discover and Movie Detail, which looks films
/// up in it by TMDB id (the API has no direct lookup yet). Invalidate it
/// after a suggestion so both pick the new film up.
final catalogProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final body = (await ref.read(apiClientProvider).get('/movies/list')).data;
  final list = body is List ? body : (body is Map && body['data'] is List ? body['data'] as List : const []);
  return [
    for (final m in list)
      if (m is Map) Map<String, dynamic>.from(m),
  ];
});

/// How many catalog films Discover shows. `/movies/list` has no limit and
/// grows with every suggestion.
const kSuggestedInClubsLimit = 24;

/// Discover's browse content. A source that fails comes back empty with its
/// `...Failed` flag set, so the screen can say so and offer a retry for that
/// section; the whole feed only fails when both do.
typedef DiscoverFeed = ({
  List<TmdbMovie> trending,
  List<TmdbMovie> suggested,
  bool trendingFailed,
  bool suggestedFailed,
});

/// Not auto-disposed, so switching tabs doesn't refetch; pull-to-refresh
/// invalidates it (and [catalogProvider]).
final discoverFeedProvider = FutureProvider<DiscoverFeed>((ref) async {
  final repo = ref.read(tmdbRepositoryProvider);
  // The two lists come from different sources (TMDB vs. our own catalog), so
  // one failing shouldn't hide the other.
  Object? firstError;
  StackTrace? firstStack;
  Future<List<TmdbMovie>?> attempt(Future<List<TmdbMovie>> f) => f.then<List<TmdbMovie>?>((v) => v, onError: (Object e, StackTrace s) {
    firstError ??= e;
    firstStack ??= s;
    return null;
  });
  final suggested = ref
      .watch(catalogProvider.future)
      .then((docs) => [for (final d in docs) TmdbMovie.fromJson(d)].take(kSuggestedInClubsLimit).toList());
  final results = await Future.wait([attempt(repo.trending()), attempt(suggested)]);
  if (results.every((r) => r == null)) Error.throwWithStackTrace(firstError!, firstStack!);
  return (
    trending: results[0] ?? const <TmdbMovie>[],
    suggested: results[1] ?? const <TmdbMovie>[],
    trendingFailed: results[0] == null,
    suggestedFailed: results[1] == null,
  );
});

/// Search results per query. Keyed by query, so a slow response for an old
/// query can never replace the results for the current one.
final movieSearchProvider = FutureProvider.autoDispose.family<List<TmdbMovie>, String>((ref, query) async {
  final results = await ref.read(tmdbRepositoryProvider).search(query);
  // Keep results for 5 minutes after the last listener goes, so coming back
  // to a tab doesn't search again.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);
  return results;
});

/// Searches start at this many characters.
const kMinSearchLength = 2;

/// The search debounce (a behaviour contract; see design/ux-audit.md §0).
const kSearchDebounce = Duration(milliseconds: 300);

/// Discover's current search, kept outside the screen so it survives tab
/// switches (the shell rebuilds tabs).
final discoverQueryProvider = StateProvider<String>((ref) => '');
