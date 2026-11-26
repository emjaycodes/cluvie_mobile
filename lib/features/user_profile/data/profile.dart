import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart' show isMongoId;
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
    this.bio = '',
    this.avatarUrl,
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
  final String bio;
  final String? avatarUrl;

  static MyProfile? fromJson(Object? json) {
    if (json is Map && json['data'] is Map) json = json['data'];
    if (json is! Map || json['_id'] is! String) return null;
    int count(Object? v) => v is List ? v.length : 0;
    final name = json['username'];
    final email = json['email'];
    final xp = json['xp'];
    final bio = json['bio'];
    final avatar = json['avatarUrl'];
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
      bio: bio is String ? bio : '',
      avatarUrl: avatar is String && avatar.trim().isNotEmpty ? avatar.trim() : null,
    );
  }
}

final myProfileProvider = FutureProvider.autoDispose<MyProfile>((ref) async {
  final res = await ref.read(apiClientProvider).get('/users/me');
  final profile = MyProfile.fromJson(res.data);
  if (profile == null) throw StateError('Unexpected profile response');
  return profile;
});

/// Someone else's profile, from `GET /users/:id`.
class PublicProfile {
  const PublicProfile({
    required this.id,
    required this.username,
    this.bio = '',
    this.avatarUrl,
    this.xp = 0,
    this.joinedAt,
    this.followers = 0,
    this.following = 0,
    this.suggestions = 0,
    this.clubs = 0,
    this.isFollowing = false,
    this.isMe = false,
  });

  final String id;
  final String username;
  final String bio;
  final String? avatarUrl;
  final int xp;
  final DateTime? joinedAt;
  final int followers;
  final int following;
  final int suggestions;
  final int clubs;
  final bool isFollowing;
  final bool isMe;

  static PublicProfile? fromJson(Object? json) {
    if (json is Map && json['data'] is Map) json = json['data'];
    if (json is! Map || json['_id'] is! String) return null;
    final name = json['username'];
    final bio = json['bio'];
    final avatar = json['avatarUrl'];
    final xp = json['xp'];
    final joined = json['joinedAt'];
    final counts = json['counts'];
    int count(String key) {
      if (counts is! Map) return 0;
      final v = counts[key];
      return v is num ? v.toInt() : 0;
    }

    return PublicProfile(
      id: json['_id'] as String,
      username: name is String && name.trim().isNotEmpty ? name.trim() : 'This member',
      bio: bio is String ? bio : '',
      avatarUrl: avatar is String && avatar.trim().isNotEmpty ? avatar.trim() : null,
      xp: xp is num ? xp.toInt() : 0,
      joinedAt: joined is String ? DateTime.tryParse(joined) : null,
      followers: count('followers'),
      following: count('following'),
      suggestions: count('suggestions'),
      clubs: count('clubs'),
      isFollowing: json['isFollowing'] == true,
      isMe: json['isMe'] == true,
    );
  }
}

/// A public profile that isn't there: unknown id, deleted account, or an id
/// that isn't a Mongo id at all (demo links).
class ProfileNotFound implements Exception {
  const ProfileNotFound();
}

/// One public profile. Ids that aren't Mongo ids fail as "not found" without
/// a request: the backend would answer 404 for them anyway.
final userProfileProvider = FutureProvider.autoDispose.family<PublicProfile, String>((ref, id) async {
  if (!isMongoId(id)) throw const ProfileNotFound();
  try {
    final res = await ref.read(apiClientProvider).get('/users/$id');
    final profile = PublicProfile.fromJson(res.data);
    if (profile == null) throw const ProfileNotFound();
    return profile;
  } on ApiException catch (e) {
    if (e.statusCode == 404) throw const ProfileNotFound();
    rethrow;
  }
});

/// Optimistic follow state for a profile while its request is in flight and
/// until the profile refetches. Null means "use the fetched value".
final followOverrideProvider = StateProvider.autoDispose.family<bool?, String>((ref, id) => null);

/// What happened when following or unfollowing.
enum FollowOutcome {
  /// The follow state now matches the request.
  done,

  /// The request was to follow yourself; a quiet no-op.
  cannotFollowSelf,

  /// The profile no longer exists.
  notFound,

  /// Network or server failure; the new state was rolled back.
  failed,
}

/// Follows or unfollows [id], showing the new state at once and putting it
/// back if the request fails. "Already following" and "not following" count
/// as success. Following yourself is a quiet no-op, not an error.
Future<FollowOutcome> setFollowing(WidgetRef ref, String id, {required bool following}) async {
  if (!isMongoId(id)) return FollowOutcome.notFound;
  final override = ref.read(followOverrideProvider(id).notifier);
  final before = override.state;
  override.state = following;
  try {
    await ref.read(apiClientProvider).post(following ? '/users/$id/follow' : '/users/$id/unfollow');
  } on ApiException catch (e) {
    final body = e.responseBody;
    final code = body is Map ? body['code'] : null;
    if (code == 'CANNOT_FOLLOW_SELF') {
      override.state = before;
      return FollowOutcome.cannotFollowSelf;
    }
    if (e.statusCode == 404) {
      override.state = before;
      return FollowOutcome.notFound;
    }
    if (e.statusCode != 400) {
      override.state = before;
      return FollowOutcome.failed;
    }
    // A 400 is "Already following" or "Not following": the goal is met.
  } catch (_) {
    override.state = before;
    return FollowOutcome.failed;
  }
  ref.invalidate(myProfileProvider);
  ref.invalidate(userProfileProvider(id));
  return FollowOutcome.done;
}

/// Why an edit to the signed-in profile was refused.
enum ProfileUpdateError { usernameTaken, invalidProfile, failed }

/// Saves `PATCH /users/me` and refetches the signed-in profile. Returns null
/// on success. A blank [avatarUrl] removes the picture.
Future<ProfileUpdateError?> updateMyProfile(
  WidgetRef ref, {
  String? username,
  String? bio,
  String? avatarUrl,
}) async {
  final body = <String, dynamic>{
    if (username != null) 'username': username,
    if (bio != null) 'bio': bio,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };
  if (body.isEmpty) return ProfileUpdateError.invalidProfile;
  try {
    await ref.read(apiClientProvider).patch('/users/me', data: body);
  } on ApiException catch (e) {
    final response = e.responseBody;
    final code = response is Map ? response['code'] : null;
    if (e.statusCode == 409 || code == 'USERNAME_TAKEN') return ProfileUpdateError.usernameTaken;
    if (e.statusCode == 400 || code == 'INVALID_PROFILE') return ProfileUpdateError.invalidProfile;
    return ProfileUpdateError.failed;
  } catch (_) {
    return ProfileUpdateError.failed;
  }
  ref.invalidate(myProfileProvider);
  return null;
}

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
