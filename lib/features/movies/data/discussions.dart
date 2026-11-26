import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The longest post the composer accepts.
const kMaxPostLength = 2000;

/// One post in a film's discussion (`/discussions/:movieId`).
class DiscussionPost {
  const DiscussionPost({
    required this.id,
    required this.text,
    required this.createdAt,
    this.authorId,
    this.authorName,
    this.pinned = false,
    this.likedBy = const {},
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String? authorId;

  /// Null when the API didn't include the author (e.g. a deleted account).
  final String? authorName;
  final bool pinned;

  /// User ids that upvoted. The API's upvote is one-way: it can't be undone.
  final Set<String> likedBy;

  int get likes => likedBy.length;

  DiscussionPost likedByUser(String userId) => DiscussionPost(
        id: id,
        text: text,
        createdAt: createdAt,
        authorId: authorId,
        authorName: authorName,
        pinned: pinned,
        likedBy: {...likedBy, userId},
      );

  static DiscussionPost? fromJson(Map<String, dynamic> json, {String? fallbackAuthorName}) {
    final id = json['_id'];
    final text = json['text'];
    if (id is! String || text is! String) return null;
    final user = json['userId'];
    String? authorId;
    String? authorName;
    if (user is Map) {
      authorId = user['_id'] is String ? user['_id'] as String : null;
      final name = user['username'];
      authorName = name is String && name.trim().isNotEmpty ? name.trim() : null;
    } else if (user is String) {
      authorId = user;
    }
    final upvotes = json['upvotes'];
    return DiscussionPost(
      id: id,
      text: text,
      createdAt: (DateTime.tryParse('${json['createdAt']}') ?? DateTime.now()).toLocal(),
      authorId: authorId,
      authorName: authorName ?? fallbackAuthorName,
      pinned: json['pinned'] == true,
      likedBy: {for (final u in (upvotes is List ? upvotes : const [])) u is Map ? '${u['_id']}' : '$u'},
    );
  }
}

/// Pinned first, then newest first.
int comparePosts(DiscussionPost a, DiscussionPost b) {
  if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
  return b.createdAt.compareTo(a.createdAt);
}

/// A film's discussion, keyed by the catalog movie id.
final discussionProvider =
    AsyncNotifierProvider.autoDispose.family<DiscussionNotifier, List<DiscussionPost>, String>(DiscussionNotifier.new);

class DiscussionNotifier extends AutoDisposeFamilyAsyncNotifier<List<DiscussionPost>, String> {
  @override
  Future<List<DiscussionPost>> build(String movieId) async {
    final res = await ref.read(apiClientProvider).get('/discussions/$movieId');
    final body = res.data;
    final list = body is List ? body : (body is Map && body['data'] is List ? body['data'] as List : const []);
    return [
      for (final p in list)
        if (p is Map) DiscussionPost.fromJson(Map<String, dynamic>.from(p)),
    ].whereType<DiscussionPost>().toList()
      ..sort(comparePosts);
  }

  /// Bumped per reload, so a slow response can't overwrite a newer one.
  int _reloads = 0;

  /// Reloads; a failure keeps the posts on screen and is rethrown. A
  /// response that is no longer the latest request's is dropped.
  Future<void> reload() async {
    final mine = ++_reloads;
    final fresh = await AsyncValue.guard(() => build(arg));
    if (mine != _reloads) return;
    if (fresh.hasError && state.hasValue) {
      Error.throwWithStackTrace(fresh.error!, fresh.stackTrace!);
    }
    state = fresh;
  }

  /// Posts [text]. Throws on failure; the caller keeps the draft.
  Future<void> post(String text, {String? authorName, String? authorId}) async {
    final res = await ref.read(apiClientProvider).post('/discussions', data: {'movieId': arg, 'text': text});
    final body = res.data;
    final raw = body is Map ? (body['discussion'] ?? body['data']) : null;
    final created = raw is Map
        ? DiscussionPost.fromJson(Map<String, dynamic>.from(raw), fallbackAuthorName: authorName)
        : null;
    final post = created ??
        DiscussionPost(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          text: text,
          createdAt: DateTime.now(),
          authorId: authorId,
          authorName: authorName,
        );
    state = AsyncData([...?state.valueOrNull, post]..sort(comparePosts));
    if (ref.exists(homeFeedProvider)) ref.invalidate(homeFeedProvider); // Recent discussions
  }

  /// Likes a post as [userId], optimistically. Rolls back and rethrows on
  /// failure, except "already upvoted", which is what the user wanted.
  Future<void> like(String postId, String userId) async {
    final before = state.valueOrNull;
    if (before == null) return;
    state = AsyncData([for (final p in before) p.id == postId ? p.likedByUser(userId) : p]);
    try {
      await ref.read(apiClientProvider).post('/discussions/$postId/upvote');
    } catch (e) {
      final body = e is ApiException ? e.responseBody : null;
      if (body is Map && '${body['message']}'.toLowerCase().contains('already')) return;
      state = AsyncData(before);
      rethrow;
    }
  }
}
