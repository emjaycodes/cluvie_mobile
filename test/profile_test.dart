import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/user_profile/data/profile.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/edit_profile_screen.dart';
import 'package:cluvie_mobile/features/user_profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _me = '64b000000000000000000001';
const _other = '64b0000000000000000000ff';

Map<String, Object?> _film(String id, int tmdb, String title) =>
    {'_id': id, 'tmdbId': tmdb, 'title': title, 'posterPath': '/p.jpg', 'releaseDate': '2023-06-02'};

class _Backend {
  bool failRemove = false;
  bool failFollow = false;
  bool cannotFollowSelf = false;
  bool usernameTaken = false;
  bool failSave = false;

  String username = 'cinephile_supreme_2026';
  String bio = '';
  String? avatarUrl;

  bool isFollowing = false;
  int publicFollowers = 2;

  final watchlist = [
    _film('68000000000000000000000a', 666277, 'Past Lives'),
    _film('68000000000000000000000b', 872585, 'Oppenheimer'),
    _film('68000000000000000000000c', 545611, 'Everything Everywhere All at Once: The Extraordinarily Long Cut'),
  ];

  Map<String, Object?> get _meJson => {
        '_id': _me,
        'username': username,
        'email': 'ada.lovelace.longname@example.com',
        'role': 'user',
        'xp': 1240,
        'suggestedMovies': [{}, {}, {}],
        'votedMovies': [{}],
        'comments': const [],
        'followers': ['a', 'b'],
        'following': ['c'],
        'bio': bio,
        'avatarUrl': avatarUrl,
      };

  Map<String, Object?> get _otherJson => {
        'success': true,
        'data': {
          '_id': _other,
          'username': 'ada_lovelace',
          'bio': 'Watches three films a day and writes about every one.',
          'avatarUrl': null,
          'xp': 320,
          'joinedAt': '2024-03-12T10:00:00.000Z',
          'counts': {'followers': publicFollowers, 'following': 3, 'suggestions': 4, 'clubs': 5},
          'isFollowing': isFollowing,
          'isMe': false,
        },
      };

  late final api = FakeApiClient(
    onGet: (path, _) {
      if (path == '/users/me') return _meJson;
      if (path == '/watchlist') return List.of(watchlist);
      if (path == '/users/$_other') return _otherJson;
      if (path.startsWith('/users/')) {
        throw ApiException(message: 'User not found', statusCode: 404, responseBody: const {'code': 'USER_NOT_FOUND'});
      }
      throw UnimplementedError(path);
    },
    onPost: (path, data) {
      if (path == '/watchlist/remove') {
        if (failRemove) throw ApiException(message: 'x', statusCode: 500);
        watchlist.removeWhere((f) => f['_id'] == data!['movieId']);
      } else if (path == '/watchlist/add') {
        watchlist.insert(0, _film(data!['movieId'] as String, 1, 'restored'));
      } else if (path == '/users/$_other/follow') {
        if (failFollow) throw ApiException(message: 'x', statusCode: 500);
        if (cannotFollowSelf) {
          throw ApiException(
            message: "You can't follow yourself",
            statusCode: 400,
            responseBody: const {'code': 'CANNOT_FOLLOW_SELF'},
          );
        }
        isFollowing = true;
        publicFollowers++;
      } else if (path == '/users/$_other/unfollow') {
        if (failFollow) throw ApiException(message: 'x', statusCode: 500);
        isFollowing = false;
        publicFollowers--;
      }
      return {'success': true};
    },
    onPatch: (path, data) {
      if (path != '/users/me') throw UnimplementedError(path);
      if (failSave) throw ApiException(message: 'x', statusCode: 500);
      if (usernameTaken) {
        throw ApiException(
          message: 'Username is taken',
          statusCode: 409,
          responseBody: const {'code': 'USERNAME_TAKEN'},
        );
      }
      final nextName = data?['username'];
      if (nextName is String) username = nextName.trim();
      final nextBio = data?['bio'];
      if (nextBio is String) bio = nextBio.trim();
      if (data != null && data.containsKey('avatarUrl')) {
        final nextAvatar = data['avatarUrl'];
        avatarUrl = nextAvatar is String && nextAvatar.isNotEmpty ? nextAvatar : null;
      }
      return {'success': true, 'data': _meJson};
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
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
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

Finder _field(int index) => find.byType(TextFormField).at(index);

Finder _button(String label) => find.ancestor(of: find.text(label), matching: find.byType(ClPressable)).first;

Future<void> _tapButton(WidgetTester t, String label) async {
  await t.tap(_button(label));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
    ClPosterImage.debugDisableNetwork = true;
  });

  testWidgets('shows who you are and your real counts; Edit opens the form', (t) async {
    await _pump(t, _app(_Backend()));
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('1240'), findsOneWidget);
    expect(find.text('Films suggested'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
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

  test('R10-N6: a failed remove brings back only that film', () async {
    final b = _Backend();
    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(b.api)]);
    addTearDown(container.dispose);
    final sub = container.listen(watchlistProvider, (_, __) {});
    addTearDown(sub.close);
    final films = await container.read(watchlistProvider.future);
    final gate = Completer<void>();
    b.api.onPost = (path, data) async {
      if (data!['movieId'] == films[0].movieId) {
        await gate.future;
        throw ApiException(message: 'x', statusCode: 500);
      }
      return {'success': true};
    };
    final n = container.read(watchlistProvider.notifier);
    final first = n.remove(films[0]).catchError((_) {});
    await n.remove(films[1]);
    gate.complete();
    await first;
    final ids = container.read(watchlistProvider).value!.map((f) => f.movieId);
    expect(ids, contains(films[0].movieId));
    expect(ids, isNot(contains(films[1].movieId)));
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

  testWidgets('another member shows bio, joined date and counts; Follow is optimistic', (t) async {
    final semantics = t.ensureSemantics();
    try {
      final b = _Backend();
      final gate = Completer<void>();
      final post = b.api.onPost!;
      b.api.onPost = (path, data) async {
        if (path == '/users/$_other/follow') await gate.future;
        return post(path, data);
      };

      await _pump(t, _app(b, initial: '/users/$_other'));
      expect(find.text('ada_lovelace'), findsOneWidget);
      expect(find.text('Watches three films a day and writes about every one.'), findsOneWidget);
      expect(find.text('Joined March 2024'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Followers: 2')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Following: 3')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Films suggested: 4')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Clubs: 5')), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);

      await t.tap(_button('Follow'));
      await t.pump();
      // The count and the follow state move before the server answers.
      expect(find.bySemanticsLabel(RegExp('Followers: 3')), findsOneWidget);

      gate.complete();
      await t.pumpAndSettle();
      // The button label, not the "Following" stat card label.
      expect(find.descendant(of: find.byType(ClButton), matching: find.text('Following')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Followers: 3')), findsOneWidget);
      expect(b.api.calls.any((c) => c.method == 'POST' && c.path == '/users/$_other/follow'), isTrue);
      expect(b.isFollowing, isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('a failed follow rolls back and shows an error', (t) async {
    final semantics = t.ensureSemantics();
    try {
      final b = _Backend()..failFollow = true;
      await _pump(t, _app(b, initial: '/users/$_other'));
      await _tapButton(t, 'Follow');
      expect(find.text('Follow'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Followers: 2')), findsOneWidget);
      expect(find.text("Couldn't follow. Try again."), findsOneWidget);
      expect(b.isFollowing, isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('CANNOT_FOLLOW_SELF is a quiet no-op', (t) async {
    final b = _Backend()..cannotFollowSelf = true;
    await _pump(t, _app(b, initial: '/users/$_other'));
    await _tapButton(t, 'Follow');
    expect(t.takeException(), isNull);
    expect(find.text('Follow'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a 404 profile says it is not available', (t) async {
    await _pump(t, _app(_Backend(), initial: '/users/64b0000000000000000000ee'));
    expect(find.text("This profile isn't available."), findsOneWidget);
    expect(find.text('Go home'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('profile load failure offers retry', (t) async {
    final b = _Backend();
    final get = b.api.onGet!;
    b.api.onGet = (p, q) => p == '/users/me' ? throw ApiException(message: 'x', statusCode: 500) : get(p, q);
    await _pump(t, _app(b));
    expect(find.text("Couldn't load your profile"), findsOneWidget);
  });

  group('edit profile', () {
    ClButton saveButton(WidgetTester t) =>
        t.widget<ClButton>(find.byWidgetPredicate((w) => w is ClButton && w.label == 'Save'));

    testWidgets('a short username blocks saving', (t) async {
      await _pump(t, _app(_Backend(), initial: '/profile/edit'));
      await t.enterText(_field(0), 'ab');
      await t.pump();
      expect(find.text('Username must be 3–30 letters, numbers, _ or .'), findsOneWidget);
      expect(saveButton(t).onPressed, isNull);
    });

    testWidgets('a bio over 160 blocks saving', (t) async {
      await _pump(t, _app(_Backend(), initial: '/profile/edit'));
      await t.enterText(_field(1), 'a' * 161);
      await t.pump();
      expect(find.textContaining('Use 160 characters or fewer'), findsOneWidget);
      expect(saveButton(t).onPressed, isNull);
    });

    testWidgets('a non-https avatar URL blocks saving', (t) async {
      await _pump(t, _app(_Backend(), initial: '/profile/edit'));
      await t.enterText(_field(2), 'http://example.com/me.jpg');
      await t.pump();
      expect(find.text('Avatar URL must start with https://'), findsOneWidget);
      expect(saveButton(t).onPressed, isNull);
    });

    testWidgets('a taken username is shown on the username field', (t) async {
      final b = _Backend()..usernameTaken = true;
      await _pump(t, _app(b, initial: '/profile/edit'));
      await t.enterText(_field(0), 'ada_films');
      await t.pump();
      expect(saveButton(t).onPressed, isNotNull);
      await _tapButton(t, 'Save');
      expect(find.text('That username is taken. Try another.'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(b.username, 'cinephile_supreme_2026');
    });

    testWidgets('saving updates the header after it pops', (t) async {
      final b = _Backend();
      await _pump(t, _app(b));
      await _tapButton(t, 'Edit profile');
      expect(find.text('Username'), findsOneWidget);
      await t.enterText(_field(0), 'ada_films');
      await t.enterText(_field(1), 'Watches films, writes notes.');
      await t.pump();
      await _tapButton(t, 'Save');
      expect(find.text('Profile updated.'), findsOneWidget);
      expect(find.text('ada_films'), findsOneWidget);
      expect(find.text('Watches films, writes notes.'), findsOneWidget);
      expect(b.username, 'ada_films');
      expect(b.bio, 'Watches films, writes notes.');
    });
  });

  group('layout and gold', () {
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final route in ['/profile', '/users/$_other', '/profile/edit']) {
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
