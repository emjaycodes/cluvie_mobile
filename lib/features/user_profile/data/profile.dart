import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in user, from `GET /users/me` (a bare user object).
class MyProfile {
  const MyProfile({
    required this.id,
    required this.username,
    this.email,
    this.isAdmin = false,
    this.xp = 0,
    this.suggested = 0,
    this.voted = 0,
    this.comments = 0,
    this.followers = 0,
    this.following = 0,
  });

  final String id;
  final String username;
  final String? email;
  final bool isAdmin;
  final int xp;
  final int suggested;
  final int voted;
  final int comments;
  final int followers;
  final int following;

  static MyProfile? fromJson(Object? json) {
    if (json is Map && json['data'] is Map) json = json['data'];
    if (json is! Map || json['_id'] is! String) return null;
    int count(Object? v) => v is List ? v.length : 0;
    final name = json['username'];
    final email = json['email'];
    final xp = json['xp'];
    return MyProfile(
      id: json['_id'] as String,
      username: name is String && name.trim().isNotEmpty ? name.trim() : 'You',
      email: email is String && email.isNotEmpty ? email : null,
      isAdmin: json['role'] == 'admin',
      xp: xp is num ? xp.toInt() : 0,
      suggested: count(json['suggestedMovies']),
      voted: count(json['votedMovies']),
      comments: count(json['comments']),
      followers: count(json['followers']),
      following: count(json['following']),
    );
  }
}

final myProfileProvider = FutureProvider.autoDispose<MyProfile>((ref) async {
  final res = await ref.read(apiClientProvider).get('/users/me');
  final profile = MyProfile.fromJson(res.data);
  if (profile == null) throw StateError('Unexpected profile response');
  return profile;
});

/// A saved film: its catalog id (what the watchlist stores) and the film.
typedef SavedFilm = ({String movieId, TmdbMovie film});

/// The user's watchlist (`GET /watchlist`, a bare array of catalog films).
final watchlistProvider =
    AsyncNotifierProvider.autoDispose<WatchlistNotifier, List<SavedFilm>>(WatchlistNotifier.new);

class WatchlistNotifier extends AutoDisposeAsyncNotifier<List<SavedFilm>> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<List<SavedFilm>> build() async {
    final body = (await _api.get('/watchlist')).data;
    final list = body is List ? body : (body is Map && body['data'] is List ? body['data'] as List : const []);
    return [
      for (final m in list)
        if (m is Map && m['_id'] is String) (movieId: m['_id'] as String, film: TmdbMovie.fromJson(Map<String, dynamic>.from(m))),
    ];
  }

  /// Removes a film at once; puts it back where it was if the request
  /// fails, and rethrows.
  Future<void> remove(SavedFilm item) async {
    final before = state.valueOrNull;
    if (before == null) return;
    final index = before.indexWhere((f) => f.movieId == item.movieId);
    if (index < 0) return;
    state = AsyncData([for (final f in before) if (f.movieId != item.movieId) f]);
    try {
      await _api.post('/watchlist/remove', data: {'movieId': item.movieId});
    } catch (_) {
      // Put back only this film, into the list as it is now: other removes
      // since then stay removed (R10-N6).
      final now = state.valueOrNull ?? const <SavedFilm>[];
      if (!now.any((f) => f.movieId == item.movieId)) {
        state = AsyncData([...now]..insert(index.clamp(0, now.length), item));
      }
      rethrow;
    }
  }

  /// Undo for [remove]: saves it again at [index].
  Future<void> restore(SavedFilm item, int index) async {
    final now = state.valueOrNull ?? const <SavedFilm>[];
    if (now.any((f) => f.movieId == item.movieId)) return;
    final next = [...now]..insert(index.clamp(0, now.length), item);
    state = AsyncData(next);
    try {
      await _api.post('/watchlist/add', data: {'movieId': item.movieId});
    } catch (e) {
      // "Already in watchlist" means it's back; anything else, take it out.
      final body = e is ApiException ? e.responseBody : null;
      final already = body is Map && body['code'] == 'ALREADY_IN_WATCHLIST';
      if (!already) state = AsyncData([for (final f in next) if (f.movieId != item.movieId) f]);
      if (!already) rethrow;
    }
  }
}
