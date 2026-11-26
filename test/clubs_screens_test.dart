import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/presentation/club_settings.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_detail_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_info_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/community_list_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/create_community_screen.dart';
import 'package:cluvie_mobile/features/clubs/presentation/widgets/club_tile.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/movies/presentation/vote_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _owned = '64c000000000000000000001'; // I own it
const _member = '64c000000000000000000002'; // I'm a member
const _other = '64c000000000000000000003'; // not mine
const _long = '64c000000000000000000004'; // not mine, long name
const _new = '64c000000000000000000009';

Map<String, Object?> _club(String id, String name, {String owner = 'someone', List<String> members = const [], String? description}) => {
      '_id': id,
      'name': name,
      'description': description ?? 'We watch one film a week and talk about it.',
      'owner': owner,
      'members': [
        {'user': owner, 'role': 'admin'},
        for (final m in members) {'user': m, 'role': 'member'},
      ],
      'admins': const [],
      'movie_suggestions': const ['m1', 'm2'],
      'createdAt': '2026-03-01T10:00:00.000Z',
    };

Map<String, Object?> _poll() => {
      '_id': '650000000000000000000001',
      'question': 'What should we watch on Friday?',
      'expiresAt': DateTime.now().add(const Duration(hours: 20)).toUtc().toIso8601String(),
      'status': 'open',
      'options': [
        for (final (i, t) in ['Past Lives', 'Perfect Days'].indexed)
          {
            '_id': '66000000000000000000000$i',
            'movie': {'_id': '67000000000000000000000$i', 'tmdbId': 100 + i, 'title': t, 'posterPath': '/p.jpg'},
            'votes': i == 0 ? ['u1', 'u2'] : const [],
          },
      ],
    };

/// A backend with state: joining and leaving change what `/joined` returns.
class _Backend {
  _Backend({this.failJoined = false});
  bool failJoined;
  bool failRefetch = false;
  bool failPolls = false;
  final joined = <String>{_owned, _member};
  late final clubs = <String, Map<String, Object?>>{
    _owned: _club(_owned, 'Cinema Sundays', owner: _me, members: ['u2']),
    _member: _club(_member, 'Night Owls', members: [_me, 'u3']),
    _other: _club(_other, 'Noir Nights', members: ['u4']),
    _long: _club(_long, 'The Extraordinarily Long-Named Society of Midnight Cinephiles', members: ['u5'],
        description: 'Overwhelmingly cinematographic discussions about cinematographers and their cinematography.'),
  };

  late final api = FakeApiClient(
    onGet: (path, params) {
      if (path == '/communities/joined') {
        if (failJoined) throw ApiException(message: 'x', statusCode: 500);
        // Like the server: only {user} entries match ('members.user').
        return {
          'success': true,
          'communities': [
            for (final c in clubs.values)
              if ((c['members'] as List).any((m) => m is Map && m['user'] == _me)) c,
          ],
        };
      }
      if (failRefetch) throw ApiException(message: 'x', statusCode: 503);
      if (path == '/communities/all') return {'success': true, 'communities': clubs.values.toList()};
      if (path == '/polls/active' && failPolls) throw ApiException(message: 'x', statusCode: 503);
      if (path == '/polls/active') return {'success': true, 'data': params?['communityId'] == _member ? [_poll()] : []};
      final films = RegExp(r'^/communities/(\w+)/movies$').firstMatch(path);
      if (films != null) {
        return {
          'success': true,
          'data': films.group(1) == _member
              ? [
                  for (var i = 0; i < 3; i++)
                    {'_id': '68000000000000000000000$i', 'tmdbId': 200 + i, 'title': 'Club film $i', 'posterPath': '/p.jpg', 'releaseDate': '2024-01-01'},
                ]
              : [],
        };
      }
      final one = RegExp(r'^/communities/(\w+)$').firstMatch(path);
      if (one != null) {
        final c = clubs[one.group(1)];
        if (c == null) throw ApiException(message: 'x', statusCode: 404);
        return {'success': true, 'data': c};
      }
      throw UnimplementedError(path);
    },
    onPost: (path, data) {
      final m = RegExp(r'^/communities/(\w+)/(join|leave)$').firstMatch(path);
      if (m != null) {
        final id = m.group(1)!;
        if (m.group(2) == 'join') {
          joined.add(id);
          (clubs[id]!['members'] as List).add({'user': _me, 'role': 'member'});
        } else {
          if (clubs[id]!['owner'] == _me) {
            throw ApiException(message: 'x', statusCode: 400, responseBody: {'message': 'Owner cannot leave the community'});
          }
          joined.remove(id);
          (clubs[id]!['members'] as List).removeWhere((e) => (e as Map)['user'] == _me);
        }
        return {'success': true};
      }
      if (path == '/communities') {
        final c = _club(_new, data!['name'] as String, owner: _me, description: data['description'] as String);
        clubs[_new] = c;
        joined.add(_new);
        return {'success': true, 'community': c};
      }
      throw UnimplementedError(path);
    },
  );
}

Map<String, Object?>? _voteExtra;

Widget _app(
  _Backend backend, {
  Future<String?> Function()? me,
  String initial = '/communities',
  Size size = const Size(390, 844),
  double scale = 1,
}) {
  final padding = EdgeInsets.only(top: size.height > 800 ? 47 : 20, bottom: 34);
  final router = GoRouter(initialLocation: initial, routes: [
    ShellRoute(builder: (_, __, child) => ClBottomNavBar(child: child), routes: [
      GoRoute(path: '/communities', builder: (_, __) => const CommunityListScreen()),
      for (final p in ['/home', '/discover', '/suggest', '/profile']) GoRoute(path: p, builder: (_, __) => Text('tab $p')),
    ]),
    GoRoute(path: '/createCommunity', builder: (_, __) => const CreateCommunityScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const Scaffold(body: Text('notifications'))),
    GoRoute(path: '/discussionThread', builder: (_, __) => const Scaffold(body: Text('thread'))),
    GoRoute(
      path: '/communities/:id',
      builder: (_, st) => CommunityDetailScreen(communityId: st.pathParameters['id']!),
      routes: [
        GoRoute(path: 'about', builder: (_, st) => CommunityInfoScreen(communityId: st.pathParameters['id']!)),
        GoRoute(path: 'settings', builder: (_, st) => ClubSettingsScreen(communityId: st.pathParameters['id']!)),
        GoRoute(path: 'suggest', builder: (_, __) => const Scaffold(body: Text('suggest'))),
        GoRoute(path: 'discussion', builder: (_, __) => const Scaffold(body: Text('discussions'))),
        GoRoute(
          path: 'vote',
          builder: (_, st) {
            _voteExtra = st.extra is Map ? Map<String, Object?>.from(st.extra as Map) : null;
            return VoteSummaryScreen(communityId: st.pathParameters['id']!, clubName: _voteExtra?['club'] as String?);
          },
        ),
      ],
    ),
  ]);
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(backend.api),
      currentUserIdProvider.overrideWith((ref) => (me ?? () async => _me)()),
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
  for (var i = 0; i < 30 && f.hitTestable().evaluate().isEmpty; i++) {
    await t.drag(_vertical.first, const Offset(0, -250));
    await t.pumpAndSettle();
  }
}

Finder _button(String label) => find.ancestor(of: find.text(label), matching: find.byType(ClPressable)).first;

Future<void> _tap(WidgetTester t, String label) async {
  await _scrollTo(t, find.text(label));
  await t.tap(_button(label));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
    ClPosterImage.debugDisableNetwork = true;
  });

  group('Clubs tab', () {
    testWidgets('your clubs with roles; other clubs with Join', (t) async {
      final b = _Backend();
      await _pump(t, _app(b));
      expect(find.widgetWithText(SliverAppBar, 'Clubs'), findsOneWidget);
      expect(find.text('Cinema Sundays'), findsOneWidget);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('Night Owls'), findsOneWidget);
      await _scrollTo(t, find.text('Noir Nights'));
      expect(find.text('Join'), findsWidgets);
      // No fake invite-code field.
      expect(find.textContaining('invite code'), findsNothing);
    });

    testWidgets('joining moves the club into Your clubs', (t) async {
      final b = _Backend();
      await _pump(t, _app(b));
      await _scrollTo(t, find.text('Noir Nights'));
      final join = find.descendant(
        of: find.ancestor(of: find.text('Noir Nights'), matching: find.byType(ClubTile)).first,
        matching: find.byType(ClButton),
      );
      await t.tap(join);
      await t.pumpAndSettle();
      expect(b.api.calls.where((c) => c.path == '/communities/$_other/join'), hasLength(1));
      expect(find.text('Welcome to Noir Nights.'), findsOneWidget);
      // Refetched: Noir Nights is now one of yours, so it has no Join button.
      final tile = find.ancestor(of: find.text('Noir Nights'), matching: find.byType(ClubTile)).first;
      expect(find.descendant(of: tile, matching: find.byType(ClButton)), findsNothing);
    });

    testWidgets('search filters both lists; no match offers to create', (t) async {
      final b = _Backend();
      await _pump(t, _app(b));
      await t.enterText(find.byType(TextField), 'noir');
      await t.pumpAndSettle();
      expect(find.text('Noir Nights'), findsOneWidget);
      expect(find.text('Cinema Sundays'), findsNothing);
      expect(find.text('None of your clubs match.'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'zzz');
      await t.pumpAndSettle();
      expect(find.text("No clubs match 'zzz'"), findsOneWidget);
    });

    testWidgets('when your clubs fail to load, other clubs show no Join', (t) async {
      final b = _Backend(failJoined: true);
      await _pump(t, _app(b));
      expect(find.text("Couldn't load your clubs"), findsOneWidget);
      await _scrollTo(t, find.text('Noir Nights'));
      expect(find.text('Join'), findsNothing);
    });
  });

  group('Club detail', () {
    testWidgets('a member sees Suggest and the open vote; Vote passes the club name', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_member'));
      expect(find.text('Night Owls'), findsWidgets);
      expect(find.text('Suggest a film'), findsOneWidget);
      expect(find.text('Join club'), findsNothing);
      await _scrollTo(t, find.text('What should we watch on Friday?'));
      expect(find.text('Past Lives leads · 2 votes'), findsOneWidget);
      await _tap(t, 'Vote');
      expect(_voteExtra, {'club': 'Night Owls'});
      expect(find.text('Night Owls vote'), findsOneWidget);
    });

    testWidgets('a non-member gets one Join action, then Suggest', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_other'));
      expect(find.text('Join club'), findsOneWidget);
      expect(find.text('Suggest a film'), findsNothing);
      await _scrollTo(t, find.text('No vote open'));
      expect(find.text('No films yet'), findsOneWidget);
      await _scrollTo(t, find.text('Join club'));
      await _tap(t, 'Join club');
      expect(b.api.calls.where((c) => c.path == '/communities/$_other/join'), hasLength(1));
      expect(find.text('Suggest a film'), findsOneWidget);
    });

    testWidgets('a demo id says the club does not exist, without a request', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/demo-community'));
      expect(find.text("This club doesn't exist"), findsOneWidget);
      expect(b.api.calls.where((c) => c.path.startsWith('/communities/demo')), isEmpty);
    });

    testWidgets('the menu opens About and Membership', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_member'));
      await t.tap(find.byTooltip('Club menu'));
      await t.pumpAndSettle();
      await t.tap(_button('About this club'));
      await t.pumpAndSettle();
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
    });
  });

  group('Membership', () {
    testWidgets('the owner cannot leave, and is told so up front', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_owned/settings'));
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text("You started this club, so you can't leave it."), findsOneWidget);
      final leave = t.widget<ClButton>(find.ancestor(of: find.text('Leave club'), matching: find.byType(ClButton)));
      expect(leave.onPressed, isNull);
    });

    testWidgets('a member leaves after confirming, and lands on Clubs', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_member/settings'));
      expect(find.text('Member'), findsOneWidget);
      await _tap(t, 'Leave club');
      expect(find.text('Leave Night Owls?'), findsOneWidget);
      expect(b.api.calls.where((c) => c.method == 'POST'), isEmpty);
      await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Leave club')));
      await t.pumpAndSettle();
      expect(b.api.calls.where((c) => c.path == '/communities/$_member/leave'), hasLength(1));
      expect(find.text('You left Night Owls.'), findsOneWidget);
      expect(find.byType(CommunityListScreen), findsOneWidget);
    });
  });

  group('Create club', () {
    testWidgets('the description is required (the backend rejects a blank one)', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/createCommunity'));
      await t.enterText(find.byType(TextFormField).first, 'Noir Club');
      await _tap(t, 'Create club');
      expect(find.text('Say what the club is about'), findsOneWidget);
      expect(b.api.calls.where((c) => c.method == 'POST'), isEmpty);
    });

    testWidgets('creating lands on the new club', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/createCommunity'));
      await t.enterText(find.byType(TextFormField).first, '  Noir Club ');
      await t.enterText(find.byType(TextFormField).last, 'Black and white only');
      await _tap(t, 'Create club');
      expect(b.api.calls.firstWhere((c) => c.method == 'POST').data, {'name': 'Noir Club', 'description': 'Black and white only'});
      expect(find.text('Suggest a film'), findsOneWidget);
      expect(find.text('Noir Club'), findsWidgets);
    });
  });

  group('Vote (R8-N3)', () {
    testWidgets('a non-member sees one Join card instead of Vote buttons', (t) async {
      final b = _Backend()..clubs[_other] = _club(_other, 'Noir Nights');
      // Give the non-member club an open poll.
      final api = b.api;
      final get = api.onGet!;
      api.onGet = (path, params) => path == '/polls/active' ? {'success': true, 'data': [_poll()]} : get(path, params);
      await _pump(t, _app(b, initial: '/communities/$_other/vote'));
      expect(find.text('Join this club to vote'), findsOneWidget);
      expect(find.text('Only club members can vote.'), findsOneWidget);
      expect(find.text('Vote'), findsNothing);
      await _tap(t, 'Join club');
      expect(find.text('Join this club to vote'), findsNothing);
      expect(find.text('Vote'), findsWidgets);
    });
  });

  group('Round 9 fixes', () {
    testWidgets('R9-S1: a raw-id member, missed by /joined, is a member everywhere', (t) async {
      final b = _Backend();
      b.clubs[_other] = {..._club(_other, 'Noir Nights'), 'members': [{'user': 'someone', 'role': 'admin'}, _me]};
      await _pump(t, _app(b));
      // Listed under Your clubs (no Join), not under Find a club.
      final tile = find.ancestor(of: find.text('Noir Nights'), matching: find.byType(ClubTile)).first;
      expect(find.descendant(of: tile, matching: find.byType(ClButton)), findsNothing);

      final get = b.api.onGet!;
      b.api.onGet = (path, params) => path == '/polls/active' ? {'success': true, 'data': [_poll()]} : get(path, params);
      await t.pumpWidget(const SizedBox());
      await _pump(t, _app(b, initial: '/communities/$_other/vote'));
      expect(find.text('Join this club to vote'), findsNothing);
      expect(find.text('Vote'), findsWidgets);
    });

    testWidgets('R9-S3: a join whose refetch fails still shows you as joined, once', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_other'));
      b.failRefetch = true;
      await t.tap(_button('Join club'));
      await t.pumpAndSettle();
      expect(b.api.calls.where((c) => c.path == '/communities/$_other/join'), hasLength(1));
      expect(find.text("You joined Noir Nights. Couldn't refresh the club yet."), findsOneWidget);
      expect(find.text('Join club'), findsNothing);
      expect(find.text('Suggest a film'), findsOneWidget);
    });

    testWidgets('R9-S2: Membership waits for your id; never guesses Member', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_owned/settings', me: () async => null));
      expect(find.text('Member'), findsNothing);
      expect(find.text('Leave club'), findsNothing);
      expect(find.text("Couldn't check your membership"), findsOneWidget);
    });

    testWidgets('R9-S4: a detail refresh where the vote fails keeps it and says so', (t) async {
      final b = _Backend();
      await _pump(t, _app(b, initial: '/communities/$_member'));
      b.failPolls = true;
      await t.fling(_vertical.first, const Offset(0, 400), 1000);
      await t.pumpAndSettle();
      expect(find.text('What should we watch on Friday?'), findsOneWidget);
      expect(find.text("Couldn't refresh. Showing earlier details."), findsOneWidget);
    });

    testWidgets('R9-N8: the owner sees their role on the club page', (t) async {
      await _pump(t, _app(_Backend(), initial: '/communities/$_owned'));
      expect(find.text('You run this club'), findsOneWidget);
    });
  });

  group('Layout and gold budget', () {
    final screens = <String, (String, List<String>)>{
      'list': ('/communities', const []),
      'detail (member)': ('/communities/$_member', const ['Suggest a film']),
      'detail (non-member, long name)': ('/communities/$_long', const ['Join club']),
      'about': ('/communities/$_long/about', const ['Join club']),
      'membership (owner)': ('/communities/$_owned/settings', const []),
      'membership (member)': ('/communities/$_member/settings', const []),
      'create': ('/createCommunity', const ['Create club']),
    };
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final MapEntry(key: name, value: (route, gold)) in screens.entries) {
          testWidgets('$name ${size.width.toInt()}x${size.height.toInt()} @${scale}x: no overflow, broken words or stray gold', (t) async {
            await _pump(t, _app(_Backend(), initial: route, size: size, scale: scale), size: size);
            final allowed = [for (final g in gold) find.ancestor(of: find.text(g), matching: find.byType(ClButton))];
            for (var i = 0; i < 10; i++) {
              expect(t.takeException(), isNull);
              expectNoBrokenWords(t);
              expect(goldViolations(t, allowed: allowed), isEmpty);
              if (_vertical.evaluate().isEmpty) break;
              await t.drag(_vertical.first, const Offset(0, -300));
              await t.pumpAndSettle();
            }
            expect(t.takeException(), isNull);
          });
        }
      }
    }
  });
}
