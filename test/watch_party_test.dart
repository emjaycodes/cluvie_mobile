import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/watch_party/data/party_room.dart';
import 'package:cluvie_mobile/features/watch_party/data/watch_parties.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_detail_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_room_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_list_screen.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/watch_party_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _club = '64c000000000000000000001';
const _otherClub = '64c000000000000000000002';
const _going = '6a0000000000000000000001'; // I'm going
const _open = '6a0000000000000000000002'; // not going, my club
const _hosting = '6a0000000000000000000003'; // I host
const _ended = '6a0000000000000000000004';
const _foreign = '6a0000000000000000000005'; // a club I'm not in
const _stale = '6a0000000000000000000006'; // scheduled 21 days ago, never started

Map<String, Object?> _party(String id, String title, {
  String host = 'h1',
  List<String> participants = const [],
  String status = 'scheduled',
  Duration from = const Duration(days: 1),
  String club = _club,
  String clubName = 'Cinema Sundays',
  String? description,
}) =>
    {
      '_id': id,
      'title': title,
      'description': description,
      'scheduledAt': DateTime.now().add(from).toUtc().toIso8601String(),
      'status': status,
      'host': {'_id': host, 'username': host == _me ? 'me_myself' : 'carmen'},
      'participants': [
        {'_id': host, 'username': host == _me ? 'me_myself' : 'carmen'},
        for (final p in participants) {'_id': p, 'username': p == _me ? 'me_myself' : 'guest_$p'},
      ],
      'movie': {'_id': 'm$id', 'tmdbId': 1, 'title': 'Past Lives', 'posterPath': '/p.jpg'},
      'community': {'_id': club, 'name': clubName},
      'isPrivate': false,
    };

class _Backend {
  late final parties = <String, Map<String, Object?>>{
    _going: _party(_going, 'Sunday screening', participants: [_me, 'u2'], description: 'Bring snacks. We start on time.'),
    _open: _party(_open, 'Friday double bill of extraordinarily long-named masterpieces', from: const Duration(hours: 3)),
    _hosting: _party(_hosting, 'My party', host: _me, participants: ['u3']),
    _ended: _party(_ended, 'Last month', status: 'ended', from: const Duration(days: -20)),
    _foreign: _party(_foreign, 'Noir night', club: _otherClub, clubName: 'Noir Nights'),
    _stale: _party(_stale, 'Forgotten one', from: const Duration(days: -21)),
  };
  bool failRefetch = false;
  int b0 = 0; // party GETs so far

  late final api = FakeApiClient(
    onGet: (path, params) {
      if (path == '/watchparties') return {'success': true, 'data': parties.values.toList()};
      final one = RegExp(r'^/watchparties/(\w+)$').firstMatch(path);
      if (one != null && failRefetch && b0 > 0) throw ApiException(message: 'x', statusCode: 503);
      if (one != null) b0++;
      if (one != null) {
        final p = parties[one.group(1)];
        if (p == null) throw ApiException(message: 'x', statusCode: 404);
        return {'success': true, 'data': p};
      }
      if (path == '/communities/joined') {
        return {'success': true, 'communities': [{'_id': _club, 'name': 'Cinema Sundays', 'description': 'd', 'members': [{'user': _me, 'role': 'member'}]}]};
      }
      if (path.startsWith('/communities/')) throw ApiException(message: 'x', statusCode: 503);
      throw UnimplementedError(path);
    },
    onPost: (path, _) {
      final m = RegExp(r'^/watchparties/(\w+)/(join|leave)$').firstMatch(path)!;
      final p = parties[m.group(1)]!;
      if ((p['community'] as Map)['_id'] == _otherClub) {
        throw ApiException(message: 'x', statusCode: 403, responseBody: {'message': 'You must be a member'});
      }
      final list = p['participants'] as List;
      if (m.group(2) == 'join') {
        list.add({'_id': _me, 'username': 'me_myself'});
      } else {
        list.removeWhere((e) => (e as Map)['_id'] == _me);
      }
      return {'success': true};
    },
    onPatch: (path, data) {
      final id = RegExp(r'^/watchparties/(\w+)/update$').firstMatch(path)!.group(1)!;
      parties[id]!['status'] = data!['status'];
      return {'success': true};
    },
  );
}

/// A room without a server: records what the app sends; the test plays
/// the server's side with [serve].
class _FakeRoom implements RoomLink {
  _FakeRoom({this.joinResult = RoomJoinResult.ok});
  final RoomJoinResult joinResult;
  final _events = StreamController<RoomEvent>.broadcast();
  final sent = <String>[];
  bool closed = false;

  void serve(RoomEvent e) => _events.add(e);

  @override
  Stream<RoomEvent> get events => _events.stream;
  @override
  void connect() => scheduleMicrotask(() => serve(const RoomConnected()));
  @override
  Future<RoomJoinResult> join() async {
    sent.add('join');
    return joinResult;
  }

  @override
  void here() => sent.add('here');
  @override
  void react(String key) => sent.add('react:$key');
  @override
  void close() {
    closed = true;
    sent.add('leave');
  }
}

_FakeRoom? _room;

Widget _app(_Backend b, String initial, {Size size = const Size(390, 844), double scale = 1, Future<String?> Function()? me}) {
  final router = GoRouter(initialLocation: initial, routes: [
    GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: Text('home'))),
    GoRoute(path: '/watch-parties', builder: (_, __) => const WatchPartyListScreen()),
    GoRoute(path: '/watch-parties/:id', builder: (_, st) => WatchPartyDetailScreen(partyId: st.pathParameters['id']!)),
    GoRoute(path: '/watch-parties/:id/live', builder: (_, st) => WatchPartyRoomScreen(partyId: st.pathParameters['id']!)),
    GoRoute(path: '/watchParty', builder: (_, __) => const WatchPartyScreen()),
    GoRoute(path: '/communities/:id', builder: (_, st) => Scaffold(body: Text('club ${st.pathParameters['id']}'))),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(b.api),
      currentUserIdProvider.overrideWith((ref) => (me ?? () async => _me)()),
      roomLinkFactoryProvider.overrideWithValue((_) async => _room ??= _FakeRoom()),
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

final _vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);

Future<void> _tap(WidgetTester t, String label) async {
  final f = find.text(label).last;
  for (var i = 0; i < 20 && f.hitTestable().evaluate().isEmpty; i++) {
    await t.drag(_vertical.first, const Offset(0, -250));
    await t.pumpAndSettle();
  }
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
    ClPosterImage.debugDisableNetwork = true;
  });

  group('list', () {
    testWidgets('coming up soonest first, past apart, with your status', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, '/watch-parties'));
      expect(find.text('Coming up'), findsOneWidget);
      final soon = t.getTopLeft(find.textContaining('Friday double bill')).dy;
      final later = t.getTopLeft(find.text('Sunday screening')).dy;
      expect(soon, lessThan(later));
      expect(find.text('GOING'), findsOneWidget);
      expect(find.text('HOSTING'), findsOneWidget);
      await t.drag(_vertical.first, const Offset(0, -2000));
      await t.pumpAndSettle();
      expect(find.text('Past'), findsOneWidget);
      // 'Last month' (ended) and 'Forgotten one' (scheduled, never started).
      expect(find.text('ENDED'), findsNWidgets(2));
      expect(find.text("I'm going"), findsNothing); // RSVP lives on each party's page
    });

    testWidgets('a tile opens its party', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, '/watch-parties'));
      await _tap(t, 'Sunday screening');
      expect(find.text('Bring snacks. We start on time.'), findsOneWidget);
    });

    testWidgets('empty state', (t) async {
      await _pump(t, _app(_Backend()..parties.clear(), '/watch-parties'));
      expect(find.text('No watch parties yet'), findsOneWidget);
    });

    testWidgets('error state', (t) async {
      final b = _Backend();
      b.api.onGet = (_, __) => throw ApiException(message: 'x', statusCode: 500);
      await _pump(t, _app(b, '/watch-parties'));
      expect(find.text("Couldn't load watch parties"), findsOneWidget);
    });
  });

  group('round 10 regressions', () {
    testWidgets('R10-S2: a scheduled party long past its start is over: no RSVP, badge Ended', (t) async {
      await _pump(t, _app(_Backend(), '/watch-parties/$_stale'));
      expect(find.text('This party has ended.'), findsOneWidget);
      expect(find.text("I'm going"), findsNothing);
      expect(find.text('ENDED'), findsOneWidget);
    });

    testWidgets('R10-S3: the list pages past old parties', (t) async {
      final b = _Backend();
      final get = b.api.onGet!;
      b.api.onGet = (path, params) {
        if (path != '/watchparties') return get(path, params);
        final page = params!['page'] as int;
        return {
          'success': true,
          'data': page == 1 ? [b.parties[_ended]] : [b.parties[_open]],
          'totalPages': 2,
        };
      };
      await _pump(t, _app(b, '/watch-parties'));
      expect(find.text('Coming up'), findsOneWidget);
      expect(b.api.calls.where((c) => c.path == '/watchparties'), hasLength(2));
    });

    testWidgets('R10-S4: busy until the party reloads; a failed reload says so', (t) async {
      final b = _Backend()..failRefetch = true;
      await _pump(t, _app(b, '/watch-parties/$_open'));
      await _tap(t, "I'm going");
      expect(find.textContaining("Couldn't refresh the party yet"), findsOneWidget);
      expect(b.api.calls.where((c) => c.path.endsWith('/join')), hasLength(1));
    });

    testWidgets('R10-S5: the tile tells a screen reader the party state', (t) async {
      await _pump(t, _app(_Backend(), '/watch-parties'));
      expect(find.bySemanticsLabel(RegExp(r'^Hosting, My party')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Going, Sunday screening')), findsOneWidget);
    });

    testWidgets('R10-S6: no RSVP while your id is unknown, even on your own party', (t) async {
      await _pump(t, _app(_Backend(), '/watch-parties/$_hosting', me: () async => null));
      expect(find.text("I'm going"), findsNothing);
      expect(find.text("Couldn't check your RSVP"), findsOneWidget);
    });

    testWidgets('R10-N4: a 403 on cancel is "only the host", not "join the club"', (t) async {
      final b = _Backend();
      b.api.onPatch = (_, __) => throw ApiException(message: 'x', statusCode: 403, responseBody: {'message': 'Only host can update watch party'});
      await _pump(t, _app(b, '/watch-parties/$_hosting'));
      await _tap(t, 'Cancel party');
      await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel party')));
      await t.pumpAndSettle();
      expect(find.text('Only the host can change this party.'), findsOneWidget);
      expect(find.textContaining('can RSVP'), findsNothing);
    });

    testWidgets('R10-N4: an unexpected 400 is a failure, not "you\'re going"', (t) async {
      final b = _Backend();
      b.api.onPost = (_, __) => throw ApiException(message: 'x', statusCode: 400, responseBody: {'message': 'Cast to ObjectId failed'});
      await _pump(t, _app(b, '/watch-parties/$_open'));
      await _tap(t, "I'm going");
      expect(find.text("Couldn't update the party. Try again."), findsOneWidget);
    });
  });

  group('detail', () {
    testWidgets("I'm going, then Can't make it: each its own request", (t) async {
      final b = _Backend();
      await _pump(t, _app(b, '/watch-parties/$_open'));
      await _tap(t, "I'm going");
      expect(b.api.calls.where((c) => c.path == '/watchparties/$_open/join'), hasLength(1));
      expect(find.text("Can't make it"), findsOneWidget);
      expect(find.text('2 going'), findsOneWidget);
      await _tap(t, "Can't make it");
      expect(b.api.calls.where((c) => c.path == '/watchparties/$_open/leave'), hasLength(1));
      expect(find.text("I'm going"), findsOneWidget);
    });

    testWidgets('a known non-member sees the club prompt instead of RSVP', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, '/watch-parties/$_foreign'));
      expect(find.text('Only members of Noir Nights can RSVP.'), findsOneWidget);
      expect(find.text("I'm going"), findsNothing);
      expect(b.api.calls.where((c) => c.method == 'POST'), isEmpty);
    });

    testWidgets('when membership is unknown, a 403 turns into the club prompt', (t) async {
      final b = _Backend();
      final get = b.api.onGet!;
      b.api.onGet = (path, params) {
        if (path == '/communities/joined') throw ApiException(message: 'x', statusCode: 503);
        return get(path, params);
      };
      await _pump(t, _app(b, '/watch-parties/$_foreign'));
      await _tap(t, "I'm going");
      expect(find.text('Only members of Noir Nights can RSVP.'), findsOneWidget);
      expect(find.text("I'm going"), findsNothing);
      await _tap(t, 'Open club');
      expect(find.text('club $_otherClub'), findsOneWidget);
    });

    testWidgets('the host cancels after confirming', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, '/watch-parties/$_hosting'));
      expect(find.text("You're hosting this party."), findsOneWidget);
      await _tap(t, 'Cancel party');
      expect(b.api.calls.where((c) => c.method == 'PATCH'), isEmpty);
      await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel party')));
      await t.pumpAndSettle();
      expect(b.api.calls.singleWhere((c) => c.method == 'PATCH').data, {'status': 'cancelled'});
      expect(find.text('This party was cancelled.'), findsOneWidget);
    });

    testWidgets('an ended party has no RSVP', (t) async {
      await _pump(t, _app(_Backend(), '/watch-parties/$_ended'));
      expect(find.text('This party has ended.'), findsOneWidget);
      expect(find.text("I'm going"), findsNothing);
    });

    testWidgets('a demo id is not found, without a request', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, '/watch-parties/demo-party'));
      expect(find.text("This watch party doesn't exist"), findsOneWidget);
      expect(b.api.calls.where((c) => c.path.contains('demo')), isEmpty);
    });

    testWidgets('the old room link without a party points to the list', (t) async {
      await _pump(t, _app(_Backend(), '/watchParty'));
      expect(find.text('Pick a watch party'), findsOneWidget);
      await _tap(t, 'See watch parties');
      expect(find.byType(WatchPartyListScreen), findsOneWidget);
    });
  });

  group('live room', () {
    setUp(() => _room = null);

    testWidgets('the host enters from the party page, joins, and starts the party', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, '/watch-parties/$_hosting'));
      await _tap(t, 'Enter live room');
      expect(_room!.sent, ['join']);
      expect(find.text('In the room (1)'), findsOneWidget);
      await _tap(t, 'Start the party');
      expect(b.api.calls.singleWhere((c) => c.method == 'PATCH').data, {'status': 'live'});
      expect(find.text('End party'), findsOneWidget);
    });

    testWidgets('presence: newcomers are greeted, leavers drop off; reactions show with names', (t) async {
      await _pump(t, _app(_Backend(), '/watch-parties/$_going/live'));
      _room!.serve(const RoomPresence('u2', 'joined'));
      await t.pumpAndSettle();
      expect(_room!.sent, contains('here'));
      expect(find.text('In the room (2)'), findsOneWidget);
      expect(find.text('guest_u2'), findsOneWidget);
      _room!.serve(const RoomPresence('u9', 'here'));
      await t.pumpAndSettle();
      expect(find.text('In the room (3)'), findsOneWidget);
      expect(find.text('A club member'), findsOneWidget);
      _room!.serve(const RoomPresence('u2', 'react:popcorn'));
      await t.pumpAndSettle();
      expect(find.text('🍿  guest_u2'), findsOneWidget);
      _room!.serve(const RoomPresence('u2', 'left'));
      await t.pumpAndSettle();
      expect(find.text('In the room (2)'), findsOneWidget);
      // Someone reconnecting (still listed here) is greeted again.
      _room!.serve(const RoomPresence('u9', 'joined'));
      await t.pumpAndSettle();
      expect(_room!.sent.where((s) => s == 'here'), hasLength(2));
      await _tap(t, '👏');
      expect(_room!.sent, contains('react:clap'));
      expect(find.text('👏  You'), findsOneWidget);
    });

    testWidgets('reconnecting is shown, then the room is joined again', (t) async {
      await _pump(t, _app(_Backend(), '/watch-parties/$_going/live'));
      _room!.serve(const RoomDisconnected());
      await t.pump();
      await t.pump();
      expect(find.text('Connection lost. Reconnecting…'), findsOneWidget);
      _room!.serve(const RoomConnected());
      await t.pumpAndSettle();
      expect(_room!.sent.where((s) => s == 'join'), hasLength(2));
      expect(find.text('Connection lost. Reconnecting…'), findsNothing);
    });

    testWidgets('a refused room asks you to join the club', (t) async {
      _room = _FakeRoom(joinResult: RoomJoinResult.forbidden);
      await _pump(t, _app(_Backend(), '/watch-parties/$_foreign/live'));
      expect(find.text('Only club members can come in'), findsOneWidget);
    });

    testWidgets('a deleted party says so; leaving the screen leaves the room', (t) async {
      await _pump(t, _app(_Backend(), '/watch-parties/$_going/live'));
      _room!.serve(const RoomPartyDeleted());
      await t.pumpAndSettle();
      expect(find.text('This party was deleted'), findsOneWidget);
      await _tap(t, 'See watch parties');
      expect(_room!.closed, isTrue);
    });

    test('the room opens 30 minutes before for guests, any time for the host', () {
      WatchParty party({required Duration from, String host = 'h1', String status = 'scheduled'}) =>
          WatchParty.fromJson(_party('6a00000000000000000000ff', 'p', host: host, participants: [_me], from: from, status: status))!;
      expect(canEnterRoom(party(from: const Duration(minutes: 20)), _me), isTrue);
      expect(canEnterRoom(party(from: const Duration(hours: 2)), _me), isFalse);
      expect(canEnterRoom(party(from: const Duration(hours: 2), status: 'live'), _me), isTrue);
      expect(canEnterRoom(party(from: const Duration(days: 3), host: _me), _me), isTrue);
      expect(canEnterRoom(party(from: const Duration(minutes: 5), status: 'ended'), _me), isFalse);
      expect(canEnterRoom(party(from: const Duration(minutes: 5)), 'stranger'), isFalse);
    });
  });

  group('layout and gold budget', () {
    final screens = <String, (String, List<String>)>{
      'list': ('/watch-parties', const []),
      'detail (open)': ('/watch-parties/$_open', const ["I'm going"]),
      'detail (going)': ('/watch-parties/$_going', const []),
      'detail (hosting)': ('/watch-parties/$_hosting', const ['Enter live room']),
      'room (host, scheduled)': ('/watch-parties/$_hosting/live', const ['Start the party']),
      'room (guest)': ('/watch-parties/$_going/live', const []),
      'detail (ended)': ('/watch-parties/$_ended', const []),
      'room': ('/watchParty', const []),
    };
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final MapEntry(key: name, value: (route, gold)) in screens.entries) {
          testWidgets('$name ${size.width.toInt()} @${scale}x', (t) async {
            await _pump(t, _app(_Backend(), route, size: size, scale: scale), size: size);
            final allowed = [for (final g in gold) find.ancestor(of: find.text(g), matching: find.byType(ClButton))];
            for (var i = 0; i < 10; i++) {
              expect(t.takeException(), isNull);
              expectNoBrokenWords(t);
              expect(goldViolations(t, allowed: allowed), isEmpty);
              if (_vertical.evaluate().isEmpty) break;
              await t.drag(_vertical.first, const Offset(0, -300));
              await t.pumpAndSettle();
            }
          });
        }
      }
    }
  });
}
