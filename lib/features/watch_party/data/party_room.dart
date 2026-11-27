import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Room chat messages: the server's limit.
const kRoomMessageMax = 500;

/// Someone in the room.
typedef RoomMember = ({String userId, String? username});

/// A chat message (`watchparty:message`, not stored by the server).
class RoomMessage {
  const RoomMessage({required this.id, required this.userId, required this.text, required this.sentAt, this.username});
  final String id;
  final String userId;
  final String? username;
  final String text;
  final DateTime sentAt;

  static RoomMessage? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['userId'] is! String || json['text'] is! String) return null;
    final name = json['username'];
    return RoomMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: name is String && name.isNotEmpty ? name : null,
      text: json['text'] as String,
      sentAt: DateTime.tryParse('${json['sentAt']}')?.toLocal() ?? DateTime.now(),
    );
  }
}

/// Something that happened in a party's live room.
sealed class RoomEvent {
  const RoomEvent();
}

/// The socket is connected (again). The room must be (re)joined.
class RoomConnected extends RoomEvent {
  const RoomConnected();
}

/// The socket dropped; it reconnects by itself.
class RoomDisconnected extends RoomEvent {
  const RoomDisconnected();
}

/// A connection attempt failed. [unauthorized]: the token is expired or
/// revoked, so retrying won't help. Otherwise the socket keeps retrying.
class RoomConnectFailed extends RoomEvent {
  const RoomConnectFailed({required this.unauthorized});
  final bool unauthorized;
}

/// Someone joined or left (`watchparty:presence`).
class RoomPresence extends RoomEvent {
  const RoomPresence(this.userId, this.action, {this.username});
  final String userId;

  /// `joined` or `left`.
  final String action;
  final String? username;
}

/// Someone reacted (`watchparty:reaction`).
class RoomReaction extends RoomEvent {
  const RoomReaction(this.userId, this.key);
  final String userId;
  final String key;
}

/// A chat message (`watchparty:message`; the sender gets theirs too).
class RoomChat extends RoomEvent {
  const RoomChat(this.message);
  final RoomMessage message;
}

/// The party changed (`watchparty:updated`, `participant_joined`,
/// `participant_left`): refetch it.
class RoomPartyChanged extends RoomEvent {
  const RoomPartyChanged();
}

/// The host deleted the party (`watchparty:deleted`).
class RoomPartyDeleted extends RoomEvent {
  const RoomPartyDeleted();
}

enum RoomJoinStatus { ok, forbidden, failed }

/// The answer to `watchparty:join`: who's in the room when ok.
typedef RoomJoin = ({RoomJoinStatus status, List<RoomMember> roster});

/// Why a reaction or message wasn't sent (the ack's `error`), or null.
typedef RoomSendError = String?;

/// One live-room connection (socket.io, `watchparty:*` events). An
/// interface so tests can drive the room without a server.
abstract class RoomLink {
  Stream<RoomEvent> get events;

  /// Connects; events start arriving.
  void connect();

  /// `watchparty:join` with ack and roster.
  Future<RoomJoin> join();

  /// `watchparty:reaction`. Null when sent, else the server's reason.
  Future<RoomSendError> react(String key);

  /// `watchparty:message`. Null when sent, else the server's reason
  /// (`rate_limited`, `too_long`, `empty`, `not_in_room`).
  Future<RoomSendError> send(String text);

  /// `watchparty:leave`, then disconnects for good.
  void close();
}

/// Where the socket lives: the API's origin, with socket.io's path under
/// any prefix the API has (`https://x.com/cluvie/api` → origin
/// `https://x.com`, path `/cluvie/socket.io`).
({String origin, String path}) socketEndpoint(String apiBaseUrl) {
  final uri = Uri.parse(apiBaseUrl.trim());
  var prefix = uri.path.replaceAll(RegExp(r'/+$'), '');
  if (prefix.endsWith('/api')) prefix = prefix.substring(0, prefix.length - 4);
  return (origin: uri.replace(path: '', query: null, fragment: null).toString(), path: '$prefix/socket.io');
}

class SocketRoomLink implements RoomLink {
  SocketRoomLink({required this.partyId, required this.token, String? apiBaseUrl})
      : _endpoint = socketEndpoint(apiBaseUrl ?? ApiClient.baseUrl);

  final String partyId;
  final String token;
  final ({String origin, String path}) _endpoint;
  final _events = StreamController<RoomEvent>.broadcast();
  io.Socket? _socket;

  @override
  Stream<RoomEvent> get events => _events.stream;

  void _add(RoomEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  bool _mine(Object? data) => data is Map && data['watchPartyId'] == partyId;

  @override
  void connect() {
    final s = io.io(
      _endpoint.origin,
      io.OptionBuilder()
          .setPath(_endpoint.path)
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .build(),
    );
    _socket = s;
    s.onConnect((_) => _add(const RoomConnected()));
    s.onDisconnect((_) => _add(const RoomDisconnected()));
    s.onConnectError((e) => _add(RoomConnectFailed(unauthorized: '$e'.contains('unauthorized'))));
    s.on('watchparty:presence', (data) {
      if (!_mine(data) || (data as Map)['userId'] is! String) return;
      final action = '${data['action'] ?? ''}';
      if (action != 'joined' && action != 'left') return;
      final name = data['username'];
      _add(RoomPresence(data['userId'] as String, action, username: name is String && name.isNotEmpty ? name : null));
    });
    s.on('watchparty:reaction', (data) {
      if (_mine(data) && (data as Map)['userId'] is String && data['key'] is String) {
        _add(RoomReaction(data['userId'] as String, data['key'] as String));
      }
    });
    s.on('watchparty:message', (data) {
      if (!_mine(data)) return;
      if (RoomMessage.fromJson(data) case final m?) _add(RoomChat(m));
    });
    for (final e in ['watchparty:updated', 'watchparty:participant_joined', 'watchparty:participant_left']) {
      s.on(e, (data) {
        if (_mine(data)) _add(const RoomPartyChanged());
      });
    }
    s.on('watchparty:deleted', (data) {
      if (_mine(data)) _add(const RoomPartyDeleted());
    });
    s.connect();
  }

  Future<Object?> _ack(String event, Map<String, Object?> data) async {
    final s = _socket;
    if (s == null || !s.connected) return {'ok': false, 'error': 'not_connected'};
    try {
      return await s.emitWithAckAsync(event, data).timeout(const Duration(seconds: 8));
    } catch (_) {
      return {'ok': false, 'error': 'timeout'};
    }
  }

  @override
  Future<RoomJoin> join() async {
    final ack = await _ack('watchparty:join', {'watchPartyId': partyId});
    if (ack is Map && ack['ok'] == true) {
      return (
        status: RoomJoinStatus.ok,
        roster: [
          for (final m in ack['roster'] is List ? ack['roster'] as List : const [])
            if (m is Map && m['userId'] is String)
              (userId: m['userId'] as String, username: m['username'] is String ? m['username'] as String : null),
        ],
      );
    }
    final forbidden = ack is Map && ack['error'] == 'forbidden';
    return (status: forbidden ? RoomJoinStatus.forbidden : RoomJoinStatus.failed, roster: const <RoomMember>[]);
  }

  RoomSendError _errorOf(Object? ack) => ack is Map && ack['ok'] == true ? null : (ack is Map ? '${ack['error'] ?? 'failed'}' : 'failed');

  @override
  Future<RoomSendError> react(String key) async =>
      _errorOf(await _ack('watchparty:reaction', {'watchPartyId': partyId, 'key': key}));

  @override
  Future<RoomSendError> send(String text) async =>
      _errorOf(await _ack('watchparty:message', {'watchPartyId': partyId, 'text': text}));

  @override
  void close() {
    final s = _socket;
    _socket = null;
    if (s != null) {
      if (s.connected) s.emit('watchparty:leave', {'watchPartyId': partyId});
      s.dispose();
    }
    _events.close();
  }
}

/// Opens a room connection for a party, or null when signed out. Tests
/// override it with a fake.
final roomLinkFactoryProvider = Provider<Future<RoomLink?> Function(String partyId)>((ref) {
  return (partyId) async {
    final token = await AuthRepository().savedToken();
    if (token == null || token.isEmpty) return null;
    return SocketRoomLink(partyId: partyId, token: token);
  };
});
