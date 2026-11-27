import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/repository/auth_repository.dart';
import 'package:cluvie_mobile/features/watch_party/data/party_room.dart' show socketEndpoint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Club chat messages: the server's limit.
const kClubMessageMax = 500;

/// A stored club chat message (`GET /communities/:id/messages`, the socket's
/// `club:message`). [userId] and [username] are null when the sender's
/// account was deleted.
class ClubMessage {
  const ClubMessage({required this.id, required this.text, required this.createdAt, this.userId, this.username});
  final String id;
  final String? userId;
  final String? username;
  final String text;
  final DateTime createdAt;

  static ClubMessage? fromJson(Object? json) {
    if (json is! Map || json['_id'] is! String || json['text'] is! String) return null;
    final user = json['user'];
    final uid = user is Map && user['_id'] is String ? user['_id'] as String : null;
    final name = user is Map && user['username'] is String && (user['username'] as String).isNotEmpty ? user['username'] as String : null;
    return ClubMessage(
      id: json['_id'] as String,
      userId: uid,
      username: name,
      text: json['text'] as String,
      createdAt: DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
    );
  }
}

/// One page of history, newest first.
typedef ClubMessagePage = ({List<ClubMessage> messages, bool hasMore});

/// `GET /communities/:id/messages`. [before] is the oldest id already
/// shown, for the next (older) page.
Future<ClubMessagePage> fetchClubMessages(ApiClient api, String communityId, {String? before, int limit = 50}) async {
  final res = await api.get('/communities/$communityId/messages', params: {
    'limit': limit,
    if (before != null) 'before': before,
  });
  final body = res.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : const [];
  return (
    messages: [for (final m in list) if (ClubMessage.fromJson(m) case final c?) c],
    hasMore: body is Map && body['hasMore'] == true,
  );
}

/// `POST /communities/:id/messages`. Returns the stored message; the server
/// also sends it to everyone in the room (the sender included).
Future<ClubMessage> sendClubMessage(ApiClient api, String communityId, String text) async {
  final body = (await api.post('/communities/$communityId/messages', data: {'text': text})).data;
  final m = ClubMessage.fromJson(body is Map ? body['data'] : null);
  if (m == null) throw const FormatException('No message in the reply');
  return m;
}

/// `DELETE /communities/:id/messages/:messageId` (the sender or a club admin).
Future<void> deleteClubMessage(ApiClient api, String communityId, String messageId) =>
    api.delete('/communities/$communityId/messages/$messageId');

/// Something that happened on a club's live chat connection.
sealed class ClubChatEvent {
  const ClubChatEvent();
}

/// Connected (again). The room must be (re)joined.
class ChatConnected extends ClubChatEvent {
  const ChatConnected();
}

/// The socket dropped; it reconnects by itself.
class ChatDisconnected extends ClubChatEvent {
  const ChatDisconnected();
}

/// A connection attempt failed. [unauthorized]: the session is over.
class ChatConnectFailed extends ClubChatEvent {
  const ChatConnectFailed({required this.unauthorized});
  final bool unauthorized;
}

/// A new message (`club:message`).
class ChatIncoming extends ClubChatEvent {
  const ChatIncoming(this.message);
  final ClubMessage message;
}

/// A message was deleted (`club:message_deleted`).
class ChatDeleted extends ClubChatEvent {
  const ChatDeleted(this.messageId);
  final String messageId;
}

enum ChatJoinStatus { ok, forbidden, failed }

/// A club's live chat connection. Receive-only: sending and deleting go
/// over REST. An interface so tests can drive it without a server.
abstract class ClubChatLink {
  Stream<ClubChatEvent> get events;
  void connect();

  /// `club:join` with ack.
  Future<ChatJoinStatus> join();

  /// `club:leave`, then disconnects for good.
  void close();
}

class SocketClubChatLink implements ClubChatLink {
  SocketClubChatLink({required this.communityId, required this.token, String? apiBaseUrl})
      : _endpoint = socketEndpoint(apiBaseUrl ?? ApiClient.baseUrl);

  final String communityId;
  final String token;
  final ({String origin, String path}) _endpoint;
  final _events = StreamController<ClubChatEvent>.broadcast();
  io.Socket? _socket;

  @override
  Stream<ClubChatEvent> get events => _events.stream;

  void _add(ClubChatEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  bool _mine(Object? data) => data is Map && data['communityId'] == communityId;

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
    s.onConnect((_) => _add(const ChatConnected()));
    s.onDisconnect((_) => _add(const ChatDisconnected()));
    s.onConnectError((e) => _add(ChatConnectFailed(unauthorized: '$e'.contains('unauthorized'))));
    s.on('club:message', (data) {
      if (!_mine(data)) return;
      if (ClubMessage.fromJson(data) case final m?) _add(ChatIncoming(m));
    });
    s.on('club:message_deleted', (data) {
      if (_mine(data) && (data as Map)['messageId'] is String) _add(ChatDeleted(data['messageId'] as String));
    });
    s.connect();
  }

  @override
  Future<ChatJoinStatus> join() async {
    final s = _socket;
    if (s == null || !s.connected) return ChatJoinStatus.failed;
    try {
      final ack = await s.emitWithAckAsync('club:join', {'communityId': communityId}).timeout(const Duration(seconds: 8));
      if (ack is Map && ack['ok'] == true) return ChatJoinStatus.ok;
      return ack is Map && ack['error'] == 'forbidden' ? ChatJoinStatus.forbidden : ChatJoinStatus.failed;
    } catch (_) {
      return ChatJoinStatus.failed;
    }
  }

  @override
  void close() {
    final s = _socket;
    _socket = null;
    if (s != null) {
      if (s.connected) s.emit('club:leave', {'communityId': communityId});
      s.dispose();
    }
    _events.close();
  }
}

/// Opens a club's live chat connection, or null when signed out. Tests
/// override it with a fake.
final clubChatLinkFactoryProvider = Provider<Future<ClubChatLink?> Function(String communityId)>((ref) {
  return (communityId) async {
    final token = await AuthRepository().savedToken();
    if (token == null || token.isEmpty) return null;
    return SocketClubChatLink(communityId: communityId, token: token);
  };
});
