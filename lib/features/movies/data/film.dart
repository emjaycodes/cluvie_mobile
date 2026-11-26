import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The watchlist toggle stays hidden until the API can take a TMDB id.
///
/// `POST /watchlist/add` and `/watchlist/remove` take the catalog's Mongo
/// `Movie._id`, and a film opened from Discover only has its TMDB id. Turn
/// this on once the backend accepts `{tmdbId}` (its `findOrCreateMovie`
/// already does the lookup for suggestions).
const kWatchlistAvailable = false;

/// Thrown when a film doesn't exist (no id, or the API says 404).
class FilmNotFound implements Exception {
  const FilmNotFound();
}

/// A film's details from `GET /tmdb/:id` (the backend's TMDB proxy, which
/// returns TMDB's movie object in `{success, data}`).
class FilmDetail {
  const FilmDetail({
    required this.tmdbId,
    required this.title,
    this.overview,
    this.tagline,
    this.releaseDate,
    this.runtimeMinutes,
    this.genres = const [],
    this.rating,
    this.posterPath,
    this.backdropPath,
  });

  final int tmdbId;
  final String title;
  final String? overview;
  final String? tagline;
  final String? releaseDate;
  final int? runtimeMinutes;
  final List<String> genres;

  /// TMDB's average, 0–10. Null when TMDB has no votes for it.
  final double? rating;
  final String? posterPath;
  final String? backdropPath;

  factory FilmDetail.fromJson(Map<String, dynamic> json, int fallbackId) {
    String? str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final rawId = json['id'];
    final runtime = json['runtime'];
    final rating = json['vote_average'];
    final votes = json['vote_count'];
    return FilmDetail(
      tmdbId: rawId is int ? rawId : fallbackId,
      title: str(json['title']) ?? str(json['name']) ?? 'Untitled',
      overview: str(json['overview']),
      tagline: str(json['tagline']),
      releaseDate: str(json['release_date']),
      runtimeMinutes: runtime is int && runtime > 0 ? runtime : null,
      genres: [
        for (final g in (json['genres'] is List ? json['genres'] as List : const []))
          if (g is Map && str(g['name']) != null) str(g['name'])!,
      ],
      rating: rating is num && rating > 0 && (votes is! num || votes > 0) ? rating.toDouble() : null,
      posterPath: str(json['poster_path']),
      backdropPath: str(json['backdrop_path']),
    );
  }

  String? get year {
    final d = releaseDate;
    return d != null && d.length >= 4 ? d.substring(0, 4) : null;
  }

  /// "2h 19m", "45m", or null.
  String? get runtimeLabel {
    final m = runtimeMinutes;
    if (m == null) return null;
    final h = m ~/ 60;
    final rest = m % 60;
    if (h == 0) return '${rest}m';
    return rest == 0 ? '${h}h' : '${h}h ${rest}m';
  }

  String? posterUrl([String size = 'w500']) => _image(posterPath, size);
  String? backdropUrl([String size = 'w780']) => _image(backdropPath, size);

  static String? _image(String? path, String size) {
    if (path == null) return null;
    if (path.startsWith('http')) return path;
    return 'https://image.tmdb.org/t/p/$size$path';
  }

  /// The shape the suggest sheet takes.
  TmdbMovie toTmdbMovie() =>
      TmdbMovie(id: tmdbId, title: title, posterPath: posterPath, releaseDate: releaseDate, rating: rating);
}

/// Film details by TMDB id. Throws [FilmNotFound] for an unknown film.
final filmDetailProvider = FutureProvider.autoDispose.family<FilmDetail, int>((ref, tmdbId) async {
  try {
    final res = await ref.read(apiClientProvider).get('/tmdb/$tmdbId');
    final body = res.data;
    final data = body is Map && body['data'] is Map ? body['data'] : body;
    if (data is! Map) throw const FilmNotFound();
    return FilmDetail.fromJson(Map<String, dynamic>.from(data), tmdbId);
  } on ApiException catch (e) {
    if (e.statusCode == 404 || e.statusCode == 400) throw const FilmNotFound();
    rethrow;
  }
});

/// A film in Cluvie's own catalog: the Mongo id that discussions, comments
/// and the watchlist are keyed by.
typedef CatalogFilm = ({String id, String title, String? posterUrl});

/// Looks up a TMDB film in Cluvie's catalog. Null means no club has
/// suggested it yet, so it has no discussion.
///
/// The API has no lookup by TMDB id, so this scans the shared
/// [catalogProvider] (one `GET /movies/list` for every film). Swap in a
/// direct lookup once the backend has one. To refetch, invalidate
/// [catalogProvider], not this.
final catalogFilmProvider = FutureProvider.autoDispose.family<CatalogFilm?, int>((ref, tmdbId) async {
  // A catalog that failed earlier, or is older than catalogMaxAge, is
  // refetched when a film is opened: other members' suggestions only show
  // up that way. Invalidating re-runs this provider on the fresh list. (The
  // await moves this out of the build phase, where invalidating isn't
  // allowed.)
  final shared = ref.read(catalogProvider);
  final stale = !shared.isLoading &&
      (shared.hasError || (shared.valueOrNull != null && DateTime.now().difference(shared.value!.fetchedAt) > catalogMaxAge));
  if (stale) {
    await Future<void>.value();
    ref.invalidate(catalogProvider);
  }
  final catalog = await ref.watch(catalogProvider.future);
  for (final m in catalog.docs) {
    final t = m['tmdbId'];
    if ((t is int ? t : int.tryParse('$t')) != tmdbId) continue;
    final id = m['_id'];
    if (id is! String || id.isEmpty) return null;
    final poster = TmdbMovie.fromJson(m).posterUrl('w185');
    return (id: id, title: '${m['title'] ?? ''}', posterUrl: poster);
  }
  return null;
});
