import 'dart:async';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/home/data/home_feed.dart';
import 'package:cluvie_mobile/features/notifications/data/notifications.dart';
import 'package:cluvie_mobile/features/notifications/presentation/notification_settings_screen.dart';
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
  bool failReadAll = false;
  bool failPrefs = false;
  final prefs = <String, Object?>{
    'notificationPreferences': {'polls': true, 'discussions': true, 'watchparty': true, 'parties': true},
    'quietHours': {'enabled': false, 'start': '22:00', 'end': '08:00'},
  };
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
      if (path == '/notifications/preferences') return {'success': true, 'data': prefs};
      if (path == '/movies/$_film') return {'_id': _film, 'tmdbId': 666277, 'title': 'Past Lives'};
      if (path == '/polls/$_poll') return {'success': true, 'data': {'_id': _poll, 'community': _club}};
      throw ApiException(message: 'x', statusCode: 404);
    },
    onPatch: (path, data) {
      if (path == '/notifications/read-all') {
        if (failReadAll) throw ApiException(message: 'x', statusCode: 500);
        for (final n in items) {
          n['isRead'] = true;
        }
        return {'success': true};
      }
      if (path == '/notifications/preferences') {
        if (failPrefs) throw ApiException(message: 'x', statusCode: 400, responseBody: {'code': 'INVALID_PREFERENCES'});
        final p = prefs['notificationPreferences'] as Map;
        final q = prefs['quietHours'] as Map;
        (data!['notificationPreferences'] as Map?)?.forEach((k, v) => p[k] = v);
        (data['quietHours'] as Map?)?.forEach((k, v) => q[k] = v);
        return {'success': true, 'data': prefs};
      }
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
    GoRoute(path: '/notifications/settings', builder: (_, __) => const NotificationSettingsScreen()),
    GoRoute(path: '/users/:id', builder: (_, st) => Scaffold(body: Text('user ${st.pathParameters['id']}'))),
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
      expect((targetFor('/users/$_film', me: _me) as DirectTarget).route, '/users/$_film');
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

  test('R10-N5: a failed mark-read does not undo a newer refresh', () async {
    final b = _Backend();
    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(b.api)]);
    addTearDown(container.dispose);
    final sub = container.listen(notificationsProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(notificationsProvider.future);
    final gate = Completer<void>();
    b.api.onPatch = (_, __) async {
      await gate.future;
      throw ApiException(message: 'x', statusCode: 503);
    };
    final marking = container.read(notificationsProvider.notifier).markRead('6e0000000000000000000001');
    // The server marked it read meanwhile, and a refresh brought that in.
    b.items.first['isRead'] = true;
    container.invalidate(notificationsProvider);
    await container.read(notificationsProvider.future);
    gate.complete();
    await marking;
    expect(container.read(notificationsProvider).value!.first.isRead, isTrue);
  });

  test('R12-N1: a notification that arrives during a failed mark-all stays unread', () async {
    final b = _Backend();
    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(b.api)]);
    addTearDown(container.dispose);
    final sub = container.listen(notificationsProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(notificationsProvider.future);
    final gate = Completer<void>();
    b.api.onPatch = (_, __) async {
      await gate.future;
      throw ApiException(message: 'x', statusCode: 503);
    };
    final notifier = container.read(notificationsProvider.notifier);
    final marking = notifier.markAllRead();
    // A fresh notification is pushed in while the request is in flight. The
    // list is currently the optimistic all-read one.
    final arrived = AppNotification.fromJson(
      _n('6e00000000000000000000ff', 'VOTE', 'New vote', 'Fresh', '/movies/$_film'),
    )!;
    // ignore: invalid_use_of_protected_member
    notifier.state = AsyncData([arrived, ...notifier.state.value!]);
    gate.complete();
    await expectLater(marking, throwsA(isA<ApiException>()));
    final list = container.read(notificationsProvider).value!;
    expect(list.first.id, '6e00000000000000000000ff');
    expect(list.first.isRead, isFalse, reason: 'it arrived after the request began');
    for (final id in ['6e0000000000000000000001', '6e0000000000000000000002']) {
      expect(list.firstWhere((n) => n.id == id).isRead, isFalse, reason: 'was unread when the request began');
    }
  });

  test('R12-N1: a failed mark-all keeps what a refresh brought in meanwhile', () async {
    final b = _Backend();
    final container = ProviderContainer(overrides: [apiClientProvider.overrideWithValue(b.api)]);
    addTearDown(container.dispose);
    final sub = container.listen(notificationsProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(notificationsProvider.future);
    final gate = Completer<void>();
    b.api.onPatch = (_, __) async {
      await gate.future;
      throw ApiException(message: 'x', statusCode: 503);
    };
    final notifier = container.read(notificationsProvider.notifier);
    final marking = notifier.markAllRead();
    // A refresh lands while the request is in flight: the server says the
    // first one is read (read on another device), so that answer must stand.
    const readElsewhere = '6e0000000000000000000001';
    // ignore: invalid_use_of_protected_member
    notifier.state = AsyncData([
      for (final n in notifier.state.value!) n.id == readElsewhere ? n.copyWith(isRead: true) : n,
    ]);
    gate.complete();
    await expectLater(marking, throwsA(isA<ApiException>()));
    final list = container.read(notificationsProvider).value!;
    expect(list.firstWhere((n) => n.id == readElsewhere).isRead, isTrue, reason: "the server's answer wins");
    expect(list.firstWhere((n) => n.id == '6e0000000000000000000002').isRead, isFalse, reason: 'our own change is undone');
  });

  test('populated targets open directly, without a lookup', () {
    AppNotification n(Map<String, Object?> extra, [String type = 'VOTE']) =>
        AppNotification.fromJson(_n('6e00000000000000000000aa', type, 't', 'm', '/movies/$_film')..addAll(extra))!;
    expect((targetOf(n({'movie': {'_id': _film, 'tmdbId': 42}})) as DirectTarget).route, '/movie/42');
    expect((targetOf(n({'community': _club}, 'POLL')) as DirectTarget).route, '/communities/$_club/vote');
    expect((targetOf(n({'watchParty': {'_id': _party}}, 'WATCHPARTY')) as DirectTarget).route, '/watch-parties/$_party');
    expect(targetOf(n({})), isA<FilmTarget>(), reason: 'falls back to the link');
  });

  testWidgets('Mark all read marks everything and drops the button; a failure says so', (t) async {
    final b = _Backend();
    await _open(t, b);
    await t.tap(find.byTooltip('Mark all read'));
    await t.pumpAndSettle();
    expect(b.api.calls.where((c) => c.path == '/notifications/read-all'), hasLength(1));
    expect(find.text('New'), findsNothing);
    expect(find.byTooltip('Mark all read'), findsNothing);
  });

  testWidgets('a failed Mark all read puts the unread back', (t) async {
    final b = _Backend()..failReadAll = true;
    await _open(t, b);
    await t.tap(find.byTooltip('Mark all read'));
    await t.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
    expect(find.textContaining("Couldn't mark them read"), findsOneWidget);
  });

  testWidgets('settings: toggles save at once; watch parties sets both backend keys; a refusal flips back', (t) async {
    final b = _Backend();
    await _open(t, b);
    await t.tap(find.byTooltip('Notification settings'));
    await t.pumpAndSettle();
    expect(find.text('Push notifications'), findsOneWidget);
    await t.tap(find.descendant(of: find.ancestor(of: find.text('Watch parties'), matching: find.byType(Row)).first, matching: find.byType(Switch)));
    await t.pumpAndSettle();
    final patch = b.api.calls.lastWhere((c) => c.path == '/notifications/preferences');
    expect(patch.data, {'notificationPreferences': {'watchparty': false, 'parties': false}});
    await t.tap(find.descendant(of: find.ancestor(of: find.text('Quiet hours').last, matching: find.byType(Row)).first, matching: find.byType(Switch)));
    await t.pumpAndSettle();
    expect(find.text('22:00'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    b.failPrefs = true;
    final votes = find.descendant(of: find.ancestor(of: find.text('Votes'), matching: find.byType(Row)).first, matching: find.byType(Switch));
    await t.tap(votes);
    await t.pumpAndSettle();
    expect(t.widget<Switch>(votes).value, isTrue, reason: 'refused: back on');
    expect(find.textContaining("Couldn't save that"), findsOneWidget);
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
