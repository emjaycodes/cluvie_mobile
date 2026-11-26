import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart' show isMongoId;
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The live room (`/watch-parties/:id/live`) runs over the backend's
/// socket: presence, reactions and host start/end. No shared video.
const kWatchPartyRoomAvailable = true;

/// A scheduled party this long past its start counts as over.
const kPartyStaleAfter = Duration(hours: 4);

/// How early before the start time people can go into the room.
const kRoomOpensBefore = Duration(minutes: 30);

/// Whether [p]'s room can be entered now by [me]: the party is open, you're
/// going or hosting, and it's live, starting soon, or you're the host.
bool canEnterRoom(WatchParty p, String? me, {DateTime? now}) {
  if (!kWatchPartyRoomAvailable || p.isOver(now) || !p.isGoing(me)) return false;
  if (p.status == PartyStatus.live || p.isHost(me)) return true;
  return !(now ?? DateTime.now()).isBefore(p.scheduledAt.subtract(kRoomOpensBefore));
}

enum PartyStatus { scheduled, live, ended, cancelled }

/// A watch party (`/api/watchparties`). The backend keeps legacy aliases
/// (`createdBy`/`host`, `communityId`/`community`, `startTime`/`scheduledAt`);
/// both are read.
class WatchParty {
  const WatchParty({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.status,
    this.description,
    this.film,
    this.clubId,
    this.clubName,
    this.hostId,
    this.hostName,
    this.participantIds = const [],
    this.participantNames = const {},
    this.isPrivate = false,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final PartyStatus status;
  final TmdbMovie? film;
  final String? clubId;
  final String? clubName;
  final String? hostId;
  final String? hostName;
  final List<String> participantIds;

  /// Usernames by id, when the backend populated participants (detail only).
  final Map<String, String> participantNames;
  final bool isPrivate;

  bool isHost(String? me) => me != null && me == hostId;
  bool isGoing(String? me) => me != null && (participantIds.contains(me) || isHost(me));

  /// Not ended or cancelled, by status alone. Prefer [isOver]: the backend
  /// never ends a party by itself.
  bool get isOpen => status == PartyStatus.scheduled || status == PartyStatus.live;

  /// Ended, cancelled, or a scheduled party more than [kPartyStaleAfter]
  /// past its start that nobody started (the backend doesn't end those).
  bool isOver([DateTime? now]) =>
      !isOpen ||
      (status == PartyStatus.scheduled && (now ?? DateTime.now()).isAfter(scheduledAt.add(kPartyStaleAfter)));

  static String? _id(Object? v) {
    if (v is String && v.isNotEmpty) return v;
    if (v is Map && v['_id'] is String) return v['_id'] as String;
    return null;
  }

  static String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  /// Null when the document is missing its id or date.
  static WatchParty? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = _id(json['_id']);
    final when = DateTime.tryParse('${json['scheduledAt'] ?? json['startTime']}')?.toLocal();
    if (id == null || when == null) return null;
    final host = json['host'] ?? json['createdBy'];
    final club = json['community'] ?? json['communityId'];
    final movie = json['movie'];
    final names = <String, String>{};
    final ids = <String>[];
    for (final p in json['participants'] is List ? json['participants'] as List : const []) {
      final pid = _id(p);
      if (pid == null || ids.contains(pid)) continue;
      ids.add(pid);
      final name = p is Map ? _str(p['username']) : null;
      if (name != null) names[pid] = name;
    }
    final hostId = _id(host);
    if (hostId != null && !ids.contains(hostId)) ids.insert(0, hostId);
    return WatchParty(
      id: id,
      title: _str(json['title']) ?? 'Watch party',
      description: _str(json['description']),
      scheduledAt: when,
      status: switch (json['status']) {
        'live' => PartyStatus.live,
        'ended' => PartyStatus.ended,
        'cancelled' => PartyStatus.cancelled,
        _ => PartyStatus.scheduled,
      },
      film: movie is Map ? TmdbMovie.fromJson(Map<String, dynamic>.from(movie)) : null,
      clubId: _id(club),
      clubName: club is Map ? _str(club['name']) : null,
      hostId: hostId,
      hostName: host is Map ? _str(host['username']) : null,
      participantIds: ids,
      participantNames: names,
      isPrivate: json['isPrivate'] == true,
    );
  }
}

class PartyNotFound implements Exception {
  const PartyNotFound();
}

/// Parties the user can see (public ones, and private ones in their clubs):
/// everything not over yet, soonest first (`upcoming=true`), then the 30
/// most recent past ones (`past=true`, newest first).
final watchPartiesProvider = FutureProvider.autoDispose<List<WatchParty>>((ref) async {
  final api = ref.read(apiClientProvider);
  List<WatchParty> parse(Object? body) {
    final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : const []);
    return [
      for (final p in list)
        if (WatchParty.fromJson(p) case final party?) party,
    ];
  }

  final results = await Future.wait([
    api.get('/watchparties', params: {'upcoming': 'true', 'limit': 100}),
    api.get('/watchparties', params: {'past': 'true', 'limit': 30}),
  ]);
  final seen = <String>{};
  return [
    for (final r in results)
      for (final p in parse(r.data))
        if (seen.add(p.id)) p,
  ];
});

/// One party (`GET /watchparties/:id`). A non-Mongo id (demo link) or 404
/// is [PartyNotFound], without a request for the former.
final watchPartyProvider = FutureProvider.autoDispose.family<WatchParty, String>((ref, id) async {
  if (!isMongoId(id)) throw const PartyNotFound();
  try {
    final res = await ref.read(apiClientProvider).get('/watchparties/$id');
    final body = res.data;
    final party = WatchParty.fromJson(body is Map ? (body['data'] ?? body) : null);
    if (party == null) throw const PartyNotFound();
    return party;
  } on ApiException catch (e) {
    if (e.statusCode == 404) throw const PartyNotFound();
    rethrow;
  }
});

/// Why going or not going didn't happen.
enum PartyRefusal {
  /// Only club members can join (403 on join).
  notMember,

  /// Only the host can change the party (403 on update).
  notHost,

  /// The host can't leave their own party.
  hostCannotLeave,

  /// Ended or cancelled.
  closed,
  notFound,
  failed,
}

/// The outcome of an RSVP or host action that went through.
class PartyActionDone {
  const PartyActionDone({required this.refreshed});

  /// False when the party couldn't be reloaded afterwards.
  final bool refreshed;
}

typedef PartyResult = (PartyActionDone?, PartyRefusal?);

/// Reloads the party (kept alive while waiting) and the list.
Future<bool> _reload(WidgetRef ref, String id) async {
  ref.invalidate(watchPartiesProvider);
  ref.invalidate(homeFeedProvider);
  final keep = ref.listenManual(watchPartyProvider(id), (_, __) {});
  try {
    final _ = await ref.refresh(watchPartyProvider(id).future);
    return true;
  } catch (_) {
    return false;
  } finally {
    keep.close();
  }
}

Future<PartyResult> _act(WidgetRef ref, String id, Future<void> Function() call, {bool hostAction = false}) async {
  try {
    await call();
  } on ApiException catch (e) {
    final body = e.responseBody;
    final message = body is Map ? '${body['message'] ?? ''}'.toLowerCase() : '';
    final code = body is Map ? body['code'] : null;
    final refusal = switch (e.statusCode) {
      403 when code == 'NOT_HOST' => PartyRefusal.notHost,
      403 when code == 'NOT_A_MEMBER' => PartyRefusal.notMember,
      403 => hostAction ? PartyRefusal.notHost : PartyRefusal.notMember,
      404 => PartyRefusal.notFound,
      // The goal is already met: you're going, or you're not.
      400 when code == 'ALREADY_PARTICIPANT' || message.contains('already a participant') => null,
      400 when code == 'NOT_PARTICIPANT' => null,
      400 when code == 'HOST_CANNOT_LEAVE' || message.contains('host cannot leave') => PartyRefusal.hostCannotLeave,
      400 when code == 'PARTY_CLOSED' || message.contains('cannot join watch party with status') => PartyRefusal.closed,
      _ => PartyRefusal.failed,
    };
    if (refusal != null) return (null, refusal);
  } catch (_) {
    return (null, PartyRefusal.failed);
  }
  return (PartyActionDone(refreshed: await _reload(ref, id)), null);
}

/// RSVP yes (`POST /watchparties/:id/join`). Club members only. Waits for
/// the party to reload, so callers can stay busy until then.
Future<PartyResult> joinParty(WidgetRef ref, String id) =>
    _act(ref, id, () => ref.read(apiClientProvider).post('/watchparties/$id/join'));

/// Take back an RSVP (`POST /watchparties/:id/leave`). Not for the host.
Future<PartyResult> leaveParty(WidgetRef ref, String id) =>
    _act(ref, id, () => ref.read(apiClientProvider).post('/watchparties/$id/leave'));

/// Sets a party's status; host only (`PATCH /watchparties/:id/update`).
/// `live` starts it, `ended` ends it, `cancelled` cancels it (kept in
/// members' lists, unlike delete).
Future<PartyResult> setPartyStatus(WidgetRef ref, String id, String status) => _act(
      ref,
      id,
      () => ref.read(apiClientProvider).patch('/watchparties/$id/update', data: {'status': status}),
      hostAction: true,
    );

/// Cancel a party; host only.
Future<PartyResult> cancelParty(WidgetRef ref, String id) => setPartyStatus(ref, id, 'cancelled');
