import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/models/community.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/suggest/presentation/suggestion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cluvie_mobile/core/router/routes.dart' as app_routes;

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

// `/tmdb/search` passes TMDB's items through.
Map<String, Object?> _film(int id, String title) =>
    {'id': id, 'title': title, 'poster_path': '/p.jpg', 'release_date': '2023-01-01'};

// `/movies/trending` maps them to its own shape.
Map<String, Object?> _trend(int id, String title) =>
    {'tmdbId': id, 'title': title, 'poster': '/p.jpg', 'releaseDate': '2023-01-01', 'popularity': 9.1};

final _trending = [_trend(11, 'Aftersun'), _trend(12, 'Anatomy of a Fall'), _trend(13, 'Perfect Days')];
const _longClub = 'The Extremely Long Named Midnight Cinema Appreciation Society of Lagos';
final _clubs = [
  fakeClub('c1', 'Cinema Sundays', members: 8),
  fakeClub('c2', 'Night Owls', members: 12),
  fakeClub('c3', _longClub, members: 40),
];

FakeApiClient _api({FutureOr<Object?> Function(String path, Map<String, dynamic>? data)? onPost, bool failSearch = false}) =>
    FakeApiClient(
      onGet: (path, params) {
        if (path == '/tmdb/search') {
          if (failSearch) throw Exception('offline');
          final q = params!['query'] as String;
          return {'success': true, 'data': q == 'zzzz' ? [] : [_film(21, 'Arrival')]};
        }
        if (path == '/movies/list') return <Object>[];
        return {'success': true, 'data': _trending};
      },
      onPost: onPost ?? (_, __) => {'ok': true},
    );

Widget _app(
  FakeApiClient api, {
  String initial = '/suggest',
  FutureOr<List<Community>> Function()? joined,
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  final router = GoRouter(initialLocation: initial, routes: [
    ShellRoute(builder: (_, __, child) => ClBottomNavBar(child: child), routes: [
      GoRoute(path: '/suggest', builder: (_, __) => const SuggestMovieScreen()),
      for (final p in ['/home', '/discover', '/profile', '/communities']) GoRoute(path: p, builder: (_, __) => Text('tab $p')),
    ]),
    GoRoute(path: '/communities/:id', builder: (_, st) => Scaffold(body: Text('club ${st.pathParameters['id']}')), routes: [
      GoRoute(path: 'suggest', builder: (_, st) => SuggestMovieScreen(communityId: st.pathParameters['id'])),
    ]),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      homeFeedProvider.overrideWith((ref) async => const HomeFeed()),
      joinedCommunitiesProvider.overrideWith(() => FakeJoinedCommunities(joined ?? () => _clubs)),
      allCommunitiesProvider.overrideWith(() => FakeAllCommunities(() => [..._clubs, fakeClub('zz', 'Horror Hounds')])),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(scale),
        padding: padding,
        viewPadding: padding,
        viewInsets: viewInsets,
      ),
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

Finder _pressable(Finder label) => find.ancestor(of: label, matching: find.byType(ClPressable)).first;

Future<void> _openSheet(WidgetTester t, String film) async {
  final scroller = find.byType(Scrollable).first;
  await t.scrollUntilVisible(find.text(film), 200, scrollable: scroller);
  await t.pumpAndSettle();
  // Keep it clear of the pinned app bar.
  final top = t.getRect(_pressable(find.text(film))).top;
  final clear = t.view.padding.top / t.view.devicePixelRatio + 140;
  if (top < clear) {
    await t.drag(scroller, Offset(0, clear - top));
    await t.pumpAndSettle();
  }
  await t.tap(_pressable(find.text(film)));
  await t.pumpAndSettle();
}

/// Taps a control inside the sheet, scrolling the sheet to it first.
Future<void> _tapInSheet(WidgetTester t, Finder label) async {
  await t.ensureVisible(label.first);
  await t.pumpAndSettle();
  await t.tap(_pressable(label));
  await t.pumpAndSettle();
}

/// The sheet's submit, found by what it says to a screen reader.
Finder _submitFor(String film, String club) => find.bySemanticsLabel('Suggest $film to $club');

Finder get _submit => find.descendant(of: find.byType(BottomSheet), matching: find.byType(ClButton));

void main() {
  setUpAll(() async {
    ClPosterImage.debugDisableNetwork = true;
    await loadRealFonts();
  });

  testWidgets('trending films come from the API (no demo list)', (t) async {
    final api = _api();
    await _pump(t, _app(api));
    expect(api.calls.map((c) => c.path), contains('/movies/trending'));
    expect(find.text('Aftersun'), findsOneWidget);
    expect(find.text('Dune: Part Two'), findsNothing);
  });

  testWidgets('suggests the film to the club the user picked, with the note', (t) async {
    final api = _api();
    await _pump(t, _app(api));
    await _openSheet(t, 'Anatomy of a Fall');
    expect(find.text('Suggest to'), findsOneWidget);
    expect(find.text('Pick a club'), findsOneWidget, reason: 'nothing preselected with two clubs');
    await _tapInSheet(t, find.text('Night Owls'));
    await t.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'Watch it twice');
    expect(_submitFor('Anatomy of a Fall', 'Night Owls'), findsOneWidget);
    await _tapInSheet(t, find.text('Suggest'));

    final post = api.calls.singleWhere((c) => c.method == 'POST');
    expect(post.path, '/communities/c2/suggest');
    expect(post.data, {'tmdbId': 12, 'note': 'Watch it twice'});
    expect(find.byType(BottomSheet), findsNothing, reason: 'sheet stays open after success');
    expect(find.text('Suggested Anatomy of a Fall to Night Owls.'), findsOneWidget);
    expect(find.textContaining('XP'), findsNothing);
  });

  testWidgets('a failed submit keeps the sheet open and Try again resubmits', (t) async {
    var fail = true;
    final api = _api(onPost: (_, __) {
      if (fail) throw Exception('offline');
      return {'ok': true};
    });
    await _pump(t, _app(api, joined: () => [_clubs.first]));
    await _openSheet(t, 'Aftersun');
    // One club: preselected.
    expect(_submitFor('Aftersun', 'Cinema Sundays'), findsOneWidget);
    await _tapInSheet(t, find.text('Suggest'));
    expect(find.textContaining("Couldn't send the suggestion"), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    fail = false;
    await _tapInSheet(t, find.text('Try again'));
    expect(api.calls.where((c) => c.method == 'POST'), hasLength(2));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Suggested Aftersun to Cinema Sundays.'), findsOneWidget);
  });

  testWidgets('a duplicate suggestion says the club has it, with no retry that would fail', (t) async {
    final api = _api(onPost: (path, __) {
      if (path == '/communities/c1/suggest') {
        throw ApiException(
          message: 'conflict',
          statusCode: 409,
          responseBody: {'success': false, 'code': 'DUPLICATE_SUGGESTION', 'message': 'Movie already suggested in this community'},
        );
      }
      return {'ok': true};
    });
    await _pump(t, _app(api));
    await _openSheet(t, 'Aftersun');
    await _tapInSheet(t, find.text('Cinema Sundays'));
    await _tapInSheet(t, find.text('Suggest'));
    expect(find.text('Cinema Sundays already has Aftersun. Pick another club to suggest it there.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(find.textContaining("Couldn't send"), findsNothing);
    expect(t.widget<ClButton>(_submit).onPressed, isNull, reason: 'resubmitting would 409 again');
    // Another club works.
    await _tapInSheet(t, find.text('Night Owls'));
    expect(t.widget<ClButton>(_submit).onPressed, isNotNull);
    await _tapInSheet(t, find.text('Suggest'));
    expect(find.text('Suggested Aftersun to Night Owls.'), findsOneWidget);
  });

  testWidgets('the submit says what it does, starting with its visible text', (t) async {
    final handle = t.ensureSemantics();
    final api = _api(onPost: (_, __) => throw Exception('offline'));
    await _pump(t, _app(api, joined: () => [_clubs.first]));
    await _openSheet(t, 'Aftersun');
    expect(find.bySemanticsLabel('Suggest Aftersun to Cinema Sundays'), findsOneWidget);
    await _tapInSheet(t, find.text('Suggest'));
    expect(find.text('Try again'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Try again: suggest Aftersun to Cinema Sundays'),
      findsOneWidget,
      reason: 'spoken label must start with the visible one',
    );
    expect(find.bySemanticsLabel('Suggest Aftersun to Cinema Sundays'), findsNothing);
    handle.dispose();
  });

  testWidgets('club rows read as one choice (radio group)', (t) async {
    final handle = t.ensureSemantics();
    await _pump(t, _app(_api()));
    await _openSheet(t, 'Aftersun');
    await _tapInSheet(t, find.text('Night Owls'));
    final picked = t.getSemantics(_pressable(find.text('Night Owls'))).getSemanticsData().flagsCollection;
    final other = t.getSemantics(_pressable(find.text('Cinema Sundays'))).getSemanticsData().flagsCollection;
    expect('${picked.isInMutuallyExclusiveGroup}', anyOf('true', contains('isTrue')));
    expect('${picked.isChecked}', anyOf('true', contains('isTrue')));
    expect('${other.isChecked}', anyOf('false', contains('isFalse')));
    handle.dispose();
  });

  testWidgets('the sheet cannot be dismissed while sending, and the result is shown', (t) async {
    final hold = Completer<Object?>();
    await _pump(t, _app(_api(onPost: (_, __) => hold.future), joined: () => [_clubs.first]));
    await _openSheet(t, 'Aftersun');
    await t.tap(_pressable(find.text('Suggest')));
    await t.pump();
    await t.tapAt(const Offset(20, 20)); // the scrim
    // The sending spinner never settles; pump past the dismiss animation.
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byType(BottomSheet), findsOneWidget, reason: 'closed mid-send');
    hold.complete({'ok': true});
    await t.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Suggested Aftersun to Cinema Sundays.'), findsOneWidget);
  });

  testWidgets('while a clubs retry is in flight the skeleton replaces the error', (t) async {
    var calls = 0;
    final hold = Completer<List<Community>>();
    await _pump(t, _app(_api(), joined: () {
      calls++;
      if (calls == 1) throw Exception('offline');
      return hold.future;
    }));
    await _openSheet(t, 'Aftersun');
    await t.tap(_pressable(find.text('Try again')));
    await t.pump();
    await t.pump();
    expect(find.text("Couldn't load your clubs"), findsNothing);
    expect(find.bySemanticsLabel('Loading your clubs'), findsOneWidget);
    hold.complete(_clubs);
    await t.pumpAndSettle();
    expect(find.text('Night Owls'), findsOneWidget);
  });

  testWidgets('with the keyboard up, the note field can be scrolled above it', (t) async {
    for (final (size, scale) in const [(Size(320, 568), 2.0), (Size(375, 667), 1.3), (Size(390, 844), 1.0)]) {
      // A phone keyboard takes about 40% of the screen.
      final inset = (size.height * 0.4).roundToDouble();
      await t.pumpWidget(const SizedBox());
      await _pump(
        t,
        _app(
          _api(),
          size: size,
          scale: scale,
          padding: const EdgeInsets.only(top: 20),
          viewInsets: EdgeInsets.only(bottom: inset),
        ),
        size: size,
      );
      await _openSheet(t, 'Aftersun');
      final note = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
      await t.ensureVisible(note);
      await t.pumpAndSettle();
      final rect = t.getRect(note);
      expect(rect.top, greaterThanOrEqualTo(0), reason: 'note above the screen at $size @$scale');
      expect(rect.top + 24, lessThanOrEqualTo(size.height - inset), reason: 'note under the keyboard at $size @$scale');
    }
  });

  testWidgets('no clubs: the sheet sends the user to find one', (t) async {
    await _pump(t, _app(_api(), joined: () => []));
    await _openSheet(t, 'Aftersun');
    expect(find.textContaining('Join a club first'), findsOneWidget);
    await t.tap(_pressable(find.text('Find a club')));
    await t.pumpAndSettle();
    expect(find.text('tab /communities'), findsOneWidget);
  });

  testWidgets('clubs failing to load shows a retry, not a fake list', (t) async {
    var fail = true;
    await _pump(t, _app(_api(), joined: () => fail ? throw Exception('offline') : _clubs));
    await _openSheet(t, 'Aftersun');
    expect(find.text("Couldn't load your clubs"), findsOneWidget);
    expect(find.text('Cinephiles Unite 🎬'), findsNothing);
    fail = false;
    await t.tap(_pressable(find.text('Try again')));
    await t.pumpAndSettle();
    expect(find.text('Night Owls'), findsOneWidget);
  });

  testWidgets('search: results, contract copy for none, and an error instead of demo films', (t) async {
    await _pump(t, _app(_api()));
    await t.enterText(find.byType(TextField), 'arr');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text('Arrival'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'zzzz');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text("No results for 'zzzz' — try another title"), findsOneWidget);

    await _pump(t, _app(_api(failSearch: true)));
    await t.enterText(find.byType(TextField), 'past');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.text("Search didn't go through"), findsOneWidget);
    expect(find.text('Past Lives'), findsNothing);
  });

  group('Club deep link (/communities/:id/suggest)', () {
    testWidgets('opens without crashing, has a back button and preselects the club', (t) async {
      final api = _api();
      await _pump(t, _app(api, initial: '/communities/c2/suggest'));
      expect(t.takeException(), isNull);
      expect(find.byType(ClBackButton), findsOneWidget);
      expect(find.textContaining('Pick a film for Night Owls'), findsOneWidget);
      await _openSheet(t, 'Perfect Days');
      expect(_submitFor('Perfect Days', 'Night Owls'), findsOneWidget, reason: 'club not preselected');
      await _tapInSheet(t, find.text('Suggest'));
      expect(api.calls.singleWhere((c) => c.method == 'POST').path, '/communities/c2/suggest');
      expect(find.text('club c2'), findsOneWidget, reason: 'did not return to the club');
      expect(find.text('Suggested Perfect Days to Night Owls.'), findsOneWidget);
    });

    testWidgets('a club the user is not in: says so and offers the club, not other clubs', (t) async {
      final api = _api();
      await _pump(t, _app(api, initial: '/communities/zz/suggest'));
      await _openSheet(t, 'Aftersun');
      expect(find.textContaining("You're not in Horror Hounds yet"), findsOneWidget);
      expect(find.text('Night Owls'), findsNothing, reason: 'offered a different club');
      await _tapInSheet(t, find.text('Open club'));
      expect(find.text('club zz'), findsOneWidget);
      expect(api.calls.where((c) => c.method == 'POST'), isEmpty);
    });

    testWidgets("the app's real route opens Suggest outside the shell", (t) async {
      final route = app_routes.router.configuration.findMatch(Uri.parse('/communities/x/suggest'));
      final leaf = route.matches.last;
      expect(leaf, isA<RouteMatch>());
      expect((leaf as RouteMatch).route.path, 'suggest');
      // Not under the ShellRoute: no ShellRouteMatch on the way down.
      expect(route.matches.whereType<ShellRouteMatch>(), isEmpty);
    });
  });

  group('Gold budget', () {
    testWidgets('the screen has no gold; in the sheet only the submit is gold', (t) async {
      await _pump(t, _app(_api()));
      expect(goldViolations(t), isEmpty);
      await _openSheet(t, 'Aftersun');
      await _tapInSheet(t, find.text('Night Owls'));
      expect(goldViolations(t, allowed: [_submit]), isEmpty);
    });
  });

  group('Layout', () {
    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} @${scale}x: screen and sheet fit', (t) async {
          final padding = EdgeInsets.only(top: size.height > 800 ? 47 : 20, bottom: 34);
          await _pump(t, _app(_api(), size: size, scale: scale, padding: padding), size: size);
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
          await _openSheet(t, 'Aftersun');
          await _tapInSheet(t, find.text('Night Owls'));
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
          expectNotTruncated(t, ['Suggest', 'Cinema Sundays', 'Night Owls', 'Aftersun', _longClub]);
          // The submit is reachable (the sheet scrolls at large text).
          await t.ensureVisible(_submit);
          await t.pumpAndSettle();
          expect(t.getRect(_submit).bottom, lessThanOrEqualTo(size.height));
        });

        testWidgets('${size.width.toInt()}x${size.height.toInt()} @${scale}x: the duplicate notice fits', (t) async {
          final padding = EdgeInsets.only(top: size.height > 800 ? 47 : 20, bottom: 34);
          final api = _api(onPost: (_, __) => throw ApiException(
                message: 'conflict',
                statusCode: 409,
                responseBody: {'success': false, 'code': 'DUPLICATE_SUGGESTION'},
              ));
          await _pump(t, _app(api, size: size, scale: scale, padding: padding), size: size);
          await _openSheet(t, 'Aftersun');
          await _tapInSheet(t, find.text(_longClub));
          await _tapInSheet(t, find.text('Suggest'));
          final notice = '$_longClub already has Aftersun. Pick another club to suggest it there.';
          await t.ensureVisible(find.text(notice));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
          expectNotTruncated(t, [notice]);
          expect(goldViolations(t, allowed: [_submit]), isEmpty);
        });
      }
    }
  });
}
