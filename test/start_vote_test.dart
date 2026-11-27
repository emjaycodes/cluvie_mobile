import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/movies/presentation/start_vote_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _club = '64c000000000000000000001';
String _mid(int i) => '64d${i.toRadixString(16).padLeft(21, '0')}';
const _titles = ['Dune', 'Heat', 'Alien', 'Arrival', 'Brazil', 'Contact', 'Drive', 'Fargo', 'Gattaca', 'Hereditary', 'Inception', 'Jaws'];

Map<String, Object?> _film(int i) =>
    {'_id': _mid(i), 'tmdbId': 1000 + i, 'id': 1000 + i, 'title': _titles[i], 'release_date': '2001-01-01'};

class _Server {
  _Server({this.isMember = true, int films = 4}) : films = [for (var i = 0; i < films; i++) _film(i)];
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
      if (path != '/polls/create') throw UnimplementedError(path);
      posts.add(data!);
      if (postError != null) throw postError!;
      return {'success': true, 'data': {'_id': '64f000000000000000000001'}};
    },
  );
}

Widget _app(_Server server, {double scale = 1, Size size = const Size(390, 1800)}) {
  final router = GoRouter(initialLocation: '/communities/$_club/vote/new', routes: [
    GoRoute(path: '/communities/:id', builder: (_, st) => Text('club ${st.pathParameters['id']}'), routes: [
      GoRoute(path: 'vote/new', builder: (_, st) => StartVoteScreen(communityId: st.pathParameters['id']!)),
      GoRoute(path: 'vote', builder: (_, st) => Text('vote page ${(st.extra as Map?)?['club']}')),
      GoRoute(path: 'suggest', builder: (_, __) => const Text('suggest page')),
    ]),
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

Future<void> _pump(WidgetTester t, Widget app, {Size size = const Size(390, 1800)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(app);
  await t.pumpAndSettle();
}

Finder get _submit => find.widgetWithText(ClButton, 'Start the vote');

final _page = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

Future<void> _reveal(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) await t.scrollUntilVisible(f, 200, scrollable: _page);
  await t.ensureVisible(f);
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await _reveal(t, f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async => loadRealFonts());

  testWidgets('starts with the first three films picked; sends catalog ids, question, 2 days, single choice', (t) async {
    final server = _Server();
    await _pump(t, _app(server));
    expect(find.text('3 picked · pick 2 to 10'), findsOneWidget);

    final before = DateTime.now();
    await _tap(t, _submit);

    final body = server.posts.single;
    expect(body['communityId'], _club);
    expect(body['question'], 'What should we watch next?');
    expect(body['options'], [_mid(0), _mid(1), _mid(2)]);
    expect(body['allowMultiple'], false);
    final ends = DateTime.parse(body['expiresAt'] as String);
    expect(ends.isUtc, isTrue);
    expect(ends.difference(before).inMinutes, closeTo(48 * 60, 1));
    expect(find.text('vote page Cinema Sundays'), findsOneWidget);
  });

  testWidgets('toggling films, duration and multiple choice', (t) async {
    final server = _Server();
    await _pump(t, _app(server));
    await _tap(t, find.text('Dune'));
    await _tap(t, find.text('Arrival'));
    expect(find.text('3 picked · pick 2 to 10'), findsOneWidget);
    await _tap(t, find.widgetWithText(ClChip, '1 week'));
    await _tap(t, find.byType(Switch));
    await t.enterText(find.byType(TextFormField), '  Friday pick?  ');
    final before = DateTime.now();
    await _tap(t, _submit);

    final body = server.posts.single;
    expect(body['options'], [_mid(1), _mid(2), _mid(3)]);
    expect(body['question'], 'Friday pick?');
    expect(body['allowMultiple'], true);
    expect(DateTime.parse(body['expiresAt'] as String).difference(before).inHours, closeTo(7 * 24, 1));
  });

  testWidgets('fewer than two picks, or an empty question, sends nothing', (t) async {
    final server = _Server();
    await _pump(t, _app(server));
    await _tap(t, find.text('Dune'));
    await _tap(t, find.text('Heat'));
    await _tap(t, _submit);
    expect(find.text('Pick at least 2 films.'), findsOneWidget);

    await _tap(t, find.text('Heat'));
    await t.enterText(find.byType(TextFormField), ' ');
    await _tap(t, _submit);
    expect(find.text('Ask the club something'), findsOneWidget);
    expect(server.posts, isEmpty);
  });

  testWidgets('at most ten films', (t) async {
    final server = _Server(films: 12);
    await _pump(t, _app(server));
    for (var i = 3; i < 10; i++) {
      await _tap(t, find.text(_titles[i]));
    }
    expect(find.text('10 picked · pick 2 to 10'), findsOneWidget);
    await _tap(t, find.text(_titles[10]));
    expect(find.text('A vote can have at most 10 films.'), findsOneWidget);
    expect(find.text('10 picked · pick 2 to 10'), findsOneWidget);
  });

  testWidgets('a 403 says only members can start votes, and the form stays', (t) async {
    final server = _Server()..postError = ApiException(message: 'x', statusCode: 403, responseBody: {'message': 'You must be a member'});
    await _pump(t, _app(server));
    await _tap(t, _submit);
    expect(find.text('Only members of Cinema Sundays can start its votes.'), findsOneWidget);
    expect(t.widget<ClButton>(_submit).onPressed, isNotNull);
  });

  testWidgets('a club with one film points to suggesting another', (t) async {
    await _pump(t, _app(_Server(films: 1)));
    expect(find.text('A vote needs two films'), findsOneWidget);
    expect(_submit, findsNothing);
    await _tap(t, find.widgetWithText(ClButton, 'Suggest a film'));
    expect(find.text('suggest page'), findsOneWidget);
  });

  testWidgets('non-members get no form', (t) async {
    await _pump(t, _app(_Server(isMember: false)));
    expect(find.text('Votes are started by members'), findsOneWidget);
    expect(_submit, findsNothing);
  });

  for (final (w, s) in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets('layout at ${w.toInt()}px, ${s}x text: no broken words, gold only on Start', (t) async {
      final size = Size(w, 844);
      await _pump(t, _app(_Server(), scale: s, size: size), size: size);
      expect(t.takeException(), isNull);
      expectNoBrokenWords(t);
      expect(goldViolations(t, allowed: [_submit]), isEmpty);
      await _reveal(t, _submit);
      await t.pumpAndSettle();
      expectNoBrokenWords(t);
      expect(goldViolations(t, allowed: [_submit]), isEmpty);
    });
  }
}
