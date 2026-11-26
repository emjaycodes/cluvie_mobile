import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/notifications/data/notifications.dart';
import 'package:cluvie_mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _film = '68000000000000000000000a';
const _poll = '65000000000000000000000b';
const _party = '6a000000000000000000000c';
const _club = '64c00000000000000000000d';

Map<String, Object?> _n(String id, String type, String title, String message, String? link, {bool read = false, int hoursAgo = 1}) => {
      '_id': id,
      'type': type,
      'title': title,
      'message': message,
      'relatedLink': link,
      'isRead': read,
      'createdAt': DateTime.now().subtract(Duration(hours: hoursAgo)).toUtc().toIso8601String(),
    };

class _Backend {
  final items = [
    _n('6e0000000000000000000001', 'VOTE', 'New vote', 'Someone voted for Past Lives', '/movies/$_film'),
    _n('6e0000000000000000000002', 'POLL', 'Poll closed', 'Cinema Sundays picked Perfect Days', '/polls/$_poll'),
    _n('6e0000000000000000000003', 'WATCHPARTY', 'New Watch Party Scheduled',
        'Sunday screening scheduled for 2026-11-30T19:00:00.000Z', '/watchparty/$_party', read: true, hoursAgo: 30),
    _n('6e0000000000000000000004', 'FOLLOW', 'New follower', 'cinephile_supreme_2026 followed you', '/users/someone',
        read: true, hoursAgo: 200),
  ];

  late final api = FakeApiClient(
    onGet: (path, params) {
      if (path == '/notifications') {
        final unreadOnly = params?['isRead'] == 'false';
        final list = [for (final n in items) if (!unreadOnly || n['isRead'] != true) n];
        return {'success': true, 'notifications': list, 'total': list.length};
      }
      if (path == '/movies/$_film') return {'_id': _film, 'tmdbId': 666277, 'title': 'Past Lives'};
      if (path == '/polls/$_poll') return {'success': true, 'data': {'_id': _poll, 'community': _club}};
      throw ApiException(message: 'x', statusCode: 404);
    },
    onPatch: (path, _) {
      final id = RegExp(r'^/notifications/(\w+)/read$').firstMatch(path)!.group(1);
      items.firstWhere((n) => n['_id'] == id)['isRead'] = true;
      return {'success': true};
    },
    onDelete: (path) {
      items.clear();
      return {'success': true};
    },
  );
}

Widget _app(_Backend b, {Size size = const Size(390, 844), double scale = 1}) {
  final router = GoRouter(initialLocation: '/home', routes: [
    GoRoute(path: '/home', builder: (_, __) => const _Bell()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/movie/:id', builder: (_, st) => Scaffold(body: Text('film ${st.pathParameters['id']}'))),
    GoRoute(path: '/communities/:id/vote', builder: (_, st) => Scaffold(body: Text('vote ${st.pathParameters['id']}'))),
    GoRoute(path: '/watch-parties/:id', builder: (_, st) => Scaffold(body: Text('party ${st.pathParameters['id']}'))),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(b.api),
      currentUserIdProvider.overrideWith((ref) async => _me),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), padding: const EdgeInsets.only(top: 47, bottom: 34)),
      child: MaterialApp.router(theme: AppTheme.theme, routerConfig: router),
    ),
  );
}

class _Bell extends ConsumerWidget {
  const _Bell();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Column(children: [
          const SizedBox(height: 80),
          Text('unread ${ref.watch(unreadCountProvider)}'),
          TextButton(onPressed: () => context.push('/notifications'), child: const Text('bell')),
        ]),
      );
}

Future<void> _open(WidgetTester t, _Backend b, {Size size = const Size(390, 844), double scale = 1}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_app(b, size: size, scale: scale));
  await t.pumpAndSettle();
  await t.tap(find.text('bell'));
  await t.pumpAndSettle();
}

final _vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);

void main() {
  setUpAll(() async {
    await loadRealFonts();
    ClPosterImage.debugDisableNetwork = true;
  });

  test('raw timestamps in messages read as local dates', () {
    final text = readableDates('Sunday screening scheduled for 2026-11-30T19:00:00.000Z');
    expect(text, isNot(contains('T19')));
    expect(text, startsWith('Sunday screening scheduled for '));
    expect(text, contains(' at '));
    expect(readableDates('No dates here'), 'No dates here');
  });

  group('links', () {
    test('backend links map to app screens; unknown ones are not tappable', () {
      expect((targetFor('/watchparty/$_party') as DirectTarget).route, '/watch-parties/$_party');
      expect((targetFor('/movies/$_film') as FilmTarget).catalogId, _film);
      expect((targetFor('/polls/$_poll') as PollTarget).pollId, _poll);
      expect(targetFor('/users/$_me', me: _me), isA<DirectTarget>());
      expect(targetFor('/users/$_film', me: _me), isNull); // others' profiles: no screen yet
      expect(targetFor('/communities/demo-community/vote'), isNull);
      expect(targetFor(null), isNull);
      expect(targetFor('https://example.com'), isNull);
    });
  });

  testWidgets('the bell counts unread; New and Earlier; no gold', (t) async {
    final b = _Backend();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_app(b));
    await t.pumpAndSettle();
    expect(find.text('unread 2'), findsOneWidget);
    await t.tap(find.text('bell'));
    await t.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(goldViolations(t, allowed: const []), isEmpty);
  });

  testWidgets('tapping a film notification marks it read and opens the film by TMDB id', (t) async {
    final b = _Backend();
    await _open(t, b);
    await t.tap(find.text('New vote'));
    await t.pumpAndSettle();
    expect(b.api.calls.where((c) => c.method == 'PATCH').single.path, '/notifications/6e0000000000000000000001/read');
    expect(find.text('film 666277'), findsOneWidget);
    t.state<NavigatorState>(find.byType(Navigator).last).pop();
    await t.pumpAndSettle();
    expect(find.text('New vote'), findsOneWidget);
    expect(b.items.first['isRead'], isTrue);
  });

  testWidgets("a poll opens its club's vote; a party opens the party", (t) async {
    final b = _Backend();
    await _open(t, b);
    await t.tap(find.text('Poll closed'));
    await t.pumpAndSettle();
    expect(find.text('vote $_club'), findsOneWidget);
    t.state<NavigatorState>(find.byType(Navigator).last).pop();
    await t.pumpAndSettle();
    await t.tap(find.text('New Watch Party Scheduled'));
    await t.pumpAndSettle();
    expect(find.text('party $_party'), findsOneWidget);
  });

  testWidgets("a read notification with no screen isn't tappable", (t) async {
    final b = _Backend();
    await _open(t, b);
    await t.drag(_vertical.first, const Offset(0, -600));
    await t.pumpAndSettle();
    expect(find.ancestor(of: find.text('New follower'), matching: find.byType(ClPressable)), findsNothing);
  });

  testWidgets('Clear all asks first, then empties the list', (t) async {
    final b = _Backend();
    await _open(t, b);
    await t.tap(find.byTooltip('Clear all'));
    await t.pumpAndSettle();
    expect(b.api.calls.where((c) => c.method == 'DELETE'), isEmpty);
    await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Clear all')));
    await t.pumpAndSettle();
    expect(b.api.calls.where((c) => c.path == '/notifications/clear'), hasLength(1));
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.byTooltip('Clear all'), findsNothing);
  });

  testWidgets('a load failure offers retry', (t) async {
    final b = _Backend();
    b.api.onGet = (_, __) => throw ApiException(message: 'x', statusCode: 500);
    await _open(t, b);
    expect(find.text("Couldn't load notifications"), findsOneWidget);
  });

  group('layout', () {
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        testWidgets('${size.width.toInt()} @${scale}x', (t) async {
          await _open(t, _Backend(), size: size, scale: scale);
          for (var i = 0; i < 8; i++) {
            expect(t.takeException(), isNull);
            expectNoBrokenWords(t);
            await t.drag(_vertical.first, const Offset(0, -300));
            await t.pumpAndSettle();
          }
        });
      }
    }
  });
}
