import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/discover/data/tmdb.dart';
import 'package:cluvie_mobile/features/movies/data/discussions.dart';
import 'package:cluvie_mobile/features/movies/data/polls.dart';
import 'package:cluvie_mobile/features/movies/presentation/club_discussions_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/discussion_thread_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_details_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/vote_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _club = '64c000000000000000000001';
const _catalogId = '64d000000000000000000001';

// ---- API fixtures, in the backend's real shapes ----

Map<String, Object?> _tmdbDetail({int id = 376867, String title = 'Moonlight'}) => {
      'success': true,
      'data': {
        'id': id,
        'title': title,
        'overview': 'A young man comes of age in Miami.',
        'tagline': 'This is the story of a lifetime.',
        'release_date': '2016-10-21',
        'runtime': 111,
        'genres': [
          {'id': 18, 'name': 'Drama'},
        ],
        'vote_average': 7.4,
        'vote_count': 7000,
        'poster_path': '/p.jpg',
        'backdrop_path': '/b.jpg',
      },
    };

Map<String, Object?> _catalog(int tmdbId) => {'_id': _catalogId, 'tmdbId': tmdbId, 'title': 'Moonlight', 'posterPath': '/p.jpg'};

Map<String, Object?> _post(String id, String text, {String user = 'Ada', bool pinned = false, int hoursAgo = 1, List<String> upvotes = const []}) => {
      '_id': id,
      'text': text,
      'userId': {'_id': 'u-$user', 'username': user},
      'pinned': pinned,
      'upvotes': upvotes,
      'createdAt': DateTime.now().subtract(Duration(hours: hoursAgo)).toUtc().toIso8601String(),
    };

Map<String, Object?> _option(String id, String title, int votes, {List<String> voters = const [], int tmdbId = 1}) => {
      '_id': id,
      'movie': {'_id': 'm-$id', 'title': title, 'posterPath': '/x.jpg', 'tmdbId': tmdbId},
      'votes': voters.isEmpty ? [for (var i = 0; i < votes; i++) 'v$i'] : voters,
      'voteCount': votes,
    };

Map<String, Object?> _poll({
  String id = '64e000000000000000000001',
  List<Map<String, Object?>>? options,
  Duration closesIn = const Duration(hours: 5, minutes: 12, seconds: 30),
  bool allowMultiple = false,
  String question = 'Friday night pick',
}) =>
    {
      '_id': id,
      'question': question,
      'status': 'open',
      'allowMultiple': allowMultiple,
      'expiresAt': DateTime.now().add(closesIn).toUtc().toIso8601String(),
      'options': options ??
          [
            _option('o1', 'Past Lives', 3, tmdbId: 11),
            _option('o2', 'Oppenheimer', 5, tmdbId: 12),
            _option('o3', 'Poor Things', 5, tmdbId: 13), // ties with o2; o2 was suggested first
          ],
    };

ApiException _apiError(int status, [Map<String, Object?>? body]) =>
    ApiException(message: 'HTTP $status', statusCode: status, responseBody: body);

// ---- Harness ----

Widget _app(
  FakeApiClient api, {
  required String initial,
  Object? extra,
  Size size = const Size(390, 844),
  double scale = 1,
  EdgeInsets padding = const EdgeInsets.only(top: 47, bottom: 34),
  EdgeInsets viewInsets = EdgeInsets.zero,
  String? me = _me,
}) {
  final router = GoRouter(initialLocation: initial, initialExtra: extra, routes: [
    GoRoute(path: '/movie/:id', builder: (_, st) => MovieDetailScreen(movieId: st.pathParameters['id'])),
    GoRoute(path: '/MovieDetails', builder: (_, __) => const MovieDetailScreen()),
    GoRoute(path: '/discussionThread', builder: (_, st) => DiscussionThreadScreen.fromExtra(st.extra)),
    GoRoute(path: '/discover', builder: (_, __) => const Scaffold(body: Text('discover tab'))),
    GoRoute(path: '/communities/:id/vote', builder: (_, st) {
      final x = st.extra is Map ? st.extra as Map : const {};
      return VoteSummaryScreen(communityId: st.pathParameters['id']!, clubName: x['club'] as String?);
    }),
    GoRoute(path: '/communities/:id/discussion', builder: (_, st) => ClubDiscussionsScreen(communityId: st.pathParameters['id']!)),
    GoRoute(path: '/communities/:id', builder: (_, st) => Scaffold(body: Text('club ${st.pathParameters['id']}'))),
    GoRoute(path: '/communities/:id/suggest', builder: (_, st) => Scaffold(body: Text('suggest ${st.pathParameters['id']}'))),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      currentUserIdProvider.overrideWith((ref) async => me),
      joinedCommunitiesProvider.overrideWith(() => FakeJoinedCommunities(() => [fakeClub(_club, 'Cinema Sundays')])),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale), padding: padding, viewPadding: padding, viewInsets: viewInsets),
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

Finder _pressable(Finder f) => find.ancestor(of: f, matching: find.byType(ClPressable)).first;
Finder _button(String label) => find.widgetWithText(ClButton, label);

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  await t.pumpAndSettle();
}

FakeApiClient _detailApi({bool inCatalog = true, List<Map<String, Object?>> posts = const []}) => FakeApiClient(
      onGet: (path, _) {
        if (path == '/tmdb/376867') return _tmdbDetail();
        if (path == '/movies/list') return inCatalog ? [_catalog(376867), _catalog(1)..['_id'] = 'other'] : [];
        if (path == '/discussions/$_catalogId') return posts;
        throw UnimplementedError(path);
      },
    );

void main() {
  setUpAll(() async {
    ClPosterImage.debugDisableNetwork = true;
    await loadRealFonts();
  });

  group('Movie Detail', () {
    testWidgets('shows the film the route names, from /tmdb/:id', (t) async {
      final api = _detailApi();
      await _pump(t, _app(api, initial: '/movie/376867'));
      expect(api.calls.map((c) => c.path), contains('/tmdb/376867'));
      expect(find.text('Moonlight'), findsWidgets);
      expect(find.text('2016 · 1h 51m'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.bySemanticsLabel('Rated 7.4 out of 10 on TMDB'), findsOneWidget);
      expect(find.text('A young man comes of age in Miami.'), findsOneWidget);
      for (final demo in ['Everything Everywhere All At Once', 'A24 · WINNER', '42 votes', '12 votes']) {
        expect(find.textContaining(demo), findsNothing);
      }
    });

    testWidgets('one suggest action, which opens the club picker sheet', (t) async {
      await _pump(t, _app(_detailApi(), initial: '/movie/376867'));
      expect(_button('Suggest to a club'), findsOneWidget);
      expect(find.textContaining('Watchlist', findRichText: true), findsNothing, reason: 'hidden until the API takes a TMDB id');
      await t.tap(_button('Suggest to a club'));
      await t.pumpAndSettle();
      expect(find.text('Suggest a film'), findsOneWidget);
      expect(find.text('Cinema Sundays'), findsOneWidget);
    });

    testWidgets('a suggestion is confirmed, and the discussion section picks the film up', (t) async {
      var suggested = false;
      final api = FakeApiClient(
        onGet: (path, _) {
          if (path == '/tmdb/376867') return _tmdbDetail();
          if (path == '/movies/list') return suggested ? [_catalog(376867)] : <Object>[];
          if (path == '/discussions/$_catalogId') return <Object>[];
          throw UnimplementedError(path);
        },
        onPost: (path, data) {
          suggested = true;
          return {'success': true};
        },
      );
      await _pump(t, _app(api, initial: '/movie/376867'));
      await _scrollTo(t, find.textContaining('No club has suggested this film yet'));
      expect(api.calls.where((c) => c.path == '/movies/list'), hasLength(1));

      await t.ensureVisible(_button('Suggest to a club'));
      await t.pumpAndSettle();
      await t.tap(_button('Suggest to a club'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Suggest').last);
      await t.pumpAndSettle();
      await t.tap(_pressable(find.text('Suggest').last));
      await t.pumpAndSettle();

      final post = api.calls.singleWhere((c) => c.method == 'POST');
      expect(post.path, '/communities/$_club/suggest');
      expect(find.text('Suggested Moonlight to Cinema Sundays.'), findsOneWidget);
      expect(api.calls.where((c) => c.path == '/movies/list'), hasLength(2), reason: 'the catalog is refetched');
      expect(find.textContaining('No club has suggested this film yet'), findsNothing);
      expect(find.text('No posts yet. Start the conversation.'), findsOneWidget);
    });

    testWidgets('reopening a film refetches a stale catalog, so other members\' suggestions show (R8-S1)', (t) async {
      final saved = catalogMaxAge;
      catalogMaxAge = Duration.zero;
      addTearDown(() => catalogMaxAge = saved);
      var inCatalog = false;
      final api = FakeApiClient(onGet: (path, _) {
        if (path == '/tmdb/376867') return _tmdbDetail();
        if (path == '/movies/list') return inCatalog ? [_catalog(376867)] : <Object>[];
        if (path == '/discussions/$_catalogId') return <Object>[];
        throw UnimplementedError(path);
      });
      await _pump(t, _app(api, initial: '/movie/376867'));
      await _scrollTo(t, find.textContaining('No club has suggested this film yet'));
      final router = GoRouter.of(t.element(find.byType(MovieDetailScreen)));
      router.go('/discover');
      await t.pumpAndSettle();
      inCatalog = true; // another member suggested it
      router.go('/movie/376867');
      await t.pumpAndSettle();
      await _scrollTo(t, find.text('No posts yet. Start the conversation.'));
      expect(find.textContaining('No club has suggested this film yet'), findsNothing);
    });

    testWidgets('a catalog that failed earlier is refetched when a film is opened (R8-S1)', (t) async {
      var fail = true;
      final api = FakeApiClient(onGet: (path, _) {
        if (path == '/tmdb/376867') return _tmdbDetail();
        if (path == '/movies/list') {
          if (fail) throw _apiError(503);
          return [_catalog(376867)];
        }
        if (path == '/discussions/$_catalogId') return <Object>[];
        throw UnimplementedError(path);
      });
      await _pump(t, _app(api, initial: '/movie/376867'));
      await _scrollTo(t, find.text("Couldn't load the discussion"));
      final router = GoRouter.of(t.element(find.byType(MovieDetailScreen)));
      router.go('/discover');
      await t.pumpAndSettle();
      fail = false;
      router.go('/movie/376867');
      await t.pumpAndSettle();
      await _scrollTo(t, find.text('No posts yet. Start the conversation.'));
      expect(find.text("Couldn't load the discussion"), findsNothing);
    });

    testWidgets('retrying the discussion preview shows the skeleton while it loads', (t) async {
      var calls = 0;
      Completer<Object?>? held;
      final api = FakeApiClient(onGet: (path, _) {
        if (path == '/tmdb/376867') return _tmdbDetail();
        if (path == '/movies/list') {
          calls++;
          if (calls == 1) throw Exception('offline');
          held = Completer<Object?>();
          return held!.future;
        }
        if (path == '/discussions/$_catalogId') return <Object>[];
        throw UnimplementedError(path);
      });
      await _pump(t, _app(api, initial: '/movie/376867'));
      await _scrollTo(t, find.text("Couldn't load the discussion"));
      await t.tap(_button('Try again'));
      await t.pump();
      expect(find.text("Couldn't load the discussion"), findsNothing);
      expect(find.byType(ClSkeletonRow), findsOneWidget);
      held!.complete([_catalog(376867)]);
      await t.pumpAndSettle();
      expect(find.text('No posts yet. Start the conversation.'), findsOneWidget);
    });

    testWidgets('no id, a bad id, or a 404 shows "not found", with a way out', (t) async {
      for (final route in ['/MovieDetails', '/movie/abc']) {
        await _pump(t, _app(_detailApi(), initial: route));
        expect(find.text("We couldn't find this film"), findsOneWidget, reason: route);
      }
      final api = FakeApiClient(onGet: (_, __) => throw _apiError(404));
      await _pump(t, _app(api, initial: '/movie/5'));
      expect(find.text("We couldn't find this film"), findsOneWidget);
      await t.tap(_button('Browse films'));
      await t.pumpAndSettle();
      expect(find.text('discover tab'), findsOneWidget);
    });

    testWidgets('a load failure shows retry, and retry loads the film', (t) async {
      var fail = true;
      final api = FakeApiClient(onGet: (path, _) {
        if (fail) throw _apiError(503);
        return _detailApi().onGet!(path, null);
      });
      await _pump(t, _app(api, initial: '/movie/376867'));
      expect(find.text("Couldn't load this film"), findsOneWidget);
      fail = false;
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('A young man comes of age in Miami.'), findsOneWidget);
    });

    testWidgets('on a deep link with no back stack, back goes to Discover', (t) async {
      await _pump(t, _app(_detailApi(), initial: '/movie/376867'));
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(find.text('discover tab'), findsOneWidget);
    });

    testWidgets('a film no club has suggested says how to start its discussion', (t) async {
      await _pump(t, _app(_detailApi(inCatalog: false), initial: '/movie/376867'));
      await _scrollTo(t, find.textContaining('No club has suggested this film yet'));
      expect(find.textContaining('No club has suggested this film yet'), findsOneWidget);
    });

    testWidgets('a catalog film previews its latest posts and opens the thread', (t) async {
      final api = _detailApi(posts: [_post('p1', 'That diner scene.'), _post('p2', 'Best score of the decade.', hoursAgo: 3), _post('p3', 'Third', hoursAgo: 10)]);
      await _pump(t, _app(api, initial: '/movie/376867'));
      await _scrollTo(t, _button('Open discussion (3 posts)'));
      expect(find.text('That diner scene.'), findsOneWidget);
      expect(find.text('Third'), findsNothing, reason: 'preview shows two');
      await t.tap(_button('Open discussion (3 posts)'));
      await t.pumpAndSettle();
      expect(find.byType(DiscussionThreadScreen), findsOneWidget);
      final screen = t.widget<DiscussionThreadScreen>(find.byType(DiscussionThreadScreen));
      expect(screen.movieId, _catalogId);
      expect(screen.tmdbId, 376867);
    });
  });

  group('Vote', () {
    FakeApiClient pollsApi({
      List<Map<String, Object?>> Function()? polls,
      FutureOr<Object?> Function(String path, Map<String, dynamic>? data)? onPost,
    }) =>
        FakeApiClient(
          onGet: (path, params) {
            expect(path, '/polls/active');
            expect(params, {'communityId': _club});
            return (polls ?? () => [_poll()])();
          },
          onPost: onPost ?? (_, __) => {'success': true},
        );

    testWidgets('ranks by votes, ties to the earlier suggestion, and shows the real club', (t) async {
      await _pump(t, _app(pollsApi(), initial: '/communities/$_club/vote', extra: {'club': 'Cinema Sundays'}));
      expect(find.text('Cinema Sundays vote'), findsOneWidget);
      expect(find.text('Friday night pick'), findsOneWidget);
      expect(find.text('Closes in 5h 12m'), findsOneWidget);
      expect(find.text('You get one vote, and it’s final.'), findsOneWidget);
      final ys = [for (final f in ['Oppenheimer', 'Poor Things', 'Past Lives']) t.getTopLeft(find.text(f)).dy];
      expect(ys, orderedEquals([...ys]..sort()), reason: 'Oppenheimer wins the tie: it was suggested first');
      expect(find.text('Leading'), findsOneWidget);
      expect(find.textContaining('Status'), findsNothing, reason: 'no debug footer');
      expect(find.textContaining('Close poll'), findsNothing, reason: 'no close endpoint, so no control');
    });

    testWidgets('a vote posts the option, is counted at once, and rows stay put', (t) async {
      final api = pollsApi();
      await _pump(t, _app(api, initial: '/communities/$_club/vote'));
      final before = t.getTopLeft(find.text('Past Lives')).dy;
      await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
      await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
      await t.pumpAndSettle();
      final post = api.calls.singleWhere((c) => c.method == 'POST');
      expect(post.path, '/polls/64e000000000000000000001/vote');
      expect(post.data, {'optionId': 'o1'});
      expect(find.text('4 votes'), findsOneWidget);
      expect(find.text('Your vote'), findsOneWidget);
      expect(_button('Vote'), findsNothing, reason: 'single-choice: no more votes');
      expect(find.text("You've voted. Votes are final."), findsOneWidget);
      await t.scrollUntilVisible(find.text('Oppenheimer'), -200, scrollable: find.byType(Scrollable).first);
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.text('Past Lives')).dy - t.getTopLeft(find.text('Oppenheimer')).dy,
          greaterThan(0), reason: 'Past Lives stays below');
      expect(before, isNonZero);
    });

    testWidgets('a failed vote is rolled back, with retry', (t) async {
      await _pump(t, _app(pollsApi(onPost: (_, __) => throw _apiError(500)), initial: '/communities/$_club/vote'));
      await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
      await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
      await t.pumpAndSettle();
      expect(find.text('3 votes'), findsOneWidget);
      expect(find.text('Your vote'), findsNothing);
      expect(find.text("Couldn't count your vote. Try again."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a failed vote\'s Retry votes again', (t) async {
      var fail = true;
      final api = pollsApi(onPost: (_, __) {
        if (fail) throw _apiError(500);
        return {'success': true};
      });
      await _pump(t, _app(api, initial: '/communities/$_club/vote'));
      await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
      await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
      await t.pumpAndSettle();
      fail = false;
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(api.calls.where((c) => c.method == 'POST'), hasLength(2));
      expect(find.text('Voted for Past Lives'), findsOneWidget);
    });

    testWidgets('signed out: voting asks the user to sign in and sends nothing', (t) async {
      final api = pollsApi();
      await _pump(t, _app(api, initial: '/communities/$_club/vote', me: null));
      await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
      await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
      await t.pumpAndSettle();
      expect(find.text('Sign in to vote'), findsOneWidget);
      expect(api.calls.where((c) => c.method == 'POST'), isEmpty);
      expect(find.text('3 votes'), findsOneWidget);
    });

    for (final code in ['POLL_CLOSED', 'ALREADY_VOTED']) {
      testWidgets('a refused vote ($code) is undone even when the reload fails (R8-S3)', (t) async {
        var loads = 0;
        final api = pollsApi(
          polls: () {
            loads++;
            if (loads > 1) throw _apiError(503);
            return [_poll()];
          },
          onPost: (_, __) => throw _apiError(400, {'code': code}),
        );
        await _pump(t, _app(api, initial: '/communities/$_club/vote'));
        await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
        await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
        await t.pumpAndSettle();
        expect(loads, 2);
        expect(find.text('Your vote'), findsNothing);
        expect(find.text('3 votes'), findsOneWidget);
      });
    }

    testWidgets('a non-member is told to join, not to retry (403)', (t) async {
      final api = pollsApi(onPost: (_, __) => throw _apiError(403, {'success': false, 'message': 'You must be a member of this community to vote'}));
      await _pump(t, _app(api, initial: '/communities/$_club/vote', extra: {'club': 'Cinema Sundays'}));
      await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
      await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
      await t.pumpAndSettle();
      expect(find.text('Join Cinema Sundays to vote'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('3 votes'), findsOneWidget, reason: 'rolled back');
      await t.tap(find.text('Open club'));
      await t.pumpAndSettle();
      expect(find.text('club $_club'), findsOneWidget);
    });

    testWidgets('row labels start with the visible title, and give no rank', (t) async {
      final handle = t.ensureSemantics();
      await _pump(t, _app(pollsApi(), initial: '/communities/$_club/vote'));
      String label(String title) =>
          t.getSemantics(find.ancestor(of: find.text(title), matching: find.byType(ClPressable)).first).label;
      expect(label('Oppenheimer'), 'Oppenheimer, 5 votes, Leading. Open film details');
      expect(label('Past Lives'), 'Past Lives, 3 votes. Open film details');
      await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
      await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
      await t.pumpAndSettle();
      expect(label('Past Lives'), 'Past Lives, 4 votes, your vote. Open film details');
      for (final title in ['Oppenheimer', 'Poor Things', 'Past Lives']) {
        expect(label(title), isNot(contains('Number')));
      }
      handle.dispose();
    });

    testWidgets('a failed pull-to-refresh keeps the vote on screen and says so', (t) async {
      var fail = false;
      final api = pollsApi(polls: () {
        if (fail) throw _apiError(503);
        return [_poll()];
      });
      await _pump(t, _app(api, initial: '/communities/$_club/vote'));
      fail = true;
      await t.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await t.pumpAndSettle();
      expect(find.text("Couldn't load the vote"), findsNothing);
      expect(find.text('Friday night pick'), findsOneWidget);
      expect(find.text("Couldn't refresh. Showing the earlier vote."), findsOneWidget);
    });

    testWidgets('retrying a failed load shows the skeleton', (t) async {
      var calls = 0;
      Completer<Object?>? held;
      final api = pollsApi(polls: () => throw StateError('unused'));
      api.onGet = (path, _) {
        calls++;
        if (calls == 1) throw _apiError(503);
        held = Completer<Object?>();
        return held!.future;
      };
      await _pump(t, _app(api, initial: '/communities/$_club/vote'));
      expect(find.text("Couldn't load the vote"), findsOneWidget);
      await t.tap(_button('Try again'));
      await t.pump();
      expect(find.text("Couldn't load the vote"), findsNothing);
      expect(find.byType(ClSkeletonRow), findsWidgets);
      held!.complete([_poll()]);
      await t.pumpAndSettle();
      expect(find.text('Friday night pick'), findsOneWidget);
    });

    testWidgets('"already voted" reloads the poll and says so', (t) async {
      var loads = 0;
      final api = pollsApi(
        polls: () {
          loads++;
          return [
            _poll(options: [
              _option('o1', 'Past Lives', 3),
              _option('o2', 'Oppenheimer', loads > 1 ? 6 : 5, voters: loads > 1 ? ['a', 'b', 'c', 'd', 'e', _me] : const []),
            ]),
          ];
        },
        onPost: (_, __) => throw _apiError(400, {'code': 'ALREADY_VOTED'}),
      );
      await _pump(t, _app(api, initial: '/communities/$_club/vote'));
      await _scrollTo(t, find.bySemanticsLabel('Vote for Past Lives'));
      await t.tap(find.bySemanticsLabel('Vote for Past Lives'));
      await t.pumpAndSettle();
      expect(loads, 2);
      expect(find.text('You already voted in this poll'), findsOneWidget);
      expect(find.text('Your vote'), findsOneWidget);
    });

    testWidgets('an expired poll shows as closed with no vote buttons', (t) async {
      // Expired while on screen (the API only lists unexpired polls).
      final api = pollsApi(polls: () => [_poll(closesIn: const Duration(minutes: -1))]);
      await _pump(t, _app(api, initial: '/communities/$_club/vote'));
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Voting has closed.'), findsOneWidget);
      expect(_button('Vote'), findsNothing);
      expect(find.text('Winner'), findsOneWidget);
    });

    testWidgets('no polls: the empty state, with a way to suggest', (t) async {
      await _pump(t, _app(pollsApi(polls: () => []), initial: '/communities/$_club/vote'));
      expect(find.text('Votes are made from the films the club suggests. Suggest one to get started.'), findsOneWidget);
      await t.tap(_button('Suggest a film'));
      await t.pumpAndSettle();
      expect(find.text('suggest $_club'), findsOneWidget);
    });

    testWidgets('a demo club id is "no polls" without calling the API', (t) async {
      final api = FakeApiClient();
      await _pump(t, _app(api, initial: '/communities/demo/vote'));
      expect(api.calls, isEmpty);
      expect(find.text('Votes are made from the films the club suggests. Suggest one to get started.'), findsOneWidget);
    });

    testWidgets('a load failure shows retry', (t) async {
      var fail = true;
      final api = FakeApiClient(onGet: (_, __) => fail ? throw _apiError(500) : [_poll()]);
      await _pump(t, _app(api, initial: '/communities/$_club/vote'));
      expect(find.text("Couldn't load the vote"), findsOneWidget);
      fail = false;
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('Friday night pick'), findsOneWidget);
    });

    testWidgets('a film row opens Movie Detail', (t) async {
      await _pump(t, _app(pollsApi(), initial: '/communities/$_club/vote'));
      await t.tap(_pressable(find.text('Oppenheimer')));
      await t.pumpAndSettle();
      expect(find.byType(MovieDetailScreen), findsOneWidget);
      expect(t.widget<MovieDetailScreen>(find.byType(MovieDetailScreen)).movieId, '12');
    });

    testWidgets('on a deep link, back goes to the club', (t) async {
      await _pump(t, _app(pollsApi(), initial: '/communities/$_club/vote'));
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(find.text('club $_club'), findsOneWidget);
    });

    test('Poll.ranked: votes desc, ties to the lower index', () {
      final p = Poll.fromJson(_poll())!;
      expect([for (final o in p.ranked) o.title], ['Oppenheimer', 'Poor Things', 'Past Lives']);
      expect(p.leader!.title, 'Oppenheimer');
      expect(Poll.fromJson(_poll(options: [_option('a', 'A', 0), _option('b', 'B', 0)]))!.leader, isNull);
    });
  });

  group('Discussion', () {
    Map<String, Object> extra() => DiscussionThreadScreen.extraFor(movieId: _catalogId, title: 'Moonlight', tmdbId: 376867);

    FakeApiClient threadApi({
      List<Map<String, Object?>> Function()? posts,
      FutureOr<Object?> Function(String path, Map<String, dynamic>? data)? onPost,
    }) =>
        FakeApiClient(
          onGet: (path, _) {
            if (path == '/discussions/$_catalogId') {
              return (posts ??
                  () => [
                        _post('a', 'Older post', hoursAgo: 5),
                        _post('pin', 'House rules: tag spoilers.', user: 'Host', pinned: true, hoursAgo: 30),
                        _post('b', 'Newest post', hoursAgo: 1, upvotes: ['x']),
                      ])();
            }
            throw UnimplementedError(path);
          },
          onPost: onPost,
        );

    testWidgets('shows the film from the route, pinned first, then newest', (t) async {
      await _pump(t, _app(threadApi(), initial: '/discussionThread', extra: extra()));
      expect(find.text('Moonlight'), findsWidgets);
      expect(find.text('3 posts'), findsOneWidget);
      expect(find.text('PINNED'), findsOneWidget);
      final ys = [for (final s in ['House rules: tag spoilers.', 'Newest post', 'Older post']) t.getTopLeft(find.text(s)).dy];
      expect(ys, orderedEquals([...ys]..sort()));
      for (final demo in ['Past Lives', 'infinite scroll', 'Tap a reaction']) {
        expect(find.textContaining(demo), findsNothing);
      }
    });

    testWidgets('no posts: "Be the first to comment"', (t) async {
      await _pump(t, _app(threadApi(posts: () => []), initial: '/discussionThread', extra: extra()));
      expect(find.text('Be the first to comment'), findsOneWidget);
    });

    testWidgets('without a film id, says the discussion is not open (no demo posts)', (t) async {
      final api = FakeApiClient();
      await _pump(t, _app(api, initial: '/discussionThread', extra: {'title': 'Oppenheimer', 'posterUrl': 'x'}));
      expect(api.calls, isEmpty);
      expect(find.text("This discussion isn't open yet"), findsOneWidget);
      expect(find.text('Oppenheimer'), findsOneWidget);
    });

    testWidgets('posting sends the text and shows the post; Enter adds a line', (t) async {
      // Like the server: the POST answers with an unpopulated author, and
      // the next GET lists the post with the author's name.
      final stored = <Map<String, Object?>>[];
      final api = threadApi(
        posts: () => [...stored, _post('a', 'Older post', hoursAgo: 5)],
        onPost: (path, data) {
          stored.add(_post('new', data!['text'] as String, user: 'Me', hoursAgo: 0));
          return {
            'message': 'Discussion created',
            'discussion': {'_id': 'new', 'text': data['text'], 'userId': _me, 'createdAt': DateTime.now().toUtc().toIso8601String()},
          };
        },
      );
      await _pump(t, _app(api, initial: '/discussionThread', extra: extra()));
      final field = find.byType(TextField);
      expect(t.widget<TextField>(field).keyboardType, TextInputType.multiline);
      await t.enterText(field, 'Line one\nline two');
      await t.pump();
      await t.tap(find.byTooltip('Post'));
      await t.pumpAndSettle();
      final post = api.calls.singleWhere((c) => c.method == 'POST');
      expect(post.path, '/discussions');
      expect(post.data, {'movieId': _catalogId, 'text': 'Line one\nline two'});
      expect(find.text('Line one\nline two'), findsOneWidget);
      expect(t.widget<TextField>(field).controller!.text, isEmpty);
      // No name was known locally (cold start), so the thread reloaded to
      // show the author's name rather than "Cluvie member" (N6).
      expect(api.calls.where((c) => c.method == 'GET'), hasLength(2));
      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Cluvie member'), findsNothing);
    });

    testWidgets('two quick posts: a slow older reload can\'t hide the newer post (R8-S4)', (t) async {
      final stored = <Map<String, Object?>>[];
      final held = <Completer<Object?>>[];
      var gets = 0;
      final api = FakeApiClient(
        onGet: (path, _) {
          gets++;
          if (gets == 1) return <Object>[];
          final snapshot = [...stored];
          final c = Completer<Object?>();
          held.add(c);
          return c.future.then((_) => snapshot);
        },
        onPost: (path, data) {
          final id = 'p${stored.length}';
          stored.add(_post(id, data!['text'] as String, user: 'Me', hoursAgo: 0));
          return {'discussion': {'_id': id, 'text': data['text'], 'userId': _me, 'createdAt': DateTime.now().toUtc().toIso8601String()}};
        },
      );
      await _pump(t, _app(api, initial: '/discussionThread', extra: extra()));
      for (final text in ['First post', 'Second post']) {
        await t.enterText(find.byType(TextField), text);
        await t.pump();
        await t.tap(find.byTooltip('Post'));
        await t.pump();
        await t.pump();
      }
      expect(held, hasLength(2));
      held[1].complete(null); // the newer reload: [First, Second]
      await t.pump();
      held[0].complete(null); // the older one, arriving last: [First]
      await t.pumpAndSettle();
      expect(find.text('First post'), findsOneWidget);
      expect(find.text('Second post'), findsOneWidget);
    });

    testWidgets('a failed post keeps the draft and offers retry', (t) async {
      await _pump(t, _app(threadApi(onPost: (_, __) => throw _apiError(500)), initial: '/discussionThread', extra: extra()));
      await t.enterText(find.byType(TextField), 'Keep me');
      await t.pump();
      await t.tap(find.byTooltip('Post'));
      await t.pumpAndSettle();
      expect(find.text("Couldn't post. Your text is still here."), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).controller!.text, 'Keep me');
    });

    testWidgets('the composer caps posts at 2000 characters and shows the count near it', (t) async {
      await _pump(t, _app(threadApi(), initial: '/discussionThread', extra: extra()));
      await t.enterText(find.byType(TextField), 'a' * 2100);
      await t.pump();
      expect(t.widget<TextField>(find.byType(TextField)).controller!.text.length, kMaxPostLength);
      expect(find.text('2000 / 2000'), findsOneWidget);
    });

    testWidgets('like is optimistic, then can’t be undone', (t) async {
      final api = threadApi(onPost: (_, __) => {'message': 'Upvote added'});
      await _pump(t, _app(api, initial: '/discussionThread', extra: extra()));
      await t.tap(find.bySemanticsLabel('Like, 1 like'));
      await t.pumpAndSettle();
      expect(api.calls.last.path, '/discussions/b/upvote');
      expect(find.bySemanticsLabel('You liked this, 2 likes'), findsOneWidget);
    });

    testWidgets('a failed like rolls back', (t) async {
      await _pump(t, _app(threadApi(onPost: (_, __) => throw _apiError(500)), initial: '/discussionThread', extra: extra()));
      await t.tap(find.bySemanticsLabel('Like, 1 like'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Like, 1 like'), findsOneWidget);
      expect(find.text("Couldn't like that post. Try again."), findsOneWidget);
    });

    testWidgets('the composer sits above the home indicator and the keyboard', (t) async {
      await _pump(t, _app(threadApi(), initial: '/discussionThread', extra: extra()));
      expect(t.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(844 - 34));
      await _pump(t, _app(threadApi(), initial: '/discussionThread', extra: extra(), viewInsets: const EdgeInsets.only(bottom: 300)));
      expect(t.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(844 - 300));
    });

    // B2, round 7: a long draft at large text must not push Post under the
    // keyboard or squeeze the posts to nothing.
    // With the keyboard up the bottom inset is 0; the small phones have a
    // 20pt status bar.
    for (final (size, keyboard, top) in [(const Size(320, 568), 260.0, 20.0), (const Size(375, 667), 260.0, 20.0), (const Size(390, 844), 300.0, 47.0)]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('${size.width.toInt()}x${size.height.toInt()} @${scale}x, keyboard up, empty draft: the hint fits', (t) async {
          await _pump(
            t,
            _app(
              threadApi(),
              initial: '/discussionThread',
              extra: extra(),
              size: size,
              scale: scale,
              padding: EdgeInsets.only(top: top),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            size: size,
          );
          expect(t.takeException(), isNull);
          final field = t.getRect(find.byType(TextField));
          final hintText = scale > 1.2 ? 'Write a post' : 'Add to the discussion';
          final hint = t.getRect(find.text(hintText));
          expect(hint.top, greaterThanOrEqualTo(field.top), reason: 'hint inside the field');
          expect(hint.bottom, lessThanOrEqualTo(field.bottom), reason: 'hint not clipped');
          expectNotTruncated(t, [hintText]);
          expectNoBrokenWords(t);
          expect(field.bottom, lessThanOrEqualTo(size.height - keyboard));
        });

        testWidgets('${size.width.toInt()}x${size.height.toInt()} @${scale}x, keyboard up, 5-line draft: Post stays reachable', (t) async {
          await _pump(
            t,
            _app(
              threadApi(),
              initial: '/discussionThread',
              extra: extra(),
              size: size,
              scale: scale,
              padding: EdgeInsets.only(top: top),
              viewInsets: EdgeInsets.only(bottom: keyboard),
            ),
            size: size,
          );
          await t.enterText(find.byType(TextField), 'One\ntwo\nthree\nfour\nfive, and a longer last line to wrap');
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          final keyboardTop = size.height - keyboard;
          expect(t.getRect(find.byTooltip('Post')).bottom, lessThanOrEqualTo(keyboardTop));
          expect(t.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(keyboardTop));
          expect(t.getSize(find.byType(ListView)).height, greaterThanOrEqualTo(48), reason: 'the posts keep at least a row');
          expect(t.widget<IconButton>(find.widgetWithIcon(IconButton, AppIcons.send)).onPressed, isNotNull);
        });
      }
    }

    testWidgets('retrying a failed load shows the skeleton', (t) async {
      var calls = 0;
      Completer<Object?>? held;
      final api = FakeApiClient(onGet: (path, _) {
        calls++;
        if (calls == 1) throw _apiError(503);
        held = Completer<Object?>();
        return held!.future;
      });
      await _pump(t, _app(api, initial: '/discussionThread', extra: extra()));
      expect(find.text("Couldn't load the discussion"), findsOneWidget);
      await t.tap(_button('Try again'));
      await t.pump();
      expect(find.text("Couldn't load the discussion"), findsNothing);
      expect(find.byType(ClSkeletonRow), findsWidgets);
      held!.complete([_post('a', 'Back again')]);
      await t.pumpAndSettle();
      expect(find.text('Back again'), findsOneWidget);
    });

    testWidgets('send and like are at least 48dp', (t) async {
      await _pump(t, _app(threadApi(), initial: '/discussionThread', extra: extra()));
      final send = t.getSize(find.ancestor(of: find.byTooltip('Post'), matching: find.byType(SizedBox)).first);
      expect(send.width, greaterThanOrEqualTo(48));
      expect(send.height, greaterThanOrEqualTo(48));
      final like = t.getSize(_pressable(find.bySemanticsLabel('Like, 1 like')));
      expect(like.height, greaterThanOrEqualTo(48));
    });

    testWidgets('on a deep link, back goes to the film', (t) async {
      await _pump(t, _app(threadApi(), initial: '/discussionThread', extra: extra()));
      expect(find.text('Discussion'), findsOneWidget, reason: 'the bar names the screen; the header names the film');
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(find.byType(MovieDetailScreen), findsOneWidget);
    });

    test('pinned first, then newest', () {
      final now = DateTime.now();
      final posts = [
        DiscussionPost(id: '1', text: '', createdAt: now.subtract(const Duration(hours: 2))),
        DiscussionPost(id: '2', text: '', createdAt: now.subtract(const Duration(days: 3)), pinned: true),
        DiscussionPost(id: '3', text: '', createdAt: now),
      ]..sort(comparePosts);
      expect([for (final p in posts) p.id], ['2', '3', '1']);
    });
  });

  group('Club discussions', () {
    testWidgets('lists the club’s films; each opens its discussion', (t) async {
      final api = FakeApiClient(onGet: (path, _) {
        expect(path, '/communities/$_club/movies');
        return {
          'success': true,
          'data': [
            {'_id': _catalogId, 'tmdbId': 376867, 'title': 'Moonlight', 'posterPath': '/p.jpg', 'releaseDate': '2016-10-21'},
          ],
        };
      });
      await _pump(t, _app(api, initial: '/communities/$_club/discussion'));
      expect(find.text('Moonlight'), findsOneWidget);
      await t.tap(_pressable(find.text('Moonlight')));
      await t.pumpAndSettle();
      expect(t.widget<DiscussionThreadScreen>(find.byType(DiscussionThreadScreen)).movieId, _catalogId);
    });

    testWidgets('a failed pull-to-refresh keeps the films and says so', (t) async {
      var fail = false;
      final api = FakeApiClient(onGet: (path, _) {
        if (fail) throw _apiError(503);
        return {'success': true, 'data': [_catalog(376867)]};
      });
      await _pump(t, _app(api, initial: '/communities/$_club/discussion'));
      fail = true;
      await t.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await t.pumpAndSettle();
      expect(find.text("Couldn't load discussions"), findsNothing);
      expect(find.text('Moonlight'), findsOneWidget);
      expect(find.text("Couldn't refresh. Showing earlier discussions."), findsOneWidget);
    });

    testWidgets('retrying a failed load shows the skeleton', (t) async {
      var calls = 0;
      Completer<Object?>? held;
      final api = FakeApiClient(onGet: (path, _) {
        calls++;
        if (calls == 1) throw _apiError(503);
        held = Completer<Object?>();
        return held!.future;
      });
      await _pump(t, _app(api, initial: '/communities/$_club/discussion'));
      await t.tap(_button('Try again'));
      await t.pump();
      expect(find.text("Couldn't load discussions"), findsNothing);
      expect(find.byType(ClSkeletonRow), findsWidgets);
      held!.complete({'success': true, 'data': [_catalog(376867)]});
      await t.pumpAndSettle();
      expect(find.text('Moonlight'), findsOneWidget);
    });

    testWidgets('no films: empty state with suggest', (t) async {
      await _pump(t, _app(FakeApiClient(onGet: (_, __) => {'success': true, 'data': []}), initial: '/communities/$_club/discussion'));
      expect(find.text('No discussions yet'), findsOneWidget);
    });
  });

  group('Layout and gold budget', () {
    const longTitle = 'The Assassination of Jesse James by the Coward Robert Ford';
    FakeApiClient api() => FakeApiClient(
          onGet: (path, _) {
            if (path.startsWith('/tmdb/')) return _tmdbDetail(title: longTitle);
            if (path == '/movies/list') return [_catalog(376867)];
            if (path.startsWith('/discussions/')) {
              return [
                _post('pin', 'House rules: tag spoilers.', user: 'Extraordinarily Longusername', pinned: true),
                _post('b', 'Newest post', upvotes: ['x']),
              ];
            }
            if (path == '/polls/active') {
              return [
                _poll(options: [_option('o1', longTitle, 2), _option('o2', 'Oppenheimer', 1)]),
              ];
            }
            if (path == '/communities/$_club/movies') {
              return {
                'success': true,
                'data': [
                  {..._catalog(376867), 'title': longTitle, 'releaseDate': '2007-09-21'},
                  {..._catalog(2), '_id': '64d000000000000000000002', 'title': 'Moonlight'},
                ],
              };
            }
            throw UnimplementedError(path);
          },
        );

    for (final size in const [Size(320, 568), Size(375, 667), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        final name = '${size.width.toInt()}x${size.height.toInt()} @${scale}x';
        final padding = EdgeInsets.only(top: size.height > 800 ? 47 : 20, bottom: 34);

        testWidgets('$name: Movie Detail fits; gold only on the suggest button', (t) async {
          await _pump(t, _app(api(), initial: '/movie/376867', size: size, scale: scale, padding: padding), size: size);
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
          expect(goldViolations(t, allowed: [_button('Suggest to a club')]), isEmpty);
          await _scrollTo(t, _button('Open discussion (2 posts)'));
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
        });

        testWidgets('$name: Vote fits; gold only on the leader badge', (t) async {
          await _pump(t, _app(api(), initial: '/communities/$_club/vote', extra: {'club': 'Cinema Sundays'}, size: size, scale: scale, padding: padding), size: size);
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
          expectNotTruncated(t, [longTitle, 'Oppenheimer']);
          expect(goldViolations(t, allowed: [find.widgetWithText(ClBadge, 'Leading')]), isEmpty);
        });

        testWidgets('$name: Club discussions fits; no gold', (t) async {
          await _pump(t, _app(api(), initial: '/communities/$_club/discussion', size: size, scale: scale, padding: padding), size: size);
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
          expectNotTruncated(t, [longTitle, 'Moonlight']);
          expect(goldViolations(t), isEmpty);
        });

        testWidgets('$name: Discussion fits; no gold', (t) async {
          await _pump(
            t,
            _app(api(),
                initial: '/discussionThread',
                extra: DiscussionThreadScreen.extraFor(movieId: _catalogId, title: longTitle, tmdbId: 376867),
                size: size,
                scale: scale,
                padding: padding),
            size: size,
          );
          expect(t.takeException(), isNull);
          expectNoBrokenWords(t);
          expect(goldViolations(t), isEmpty);
        });
      }
    }
  });
}
