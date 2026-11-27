import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/club_chat.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _ola = '64b000000000000000000002';
const _club = '64c000000000000000000001';

int _seq = 0;
Map<String, Object?> _msg(String text, {String user = _ola, String? name = 'ola', int minutesAgo = 1}) => {
      '_id': '6a${(_seq++).toRadixString(16).padLeft(22, '0')}',
      'communityId': _club,
      'user': {'_id': user, 'username': name},
      'text': text,
      'createdAt': DateTime.now().subtract(Duration(minutes: minutesAgo)).toUtc().toIso8601String(),
    };

class _FakeLink implements ClubChatLink {
  ChatJoinStatus joinStatus = ChatJoinStatus.ok;
  final _events = StreamController<ClubChatEvent>.broadcast();
  int joins = 0;
  bool closed = false;

  void serve(ClubChatEvent e) => _events.add(e);

  @override
  Stream<ClubChatEvent> get events => _events.stream;
  @override
  void connect() => scheduleMicrotask(() => serve(const ChatConnected()));
  @override
  Future<ChatJoinStatus> join() async {
    joins++;
    return joinStatus;
  }

  @override
  void close() => closed = true;
}

/// A server with stored messages (newest last in [stored]).
class _Server {
  _Server({List<Map<String, Object?>>? messages, this.isMember = true, this.admins = const []})
      : stored = messages ?? [];
  final List<Map<String, Object?>> stored;
  bool isMember;
  List<String> admins;
  Object? sendError;
  Object? deleteError;
  final deleted = <String>[];

  Map<String, Object?> get club => {
        '_id': _club,
        'name': 'Cinema Sundays',
        'description': 'd',
        'owner': 'someone',
        'members': [
          {'user': 'someone', 'role': 'admin'},
          if (isMember) {'user': _me, 'role': admins.contains(_me) ? 'admin' : 'member'},
          {'user': _ola, 'role': 'member'},
        ],
        'admins': admins,
      };

  late final api = FakeApiClient(
    onGet: (path, params) {
      if (path == '/communities/$_club') return {'success': true, 'data': club};
      if (path == '/communities/$_club/messages') {
        if (!isMember) throw ApiException(message: 'x', statusCode: 403, responseBody: {'code': 'NOT_A_MEMBER'});
        final limit = params?['limit'] as int? ?? 50;
        var newestFirst = stored.reversed.toList();
        final before = params?['before'];
        if (before != null) newestFirst = newestFirst.skipWhile((m) => m['_id'] != before).skip(1).toList();
        return {'success': true, 'data': newestFirst.take(limit).toList(), 'hasMore': newestFirst.length > limit};
      }
      throw UnimplementedError(path);
    },
    onPost: (path, data) {
      if (path == '/communities/$_club/messages') {
        if (sendError != null) throw sendError!;
        final m = _msg(data!['text'] as String, user: _me, name: 'me_myself', minutesAgo: 0);
        stored.add(m);
        return {'success': true, 'data': m};
      }
      throw UnimplementedError(path);
    },
    onDelete: (path) {
      if (deleteError != null) throw deleteError!;
      deleted.add(path.split('/').last);
      return {'success': true};
    },
  );
}

Widget _app(_Server server, _FakeLink link, {Size size = const Size(390, 844), double scale = 1}) {
  final router = GoRouter(initialLocation: '/communities/$_club/chat', routes: [
    GoRoute(path: '/communities/:id', builder: (_, st) => Scaffold(body: Text('club ${st.pathParameters['id']}')), routes: [
      GoRoute(path: 'chat', builder: (_, st) => ClubChatScreen(communityId: st.pathParameters['id']!)),
    ]),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(server.api),
      currentUserIdProvider.overrideWith((ref) async => _me),
      clubChatLinkFactoryProvider.overrideWithValue((_) async => link),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), padding: const EdgeInsets.only(top: 47, bottom: 34)),
      child: MaterialApp.router(theme: AppTheme.theme, routerConfig: router),
    ),
  );
}

Future<void> _pump(WidgetTester t, Widget app, {Size size = const Size(390, 844)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(app);
  await t.pumpAndSettle();
}

Finder _sendButton() => find.byTooltip('Send');

void main() {
  setUpAll(() async => loadRealFonts());

  testWidgets('shows history, newest at the bottom, with names on each run of messages', (t) async {
    final server = _Server(messages: [
      _msg('First from ola', minutesAgo: 30),
      _msg('Second from ola', minutesAgo: 29),
      _msg('Mine', user: _me, name: 'me_myself', minutesAgo: 20),
    ]);
    await _pump(t, _app(server, _FakeLink()));
    expect(find.text('First from ola'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    expect(find.text('ola'), findsOneWidget, reason: 'one name for two messages in a row');
    expect(find.text('You'), findsNothing, reason: 'my own messages carry no name');
    expect(t.getTopLeft(find.text('Mine')).dy, greaterThan(t.getTopLeft(find.text('First from ola')).dy));
    expect(find.text('Load older messages'), findsNothing);
  });

  testWidgets('loads older pages until there are none', (t) async {
    final server = _Server(messages: [for (var i = 0; i < 55; i++) _msg('m$i', minutesAgo: 100 - i)]);
    await _pump(t, _app(server, _FakeLink()));
    expect(find.text('m54'), findsOneWidget);
    final older = find.widgetWithText(ClButton, 'Load older messages');
    await t.scrollUntilVisible(older, 400, scrollable: find.byType(Scrollable).first);
    await t.drag(find.byType(Scrollable).first, const Offset(0, 200));
    await t.pumpAndSettle();
    await t.tap(older);
    await t.pumpAndSettle();
    final calls = server.api.calls.where((c) => c.path == '/communities/$_club/messages').toList();
    expect(calls.last.params?['before'], server.stored[5]['_id'], reason: 'the oldest one shown');
    expect(find.text('Load older messages'), findsNothing);
    await t.scrollUntilVisible(find.text('m0'), 400, scrollable: find.byType(Scrollable).first);
    expect(find.text('m0'), findsOneWidget);
  });

  testWidgets('sending posts over REST, shows the message once (even with the live echo), and clears the box', (t) async {
    final server = _Server(messages: [_msg('hello')]);
    final link = _FakeLink();
    await _pump(t, _app(server, link));
    await t.enterText(find.byType(TextField), '  See you Friday  ');
    await t.pump();
    await t.tap(_sendButton());
    await t.pumpAndSettle();
    final post = server.api.calls.lastWhere((c) => c.method == 'POST');
    expect(post.data, {'text': 'See you Friday'});
    link.serve(ChatIncoming(ClubMessage.fromJson(server.stored.last)!));
    await t.pumpAndSettle();
    expect(find.text('See you Friday'), findsOneWidget);
    expect((t.widget(find.byType(TextField)) as TextField).controller!.text, isEmpty);
  });

  testWidgets('a failed send keeps the text and says so', (t) async {
    final server = _Server()..sendError = ApiException(message: 'x', statusCode: 500);
    await _pump(t, _app(server, _FakeLink()));
    await t.enterText(find.byType(TextField), 'Are we on?');
    await t.pump();
    await t.tap(_sendButton());
    await t.pumpAndSettle();
    expect(find.text("Couldn't send. Check your connection and try again."), findsOneWidget);
    expect((t.widget(find.byType(TextField)) as TextField).controller!.text, 'Are we on?');
  });

  testWidgets('live messages and deletions show up; a reconnect fetches what was missed', (t) async {
    final server = _Server(messages: [_msg('before')]);
    final link = _FakeLink();
    await _pump(t, _app(server, link));
    expect(link.joins, 1);

    final live = _msg('live one');
    link.serve(ChatIncoming(ClubMessage.fromJson(live)!));
    await t.pumpAndSettle();
    expect(find.text('live one'), findsOneWidget);

    link.serve(ChatDeleted(live['_id'] as String));
    await t.pumpAndSettle();
    expect(find.text('live one'), findsNothing);

    link.serve(const ChatDisconnected());
    await t.pumpAndSettle();
    expect(find.textContaining('Reconnecting'), findsOneWidget);
    server.stored.add(_msg('sent while you were away', minutesAgo: 0));
    link.serve(const ChatConnected());
    await t.pumpAndSettle();
    expect(link.joins, 2);
    expect(find.textContaining('Reconnecting'), findsNothing);
    expect(find.text('sent while you were away'), findsOneWidget);
    expect(find.text('before'), findsOneWidget);
  });

  testWidgets('I can delete my own message; not someone else\'s', (t) async {
    final mine = _msg('oops', user: _me, name: 'me_myself');
    final server = _Server(messages: [_msg('not mine'), mine]);
    await _pump(t, _app(server, _FakeLink()));

    await t.longPress(find.text('not mine'));
    await t.pumpAndSettle();
    expect(find.text('Delete this message?'), findsNothing);

    await t.longPress(find.text('oops'));
    await t.pumpAndSettle();
    expect(find.text('Delete this message?'), findsOneWidget);
    await t.tap(find.widgetWithText(ClButton, 'Delete'));
    await t.pumpAndSettle();
    expect(server.deleted, [mine['_id']]);
    expect(find.text('oops'), findsNothing);
  });

  testWidgets('a club admin can delete anyone\'s message; a failed delete puts it back', (t) async {
    final theirs = _msg('rude');
    final server = _Server(messages: [theirs], admins: [_me])..deleteError = ApiException(message: 'x', statusCode: 500);
    await _pump(t, _app(server, _FakeLink()));
    await t.longPress(find.text('rude'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ClButton, 'Delete'));
    await t.pumpAndSettle();
    expect(find.text('rude'), findsOneWidget);
    expect(find.text("Couldn't delete the message. Try again."), findsOneWidget);
  });

  testWidgets('non-members see why, with no message box and no socket join', (t) async {
    final server = _Server(isMember: false);
    final link = _FakeLink();
    await _pump(t, _app(server, link));
    expect(find.text('Chat is for members'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(link.joins, 0);
  });

  testWidgets('a deleted account shows as such', (t) async {
    final server = _Server(messages: [
      {..._msg('ghost'), 'user': {'_id': null, 'username': null}},
    ]);
    await _pump(t, _app(server, _FakeLink()));
    expect(find.text('Deleted account'), findsOneWidget);
  });

  testWidgets('empty chat invites the first message', (t) async {
    await _pump(t, _app(_Server(), _FakeLink()));
    expect(find.text('No messages yet'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  for (final (w, scale) in [(320.0, 2.0), (390.0, 1.3)]) {
    testWidgets('layout ${w.toInt()} @${scale}x: no overflow, no broken words, no gold', (t) async {
      final server = _Server(messages: [
        _msg('Extraordinarily cinematographic thoughts about cinematography', minutesAgo: 5),
        _msg('Short', user: _me, name: 'me_myself', minutesAgo: 1),
      ]);
      await _pump(t, _app(server, _FakeLink(), size: Size(w, 700), scale: scale), size: Size(w, 700));
      expect(t.takeException(), isNull);
      expectNoBrokenWords(t);
      expect(goldViolations(t), isEmpty);
    });
  }
}
