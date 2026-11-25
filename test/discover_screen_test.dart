import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/discover/presentation/discover_screen.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

Map<String, Object?> _film(int? id, String title, {String? date = '2023-05-01', String? poster = '/p.jpg'}) => {
  'id': id,
  'title': title,
  'poster_path': poster,
  'release_date': date,
};

final _trending = [_film(11, 'Aftersun'), _film(12, 'Anatomy of a Fall'), _film(13, 'Perfect Days')];
final _popular = [for (var i = 0; i < 7; i++) _film(100 + i, 'Popular film ${i + 1}')];

FakeApiClient _api({FutureOr<Object?> Function(String q)? search, bool failFeed = false}) => FakeApiClient(
  onGet: (path, params) {
    if (path == '/tmdb/search') return (search ?? (q) => {'success': true, 'data': []})(params!['query'] as String);
    if (failFeed) throw Exception('offline');
    if (path == '/movies/trending') return {'success': true, 'data': _trending};
    if (path == '/movies/list') return _popular; // bare list, as the backend sends it
    throw UnimplementedError(path);
  },
);

final _clubs = [fakeClub('c1', 'Cinema Sundays'), fakeClub('c2', 'Night Owls', members: 12, description: 'Late films')];

Widget _app(
  FakeApiClient api, {
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  FutureOr<List<Community>> Function()? all,
  FutureOr<List<Community>> Function()? joined,
  int unread = 0,
}) {
  final router = GoRouter(initialLocation: '/discover', routes: [
    ShellRoute(builder: (_, __, child) => ClBottomNavBar(child: child), routes: [
      GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
      for (final p in ['/home', '/suggest', '/profile']) GoRoute(path: p, builder: (_, __) => Text('tab $p')),
      GoRoute(path: '/communities', builder: (_, __) => const Text('tab /communities')),
    ]),
    GoRoute(path: '/movie/:id', builder: (_, st) => Scaffold(body: Text('movie ${st.pathParameters['id']}'))),
    GoRoute(path: '/communities/:id', builder: (_, st) => Scaffold(body: Text('club ${st.pathParameters['id']}'))),
    GoRoute(path: '/notifications', builder: (_, __) => const Scaffold(body: Text('notifications'))),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      homeFeedProvider.overrideWith((ref) async => demoHomeFeed),
      unreadCountProvider.overrideWithValue(unread),
      allCommunitiesProvider.overrideWith(() => FakeAllCommunities(all ?? () => _clubs)),
      joinedCommunitiesProvider.overrideWith(() => FakeJoinedCommunities(joined ?? () => [_clubs.first])),
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

Future<void> _type(WidgetTester t, String text) async {
  await t.enterText(find.byType(TextField), text);
  await t.pump(const Duration(milliseconds: 300));
  await t.pumpAndSettle();
}

Finder _tile(String title) => find.ancestor(of: find.text(title), matching: find.byType(ClPressable)).first;

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
    await t.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    ClPosterImage.debugDisableNetwork = true;
    await loadRealFonts();
  });

  group('Browse', () {
    testWidgets('trending and every popular film come from the API', (t) async {
      final api = _api();
      await _pump(t, _app(api));
      expect(api.calls.map((c) => c.path), containsAll(['/movies/trending', '/movies/list']));
      expect(find.text('Aftersun'), findsOneWidget);
      await _scrollTo(t, find.text('Popular film 7'));
      expect(find.text('Popular film 7'), findsOneWidget, reason: 'popular grid is capped');
    });

    testWidgets('when TMDB trending is down, club films still show', (t) async {
      final api = FakeApiClient(onGet: (path, _) {
        if (path == '/movies/trending') throw Exception('TMDB unavailable');
        return _popular;
      });
      await _pump(t, _app(api));
      expect(find.text("Couldn't load Discover — tap to retry"), findsNothing);
      expect(find.text('Trending now'), findsNothing);
      expect(find.text('Popular in clubs'), findsOneWidget);
    });

    testWidgets('a failure shows one retry card and no demo films; tapping it reloads', (t) async {
      var fail = true;
      final api = FakeApiClient(onGet: (path, _) {
        if (fail) throw Exception('offline');
        return path == '/movies/trending' ? {'success': true, 'data': _trending} : _popular;
      });
      await _pump(t, _app(api));
      expect(find.text("Couldn't load Discover — tap to retry"), findsOneWidget);
      for (final demo in ['Dune: Part Two', 'The Batman', 'Blade Runner 2049']) {
        expect(find.text(demo), findsNothing);
      }
      expect(find.textContaining('cached'), findsNothing);
      fail = false;
      await t.tap(find.ancestor(of: find.text("Couldn't load Discover — tap to retry"), matching: find.byType(ClPressable)));
      await t.pumpAndSettle();
      expect(find.text('Aftersun'), findsOneWidget);
    });

    testWidgets('the search field stays usable while browse content loads', (t) async {
      final hold = Completer<Object?>();
      final api = FakeApiClient(onGet: (path, _) => path == '/tmdb/search' ? {'success': true, 'data': []} : hold.future);
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(api));
      await t.pump();
      expect(find.byType(ClSearchField), findsOneWidget);
      expect(find.bySemanticsLabel('Loading films'), findsOneWidget);
      hold.complete({'success': true, 'data': []});
      await t.pumpAndSettle();
    });

    testWidgets('tapping a film opens it; a film with no id is not a button', (t) async {
      final api = _api(search: (_) => {'success': true, 'data': [_film(null, 'No Id Film'), _film(77, 'Has Id Film')]});
      await _pump(t, _app(api));
      await _type(t, 'film');
      final noId = t.widget<ClPressable>(_tile('No Id Film'));
      expect(noId.onTap, isNull);
      await t.tap(_tile('Has Id Film'));
      await t.pumpAndSettle();
      expect(find.text('movie 77'), findsOneWidget);
    });

    testWidgets('a film with no date shows no year (none is invented)', (t) async {
      final api = _api(search: (_) => {'success': true, 'data': [_film(5, 'Undated', date: null, poster: null)]});
      await _pump(t, _app(api));
      await _type(t, 'undated');
      expect(find.text('Undated'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d{4}$')), findsNothing);
    });

    testWidgets('the bell follows the shared unread count, with no made-up badge', (t) async {
      await _pump(t, _app(_api(), unread: 2));
      expect(find.byTooltip('Notifications, 2 unread'), findsOneWidget);
      await _pump(t, _app(_api()));
      expect(find.byTooltip('Notifications'), findsOneWidget, reason: 'badge without unread notifications');
    });

    testWidgets('a failed refresh keeps the films and says so', (t) async {
      var fail = false;
      final api = FakeApiClient(onGet: (path, _) {
        if (fail) throw Exception('offline');
        return path == '/movies/trending' ? {'success': true, 'data': _trending} : _popular;
      });
      await _pump(t, _app(api));
      fail = true;
      await t.fling(find.byType(CustomScrollView), const Offset(0, 500), 1500);
      await t.pumpAndSettle();
      expect(find.text('Aftersun'), findsOneWidget);
      expect(find.textContaining("Couldn't refresh"), findsOneWidget);
    });

    testWidgets('the search field uses the input tokens: borderInput at rest, 2px focus ring', (t) async {
      await _pump(t, _app(_api()));
      final deco = t.widget<TextField>(find.byType(TextField)).decoration!;
      expect((deco.enabledBorder! as OutlineInputBorder).borderSide.color, AppColors.borderInput);
      final focused = (deco.focusedBorder! as OutlineInputBorder).borderSide;
      expect(focused.color, AppColors.focusRing);
      expect(focused.width, 2);
    });
  });

  group('Search', () {
    testWidgets('debounced 300 ms, then searches the API and shows results', (t) async {
      final api = _api(search: (q) => {'success': true, 'data': [_film(21, 'Arrival')]});
      await _pump(t, _app(api));
      await t.enterText(find.byType(TextField), 'arr');
      await t.pump(const Duration(milliseconds: 250));
      expect(api.calls.where((c) => c.path == '/tmdb/search'), isEmpty, reason: 'searched before the debounce');
      await t.pump(const Duration(milliseconds: 60));
      await t.pumpAndSettle();
      final search = api.calls.where((c) => c.path == '/tmdb/search').toList();
      expect(search, hasLength(1));
      expect(search.single.params, {'query': 'arr'});
      expect(find.text("Results for 'arr'"), findsOneWidget);
      expect(find.text('Arrival'), findsOneWidget);
    });

    testWidgets('one letter shows the minimum-length hint and does not search', (t) async {
      final api = _api();
      await _pump(t, _app(api));
      await _type(t, 'a');
      expect(find.textContaining('search starts at 2 letters'), findsOneWidget);
      expect(api.calls.where((c) => c.path == '/tmdb/search'), isEmpty);
    });

    testWidgets('no results shows the contract copy', (t) async {
      await _pump(t, _app(_api()));
      await _type(t, 'zzzz');
      expect(find.text("No results for 'zzzz' — try another title"), findsOneWidget);
    });

    testWidgets('a failed search shows an error with retry, not demo films', (t) async {
      var fail = true;
      final api = _api(search: (q) {
        if (fail) throw Exception('offline');
        return {'success': true, 'data': [_film(31, 'Retried Film')]};
      });
      await _pump(t, _app(api));
      await _type(t, 'dune');
      expect(find.text("Search didn't go through"), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsNothing);
      fail = false;
      await t.tap(find.ancestor(of: find.text('Try again'), matching: find.byType(ClPressable)));
      await t.pumpAndSettle();
      expect(find.text('Retried Film'), findsOneWidget);
    });

    testWidgets('while a search retry is in flight the skeleton replaces the error', (t) async {
      var calls = 0;
      final hold = Completer<Object?>();
      final api = _api(search: (q) {
        calls++;
        if (calls == 1) throw Exception('offline');
        return hold.future;
      });
      await _pump(t, _app(api));
      await _type(t, 'dune');
      await t.tap(find.ancestor(of: find.text('Try again'), matching: find.byType(ClPressable)));
      await t.pump();
      await t.pump();
      expect(find.text("Search didn't go through"), findsNothing);
      expect(find.bySemanticsLabel('Loading films'), findsOneWidget);
      hold.complete({'success': true, 'data': [_film(1, 'Dune')]});
      await t.pumpAndSettle();
      expect(find.text('Dune'), findsOneWidget);
    });

    testWidgets('clearing the search returns to browse', (t) async {
      await _pump(t, _app(_api(search: (_) => {'success': true, 'data': [_film(21, 'Arrival')]})));
      await _type(t, 'arr');
      await t.tap(find.byTooltip('Clear search'));
      await t.pumpAndSettle();
      expect(find.text("Results for 'arr'"), findsNothing);
      expect(find.text('Aftersun'), findsOneWidget);
    });

    testWidgets('the search survives switching tabs', (t) async {
      final api = _api(search: (_) => {'success': true, 'data': [_film(21, 'Arrival')]});
      await _pump(t, _app(api));
      await _type(t, 'arr');
      await t.tap(find.bySemanticsLabel('Home'));
      await t.pumpAndSettle();
      expect(find.text('tab /home'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Discover'));
      await t.pumpAndSettle();
      expect(find.text('arr'), findsOneWidget, reason: 'search text lost');
      expect(find.text('Arrival'), findsOneWidget);
      expect(api.calls.where((c) => c.path == '/movies/trending'), hasLength(1), reason: 'browse refetched on tab switch');
    });
  });

  group('Clubs to join', () {
    testWidgets('lists real clubs the user is not in; a card opens the club', (t) async {
      await _pump(t, _app(_api()));
      await _scrollTo(t, find.text('Night Owls'));
      expect(find.text('Cinema Sundays'), findsNothing, reason: 'already joined');
      expect(find.text('12 members'), findsOneWidget);
      expect(find.text('Join Club'), findsNothing, reason: 'no fake join button');
      await t.tap(find.ancestor(of: find.text('Night Owls'), matching: find.byType(ClPressable)).first);
      await t.pumpAndSettle();
      expect(find.text('club c2'), findsOneWidget);
    });

    testWidgets('hidden when the club API fails', (t) async {
      await _pump(t, _app(_api(), all: () => throw Exception('offline')));
      await t.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(find.text('Clubs to join'), findsNothing);
    });
  });

  group('Layout and gold budget', () {
    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} @${scale}x: no overflow, broken words or gold', (t) async {
          final padding = EdgeInsets.only(top: size.height > 800 ? 47 : 20, bottom: 34);
          await _pump(t, _app(_api(), size: size, scale: scale, padding: padding), size: size);
          for (var i = 0; i < 12; i++) {
            expect(t.takeException(), isNull);
            expectNoBrokenWords(t);
            expect(goldViolations(t), isEmpty);
            await t.drag(find.byType(CustomScrollView), const Offset(0, -350));
            await t.pumpAndSettle();
          }
          expect(find.text('Night Owls'), findsOneWidget, reason: 'did not reach the end');
          expect(t.takeException(), isNull);
        });

        testWidgets('${size.width.toInt()}x${size.height.toInt()} @${scale}x: hint, no-results, search-error and feed-error states fit', (t) async {
          final padding = EdgeInsets.only(top: size.height > 800 ? 47 : 20, bottom: 34);
          Future<void> check() async {
            expect(t.takeException(), isNull);
            expectNoBrokenWords(t);
            expectNotTruncated(t, ["Couldn't load Discover — tap to retry"]);
          }

          await _pump(t, _app(_api(search: (q) => q == 'boom' ? throw Exception('x') : {'success': true, 'data': []}), size: size, scale: scale, padding: padding), size: size);
          // The hint is the field's only visible name: whole while empty.
          expectNotTruncated(t, ['Search films']);
          await _type(t, 'a');
          await check();
          await _type(t, 'zzzz');
          await check();
          await _type(t, 'boom');
          await check();
          // A fresh ProviderScope (same-position scopes keep their container).
          await t.pumpWidget(const SizedBox());
          await _pump(t, _app(_api(failFeed: true), size: size, scale: scale, padding: padding), size: size);
          expect(find.text("Couldn't load Discover — tap to retry"), findsOneWidget);
          await check();
        });
      }
    }
  });
}
