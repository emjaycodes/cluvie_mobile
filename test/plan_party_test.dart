import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/watch_party/presentation/plan_party_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _club = '64c000000000000000000001';
const _dune = '64d000000000000000000001';
const _heat = '64d000000000000000000002';
const _party = '64e000000000000000000001';

Map<String, Object?> _film(String id, int tmdbId, String title) =>
    {'_id': id, 'tmdbId': tmdbId, 'id': tmdbId, 'title': title, 'release_date': '2021-10-22'};

class _Server {
  _Server({this.isMember = true, List<Map<String, Object?>>? films})
      : films = films ?? [_film(_dune, 438631, 'Dune'), _film(_heat, 949, 'Heat')];
  bool isMember;
  List<Map<String, Object?>> films;
  Object? postError;
  final posts = <Map<String, dynamic>>[];

  late final api = FakeApiClient(
    onGet: (path, params) {
      if (path == '/communities/$_club') {
        return {
          'success': true,
          'data': {
            '_id': _club,
            'name': 'Cinema Sundays',
            'description': 'd',
            'owner': 'someone',
            'members': [
              {'user': 'someone', 'role': 'admin'},
              if (isMember) {'user': _me, 'role': 'member'},
            ],
          },
        };
      }
      if (path == '/communities/$_club/movies') return {'success': true, 'data': films};
      throw UnimplementedError(path);
    },
    onPost: (path, data) {
      if (path != '/watchparties') throw UnimplementedError(path);
      posts.add(data!);
      if (postError != null) throw postError!;
      return {
        'success': true,
        'data': {
          '_id': _party,
          'title': data['title'],
          'scheduledAt': data['scheduledAt'],
          'status': 'scheduled',
          'host': {'_id': _me, 'username': 'me'},
          'community': {'_id': _club, 'name': 'Cinema Sundays'},
          'participants': [_me],
        },
      };
    },
  );
}

Widget _app(_Server server, {String location = '/communities/$_club/watch-party/new', double scale = 1, Size size = const Size(390, 844)}) {
  final router = GoRouter(initialLocation: location, routes: [
    GoRoute(path: '/communities/:id', builder: (_, st) => Text('club ${st.pathParameters['id']}'), routes: [
      GoRoute(
        path: 'watch-party/new',
        builder: (_, st) => PlanPartyScreen(communityId: st.pathParameters['id']!, movieId: st.uri.queryParameters['movie']),
      ),
      GoRoute(path: 'suggest', builder: (_, __) => const Text('suggest page')),
    ]),
    GoRoute(path: '/watch-parties/:id', builder: (_, st) => Text('party ${st.pathParameters['id']}')),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(server.api),
      currentUserIdProvider.overrideWith((ref) async => _me),
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

Finder get _submit => find.widgetWithText(ClButton, 'Schedule watch party');

Future<void> _tapSubmit(WidgetTester t) async {
  await t.ensureVisible(_submit);
  await t.pumpAndSettle();
  await t.tap(_submit);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async => loadRealFonts());

  group('defaultPartyStart', () {
    test('8pm today when that is at least an hour away, else tomorrow', () {
      expect(defaultPartyStart(DateTime(2026, 11, 27, 18, 59)), DateTime(2026, 11, 27, 20));
      expect(defaultPartyStart(DateTime(2026, 11, 27, 19, 1)), DateTime(2026, 11, 28, 20));
      expect(defaultPartyStart(DateTime(2026, 11, 30, 23)), DateTime(2026, 12, 1, 20));
    });
  });

  testWidgets('schedules the first film with a filled-in title and lands on the new party', (t) async {
    final server = _Server();
    await _pump(t, _app(server));

    expect(find.widgetWithText(TextFormField, 'Dune night'), findsOneWidget);
    await _tapSubmit(t);

    expect(server.posts, hasLength(1));
    final body = server.posts.single;
    expect(body['movieId'], _dune, reason: 'the catalog id, not the TMDB id');
    expect(body['communityId'], _club);
    expect(body['title'], 'Dune night');
    expect(body['isPrivate'], false);
    expect(body.containsKey('description'), isFalse);
    final sent = DateTime.parse(body['scheduledAt'] as String);
    expect(sent.isUtc, isTrue);
    expect(sent, defaultPartyStart(DateTime.now()).toUtc());
    expect(find.text('party $_party'), findsOneWidget);
  });

  testWidgets('picking a film retitles until the title is edited; note and members-only are sent', (t) async {
    final server = _Server();
    await _pump(t, _app(server));

    await t.tap(find.text('Heat'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Heat night'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextFormField, 'Heat night'), 'Pacino vs De Niro');
    await t.tap(find.text('Dune'));
    await t.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Pacino vs De Niro'), findsOneWidget);

    await t.enterText(find.byType(TextFormField).last, '  Bring snacks  ');
    await t.ensureVisible(find.byType(Switch));
    await t.pumpAndSettle();
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(find.text('Only Cinema Sundays members can see it.'), findsOneWidget);
    await _tapSubmit(t);

    expect(server.posts.single, containsPair('movieId', _dune));
    expect(server.posts.single, containsPair('title', 'Pacino vs De Niro'));
    expect(server.posts.single, containsPair('description', 'Bring snacks'));
    expect(server.posts.single, containsPair('isPrivate', true));
  });

  testWidgets('?movie= preselects that film', (t) async {
    await _pump(t, _app(_Server(), location: '/communities/$_club/watch-party/new?movie=$_heat'));
    expect(find.widgetWithText(TextFormField, 'Heat night'), findsOneWidget);
  });

  testWidgets('an empty title is refused before anything is sent', (t) async {
    final server = _Server();
    await _pump(t, _app(server));
    await t.enterText(find.widgetWithText(TextFormField, 'Dune night'), '   ');
    await _tapSubmit(t);
    expect(find.text('Give the party a title'), findsOneWidget);
    expect(server.posts, isEmpty);
  });

  testWidgets("the server's past-time refusal keeps the form as it was", (t) async {
    final server = _Server()
      ..postError = ApiException(message: 'x', statusCode: 400, responseBody: {'success': false, 'message': 'scheduledAt must be in the future'});
    await _pump(t, _app(server));
    await t.enterText(find.widgetWithText(TextFormField, 'Dune night'), 'Spice night');
    await _tapSubmit(t);

    expect(find.text('That time has passed. Pick a later one.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Spice night'), findsOneWidget);
    expect(find.text('party $_party'), findsNothing);
    expect(t.widget<ClButton>(_submit).onPressed, isNotNull, reason: 'can try again');
  });

  testWidgets('a 403 says only members can plan', (t) async {
    final server = _Server()..postError = ApiException(message: 'x', statusCode: 403, responseBody: {'success': false, 'message': 'You must be a member'});
    await _pump(t, _app(server));
    await _tapSubmit(t);
    expect(find.text('Only members of Cinema Sundays can plan its watch parties.'), findsOneWidget);
  });

  testWidgets('a club with no films points to suggesting one', (t) async {
    final server = _Server(films: []);
    await _pump(t, _app(server));
    expect(find.text('Suggest a film first'), findsOneWidget);
    expect(_submit, findsNothing);
    await t.tap(find.widgetWithText(ClButton, 'Suggest a film'));
    await t.pumpAndSettle();
    expect(find.text('suggest page'), findsOneWidget);
  });

  testWidgets('non-members get no form', (t) async {
    await _pump(t, _app(_Server(isMember: false)));
    expect(find.text('Watch parties are planned by members'), findsOneWidget);
    expect(_submit, findsNothing);
  });

  for (final (w, s) in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets('layout at ${w.toInt()}px, ${s}x text: no broken words, gold only on Schedule', (t) async {
      final size = Size(w, 844);
      await _pump(t, _app(_Server(), scale: s, size: size), size: size);
      expect(t.takeException(), isNull);
      expectNoBrokenWords(t);
      expect(goldViolations(t, allowed: [_submit]), isEmpty);
      await t.ensureVisible(_submit);
      await t.pumpAndSettle();
      expectNoBrokenWords(t);
    });
  }
}
