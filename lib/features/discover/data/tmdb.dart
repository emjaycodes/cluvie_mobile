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
/// suggested, as raw Mongo documents (`{_id, tmdbId, title, posterPath…}`),
/// with when it was fetched.
///
/// Fetched once and shared by Discover and Movie Detail, which looks films
/// up in it by TMDB id (the API has no direct lookup yet). Invalidate it
/// after a suggestion so both pick the new film up. Movie Detail refetches
/// it when it is older than [catalogMaxAge] or failed earlier.
typedef Catalog = ({List<Map<String, dynamic>> docs, DateTime fetchedAt});

final catalogProvider = FutureProvider<Catalog>((ref) async {
  final body = (await ref.read(apiClientProvider).get('/movies/list')).data;
  final list = body is List ? body : (body is Map && body['data'] is List ? body['data'] as List : const []);
  return (
    docs: [
      for (final m in list)
        if (m is Map) Map<String, dynamic>.from(m),
    ],
    fetchedAt: DateTime.now(),
  );
});

/// How long Movie Detail trusts the shared catalog. Other members suggest
/// films too, and only this device's suggestions invalidate it. Variable
/// only so tests can shorten it (widget tests can't fake `DateTime.now`).
Duration catalogMaxAge = const Duration(minutes: 2);

/// TMDB's weekly trending list, shared by Discover and Suggest. Its own
/// provider so catalog changes (suggestions) don't refetch TMDB.
final trendingProvider = FutureProvider<List<TmdbMovie>>((ref) => ref.read(tmdbRepositoryProvider).trending());

/// How many catalog films Discover shows. `/movies/list` has no limit and
/// grows with every suggestion.
const kSuggestedInClubsLimit = 24;

/// Discover's browse content.
///
/// A source that fails keeps the list it had (flagged [stale], so a refresh
/// can say it failed); with nothing earlier it comes back empty with its
/// `...Failed` flag set, so the screen offers a retry for that section. The
/// whole feed only fails when both sources fail with nothing to show.
typedef DiscoverFeed = ({
  List<TmdbMovie> trending,
  List<TmdbMovie> suggested,
  bool trendingFailed,
  bool suggestedFailed,
  bool stale,
});

/// Not auto-disposed, so switching tabs doesn't refetch. Refresh by
/// invalidating [trendingProvider] and [catalogProvider].
final discoverFeedProvider = FutureProvider<DiscoverFeed>((ref) async {
  final previous = ref.state.valueOrNull;
  Object? firstError;
  StackTrace? firstStack;
  Future<List<TmdbMovie>?> attempt(Future<List<TmdbMovie>> f) => f.then<List<TmdbMovie>?>((v) => v, onError: (Object e, StackTrace s) {
    firstError ??= e;
    firstStack ??= s;
    return null;
  });
  final suggested = ref
      .watch(catalogProvider.future)
      .then((c) => [for (final d in c.docs) TmdbMovie.fromJson(d)].take(kSuggestedInClubsLimit).toList());
  final results = await Future.wait([attempt(ref.watch(trendingProvider.future)), attempt(suggested)]);
  final trending = results[0] ?? ((previous?.trending.isNotEmpty ?? false) ? previous!.trending : null);
  final picks = results[1] ?? ((previous?.suggested.isNotEmpty ?? false) ? previous!.suggested : null);
  if (trending == null && picks == null) Error.throwWithStackTrace(firstError!, firstStack!);
  return (
    trending: trending ?? const <TmdbMovie>[],
    suggested: picks ?? const <TmdbMovie>[],
    trendingFailed: trending == null,
    suggestedFailed: picks == null,
    stale: (results[0] == null && trending != null) || (results[1] == null && picks != null),
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
