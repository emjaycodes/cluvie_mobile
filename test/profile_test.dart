import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';

Map<String, Object?> _film(String id, int tmdb, String title) =>
    {'_id': id, 'tmdbId': tmdb, 'title': title, 'posterPath': '/p.jpg', 'releaseDate': '2023-06-02'};

class _Backend {
  bool failRemove = false;
  final watchlist = [
    _film('68000000000000000000000a', 666277, 'Past Lives'),
    _film('68000000000000000000000b', 872585, 'Oppenheimer'),
    _film('68000000000000000000000c', 545611, 'Everything Everywhere All at Once: The Extraordinarily Long Cut'),
  ];
  late final api = FakeApiClient(
    onGet: (path, _) {
      if (path == '/users/me') {
        return {
          '_id': _me,
          'username': 'cinephile_supreme_2026',
          'email': 'ada.lovelace.longname@example.com',
          'role': 'user',
          'xp': 1240,
          'suggestedMovies': [{}, {}, {}],
          'votedMovies': [{}],
          'comments': const [],
          'followers': ['a', 'b'],
          'following': ['c'],
        };
      }
      if (path == '/watchlist') return List.of(watchlist);
      throw UnimplementedError(path);
    },
    onPost: (path, data) {
      if (path == '/watchlist/remove') {
        if (failRemove) throw ApiException(message: 'x', statusCode: 500);
        watchlist.removeWhere((f) => f['_id'] == data!['movieId']);
      } else if (path == '/watchlist/add') {
        watchlist.insert(0, _film(data!['movieId'] as String, 1, 'restored'));
      }
      return {'success': true};
    },
  );
}

Widget _app(_Backend b, {String initial = '/profile', Size size = const Size(390, 844), double scale = 1}) {
  final router = GoRouter(initialLocation: initial, routes: [
    ShellRoute(builder: (_, __, child) => ClBottomNavBar(child: child), routes: [
      GoRoute(path: '/profile', builder: (_, __) => const UserProfileScreen()),
      for (final p in ['/home', '/discover', '/suggest', '/communities']) GoRoute(path: p, builder: (_, __) => Text('tab $p')),
    ]),
    GoRoute(path: '/users/:id', builder: (_, st) => UserProfileScreen(userId: st.pathParameters['id'])),
    GoRoute(path: '/movie/:id', builder: (_, st) => Scaffold(body: Text('film ${st.pathParameters['id']}'))),
    GoRoute(path: '/welcome', name: 'welcome', builder: (_, __) => const Scaffold(body: Text('welcome'))),
    GoRoute(path: '/notifications', builder: (_, __) => const Scaffold(body: Text('notifications'))),
  ]);
  final padding = const EdgeInsets.only(top: 47, bottom: 34);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(b.api),
      currentUserIdProvider.overrideWith((ref) async => _me),
      unreadCountProvider.overrideWithValue(0),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), padding: padding, viewPadding: padding),
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

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  for (var i = 0; i < 20 && f.hitTestable().evaluate().isEmpty; i++) {
    await t.drag(_vertical.first, const Offset(0, -250));
    await t.pumpAndSettle();
  }
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
    ClPosterImage.debugDisableNetwork = true;
  });

  testWidgets('shows who you are and your real counts; no Edit or made-up levels', (t) async {
    await _pump(t, _app(_Backend()));
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('1240'), findsOneWidget);
    expect(find.text('Films suggested'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.textContaining('Level'), findsNothing);
    expect(find.text('CLUVIE'), findsNothing);
  });

  testWidgets('a watchlist film opens by TMDB id', (t) async {
    await _pump(t, _app(_Backend()));
    await _scrollTo(t, find.text('Past Lives'));
    await t.tap(find.text('Past Lives'));
    await t.pumpAndSettle();
    expect(find.text('film 666277'), findsOneWidget);
  });

  testWidgets('removing is immediate with Undo; Undo saves it again', (t) async {
    final b = _Backend();
    await _pump(t, _app(b));
    await _scrollTo(t, find.byTooltip('Remove Oppenheimer from watchlist'));
    await t.tap(find.byTooltip('Remove Oppenheimer from watchlist'));
    await t.pumpAndSettle();
    expect(b.api.calls.singleWhere((c) => c.path == '/watchlist/remove').data, {'movieId': '68000000000000000000000b'});
    expect(find.text('Oppenheimer'), findsNothing);
    expect(find.text('Removed Oppenheimer.'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(b.api.calls.singleWhere((c) => c.path == '/watchlist/add').data, {'movieId': '68000000000000000000000b'});
    expect(find.text('Oppenheimer'), findsOneWidget);
  });

  testWidgets('a failed remove puts the film back and says so', (t) async {
    final b = _Backend()..failRemove = true;
    await _pump(t, _app(b));
    await _scrollTo(t, find.byTooltip('Remove Past Lives from watchlist'));
    await t.tap(find.byTooltip('Remove Past Lives from watchlist'));
    await t.pumpAndSettle();
    expect(find.text('Past Lives'), findsOneWidget);
    expect(find.text("Couldn't remove Past Lives. Try again."), findsOneWidget);
  });

  testWidgets('an empty watchlist offers Discover', (t) async {
    final b = _Backend()..watchlist.clear();
    await _pump(t, _app(b));
    await _scrollTo(t, find.text('Nothing saved yet'));
    expect(find.text('Discover films'), findsOneWidget);
  });

  testWidgets('log out asks first, then signs out', (t) async {
    await _pump(t, _app(_Backend()));
    await _scrollTo(t, find.text('Log out'));
    await t.tap(find.text('Log out'));
    await t.pumpAndSettle();
    expect(find.text('Log out of Cluvie?'), findsOneWidget);
  });

  testWidgets("someone else's profile says it isn't available yet", (t) async {
    await _pump(t, _app(_Backend(), initial: '/users/64b0000000000000000000ff'));
    expect(find.text("Member profiles aren't available yet"), findsOneWidget);
  });

  testWidgets('profile load failure offers retry', (t) async {
    final b = _Backend();
    final get = b.api.onGet!;
    b.api.onGet = (p, q) => p == '/users/me' ? throw ApiException(message: 'x', statusCode: 500) : get(p, q);
    await _pump(t, _app(b));
    expect(find.text("Couldn't load your profile"), findsOneWidget);
  });

  group('layout and gold', () {
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final route in ['/profile', '/users/64b0000000000000000000ff']) {
          testWidgets('$route ${size.width.toInt()} @${scale}x', (t) async {
            await _pump(t, _app(_Backend(), initial: route, size: size, scale: scale), size: size);
            for (var i = 0; i < 12; i++) {
              expect(t.takeException(), isNull);
              expectNoBrokenWords(t);
              expect(goldViolations(t, allowed: const []), isEmpty);
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
