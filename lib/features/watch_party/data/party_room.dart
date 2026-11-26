import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/repository/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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

/// The server refused the connection (`unauthorized`: expired or revoked
/// token) or couldn't be reached.
class RoomConnectFailed extends RoomEvent {
  const RoomConnectFailed({required this.unauthorized});
  final bool unauthorized;
}

/// `watchparty:presence` from someone else: `joined`, `left`, or a
/// client-defined action ([RoomLink.here], [RoomLink.react]).
class RoomPresence extends RoomEvent {
  const RoomPresence(this.userId, this.action);
  final String userId;
  final String action;
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

/// Why entering a room failed.
enum RoomJoinResult { ok, forbidden, failed }

/// One live-room connection (socket.io, `watchparty:*` events). An
/// interface so tests can drive the room without a server.
abstract class RoomLink {
  Stream<RoomEvent> get events;

  /// Connects; events start arriving.
  void connect();

  /// `watchparty:join` with ack.
  Future<RoomJoinResult> join();

  /// Tells a newcomer you're already here (answers their `joined`).
  void here();

  /// Sends a reaction (presence action `react:<key>`).
  void react(String key);

  /// `watchparty:leave`, then disconnects for good.
  void close();
}

/// Presence actions this app sends on top of the server's joined/left.
/// The server relays any action string to the room. A dedicated reaction
/// event is a backend ask.
const kHereAction = 'here';
const kReactPrefix = 'react:';

class SocketRoomLink implements RoomLink {
  SocketRoomLink({required this.partyId, required this.token, String? url}) : _url = url ?? ApiClient.socketUrl;

  final String partyId;
  final String token;
  final String _url;
  final _events = StreamController<RoomEvent>.broadcast();
  io.Socket? _socket;

  @override
  Stream<RoomEvent> get events => _events.stream;

  void _add(RoomEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  @override
  void connect() {
    final s = io.io(
      _url,
      io.OptionBuilder()
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
      if (data is Map && data['watchPartyId'] == partyId && data['userId'] is String) {
        _add(RoomPresence(data['userId'] as String, '${data['action'] ?? ''}'));
      }
    });
    for (final e in ['watchparty:updated', 'watchparty:participant_joined', 'watchparty:participant_left']) {
      s.on(e, (_) => _add(const RoomPartyChanged()));
    }
    s.on('watchparty:deleted', (_) => _add(const RoomPartyDeleted()));
    s.connect();
  }

  @override
  Future<RoomJoinResult> join() async {
    final s = _socket;
    if (s == null) return RoomJoinResult.failed;
    try {
      final ack = await s.emitWithAckAsync('watchparty:join', {'watchPartyId': partyId}).timeout(const Duration(seconds: 8));
      if (ack is Map && ack['ok'] == true) return RoomJoinResult.ok;
      if (ack is Map && ack['error'] == 'forbidden') return RoomJoinResult.forbidden;
      return RoomJoinResult.failed;
    } catch (_) {
      return RoomJoinResult.failed;
    }
  }

  @override
  void here() => _socket?.emit('watchparty:presence', {'watchPartyId': partyId, 'action': kHereAction});

  @override
  void react(String key) => _socket?.emit('watchparty:presence', {'watchPartyId': partyId, 'action': '$kReactPrefix$key'});

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
