import 'package:intl/intl.dart';
import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart' show isMongoId;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationKind { follow, comment, vote, suggestion, alert, poll, discussion, watchParty }

/// One of the signed-in user's notifications (`GET /notifications`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.link,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  /// The backend's `relatedLink`, e.g. `/movies/:catalogId`, `/polls/:id`,
  /// `/watchparty/:id`, `/users/:id`.
  final String? link;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        kind: kind,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        link: link,
      );

  static AppNotification? fromJson(Object? json) {
    if (json is! Map || json['_id'] is! String) return null;
    String? str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final title = str(json['title']);
    final message = str(json['message']);
    if (title == null && message == null) return null;
    return AppNotification(
      id: json['_id'] as String,
      kind: switch (json['type']) {
        'FOLLOW' => NotificationKind.follow,
        'COMMENT' => NotificationKind.comment,
        'VOTE' => NotificationKind.vote,
        'movie_suggestion' => NotificationKind.suggestion,
        'POLL' => NotificationKind.poll,
        'DISCUSSION' => NotificationKind.discussion,
        'WATCHPARTY' => NotificationKind.watchParty,
        _ => NotificationKind.alert,
      },
      title: breakableTokens(readableDates(title ?? message!)),
      message: breakableTokens(readableDates(message ?? '')),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
      link: str(json['relatedLink']),
    );
  }
}

final _isoDate = RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?');

/// Some server messages embed a raw timestamp ("scheduled for
/// 2026-11-30T19:00:00.000Z"). Shows it in local time instead:
/// "Sun 30 Nov at 20:00".
String readableDates(String text) => text.replaceAllMapped(_isoDate, (m) {
      final when = DateTime.tryParse(m[0]!);
      if (when == null) return m[0]!;
      final local = when.toLocal();
      return '${DateFormat('EEE d MMM').format(local)} at ${DateFormat.Hm().format(local)}';
    });

/// The newest 100 notifications. Read state changes locally first
/// ([NotificationsNotifier.markRead]).
final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsNotifier, List<AppNotification>>(NotificationsNotifier.new);

class NotificationsNotifier extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<List<AppNotification>> build() async {
    final res = await _api.get('/notifications', params: {'limit': 100});
    final body = res.data;
    final list = body is Map && body['notifications'] is List ? body['notifications'] as List : (body is List ? body : const []);
    return [
      for (final n in list)
        if (AppNotification.fromJson(n) case final notification?) notification,
    ];
  }

  void _replace(String id, AppNotification item) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([for (final n in list) n.id == id ? item : n]);
  }

  /// Marks one read (`PATCH /notifications/:id/read`): at once on screen,
  /// back to unread if the request fails.
  Future<void> markRead(String id) async {
    final current = state.valueOrNull?.where((n) => n.id == id).firstOrNull;
    if (current == null || current.isRead) return;
    final optimistic = current.copyWith(isRead: true);
    _replace(id, optimistic);
    try {
      await _api.patch('/notifications/$id/read');
    } catch (_) {
      // Undo only our own change: if a refresh replaced the item since,
      // the server's answer wins (R10-N5).
      final now = state.valueOrNull?.where((n) => n.id == id).firstOrNull;
      if (identical(now, optimistic)) _replace(id, current);
    } finally {
      ref.invalidate(unreadNotificationCountProvider);
    }
  }

  /// Deletes them all (`DELETE /notifications/clear`). Throws on failure,
  /// leaving the list as it was.
  Future<void> clearAll() async {
    await _api.delete('/notifications/clear');
    state = const AsyncData([]);
    ref.invalidate(unreadNotificationCountProvider);
  }
}

/// How many notifications are unread (`GET /notifications?isRead=false`,
/// reading `total`). Null while loading or when it failed.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final res = await ref.read(apiClientProvider).get('/notifications', params: {'isRead': 'false', 'limit': 1});
  final body = res.data;
  if (body is Map && body['total'] is int) return body['total'] as int;
  if (body is Map && body['notifications'] is List) return (body['notifications'] as List).length;
  return 0;
});

/// Where a notification's link leads in the app, or null when the app has
/// no screen for it. Film and poll links need a lookup (they carry catalog
/// and poll ids, not the TMDB or club id the app routes by); [resolve] does
/// it.
sealed class NotificationTarget {
  const NotificationTarget();
}

class DirectTarget extends NotificationTarget {
  const DirectTarget(this.route);
  final String route;
}

class FilmTarget extends NotificationTarget {
  const FilmTarget(this.catalogId);
  final String catalogId;
}

class PollTarget extends NotificationTarget {
  const PollTarget(this.pollId);
  final String pollId;
}

NotificationTarget? targetFor(String? link, {String? me}) {
  if (link == null) return null;
  final parts = Uri.tryParse(link)?.pathSegments ?? const <String>[];
  if (parts.length != 2 || !isMongoId(parts[1])) return null;
  final id = parts[1];
  return switch (parts[0]) {
    'watchparty' || 'watchparties' || 'watch-parties' => DirectTarget('/watch-parties/$id'),
    'communities' => DirectTarget('/communities/$id'),
    'movies' => FilmTarget(id),
    'polls' => PollTarget(id),
    // Other people's profiles aren't available yet (no GET /users/:id).
    'users' => id == me ? const DirectTarget('/profile') : null,
    _ => null,
  };
}

/// Turns a target into an app route; null when the lookup finds nothing to
/// open (e.g. a catalog film without a TMDB id). Throws when the lookup
/// itself fails.
Future<String?> resolve(ApiClient api, NotificationTarget target) async {
  switch (target) {
    case DirectTarget(:final route):
      return route;
    case FilmTarget(:final catalogId):
      final body = (await api.get('/movies/$catalogId')).data;
      final film = body is Map && body['data'] is Map ? body['data'] as Map : body;
      final tmdb = film is Map ? film['tmdbId'] : null;
      final id = tmdb is int ? tmdb : int.tryParse('${tmdb ?? ''}');
      return id == null ? null : '/movie/$id';
    case PollTarget(:final pollId):
      final body = (await api.get('/polls/$pollId')).data;
      final poll = body is Map && body['data'] is Map ? body['data'] as Map : null;
      final club = poll?['community'];
      final clubId = club is Map ? club['_id'] : club;
      return clubId is String && isMongoId(clubId) ? '/communities/$clubId/vote' : null;
  }
}
