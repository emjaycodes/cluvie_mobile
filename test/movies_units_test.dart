import 'dart:convert';

import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/repository/auth_repository.dart';
import 'package:cluvie_mobile/core/router/routes.dart' as app_routes;
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/core/utils/fit_text.dart';
import 'package:cluvie_mobile/core/utils/relative_time.dart';
import 'package:cluvie_mobile/features/authentication/data/current_user.dart';
import 'package:cluvie_mobile/features/clubs/data/comunity_provider.dart';
import 'package:cluvie_mobile/features/movies/presentation/club_discussions_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_details_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/vote_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _club = '64c000000000000000000001';

String _jwt(Object payload) {
  String seg(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${seg({'alg': 'HS256', 'typ': 'JWT'})}.${seg(payload)}.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepository.savedUserId', () {
    Future<String?> idFor(String? token) async {
      SharedPreferences.setMockInitialValues({if (token != null) 'auth_token': token});
      return AuthRepository().savedUserId();
    }

    test('reads the id from a valid token', () async {
      expect(await idFor(_jwt({'id': '64b000000000000000000001', 'iat': 1})), '64b000000000000000000001');
    });

    test('null for no token, a malformed token, or no id', () async {
      expect(await idFor(null), isNull);
      expect(await idFor('not-a-jwt'), isNull);
      expect(await idFor('a.%%%.c'), isNull);
      expect(await idFor(_jwt({'sub': 'x'})), isNull);
      expect(await idFor(_jwt({'id': ''})), isNull);
      expect(await idFor(_jwt(['id'])), isNull);
    });

    test('currentUserIdProvider falls back to the saved token after a cold start', () async {
      SharedPreferences.setMockInitialValues({'auth_token': _jwt({'id': 'u-cold'})});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(await container.read(currentUserIdProvider.future), 'u-cold');
    });
  });

  group('relative time', () {
    final now = DateTime(2026, 11, 26, 14, 0);

    test('timeLeft', () {
      expect(timeLeft(now.add(const Duration(days: 2, hours: 4, minutes: 9)), now: now), '2d 4h');
      expect(timeLeft(now.add(const Duration(days: 1)), now: now), '1d');
      expect(timeLeft(now.add(const Duration(hours: 5, minutes: 12)), now: now), '5h 12m');
      expect(timeLeft(now.add(const Duration(hours: 3)), now: now), '3h');
      expect(timeLeft(now.add(const Duration(minutes: 12)), now: now), '12m');
      expect(timeLeft(now.add(const Duration(seconds: 30)), now: now), 'under a minute');
      expect(timeLeft(now, now: now), isNull);
      expect(timeLeft(now.subtract(const Duration(minutes: 1)), now: now), isNull);
    });

    test('dayAndTime: today, tomorrow, later; 24h or 12h', () {
      expect(dayAndTime(DateTime(2026, 11, 26, 20, 0), now: now), 'today at 20:00');
      expect(dayAndTime(DateTime(2026, 11, 27, 9, 30), now: now), 'tomorrow at 09:30');
      expect(dayAndTime(DateTime(2026, 11, 27, 9, 30), now: now, use24h: false), 'tomorrow at 9:30\u202fAM');
      expect(dayAndTime(DateTime(2026, 11, 28, 20, 0), now: now), 'Sat 28 Nov at 20:00');
      // Late tonight to just after midnight is still "tomorrow".
      expect(dayAndTime(DateTime(2026, 11, 27, 0, 5), now: DateTime(2026, 11, 26, 23, 50)), 'tomorrow at 00:05');
    });

    test('dayAndTime counts calendar days, not 24h spans (DST-safe)', () {
      // Across the EU spring-forward night the local midnights are 23h apart;
      // inDays on local DateTimes gave 0 ("today"). Calendar days must give 1.
      expect(dayAndTime(DateTime(2026, 3, 29, 20, 0), now: DateTime(2026, 3, 28, 21, 0)), 'tomorrow at 20:00');
      expect(dayAndTime(DateTime(2026, 10, 26, 8, 0), now: DateTime(2026, 10, 25, 1, 0)), 'tomorrow at 08:00');
    });
  });

  group('styleThatFits', () {
    setUpAll(loadRealFonts);
    const styles = [AppTextStyles.h1, AppTextStyles.h3, AppTextStyles.bodySm];

    test('keeps the largest style when every word fits', () {
      expect(styleThatFits('Past Lives', styles, maxWidth: 320, textScaler: TextScaler.noScaling), AppTextStyles.h1);
    });

    test('steps down until the longest word fits', () {
      final s = styleThatFits('Assassination', styles, maxWidth: 200, textScaler: const TextScaler.linear(2));
      expect(styles.indexOf(s), greaterThan(0));
      final tp = TextPainter(
        text: TextSpan(text: 'Assassination', style: s),
        textScaler: const TextScaler.linear(2),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(tp.width, lessThanOrEqualTo(200));
      tp.dispose();
    });

    test('falls back to the last style when nothing fits', () {
      expect(styleThatFits('Supercalifragilistic', styles, maxWidth: 10, textScaler: TextScaler.noScaling), AppTextStyles.bodySm);
    });
  });

  group("the app's real routes", () {
    setUpAll(() async {
      ClPosterImage.debugDisableNetwork = true;
      await loadRealFonts();
    });

    Future<void> open(WidgetTester t, String location, {Object? extra}) async {
      SharedPreferences.setMockInitialValues({});
      final api = FakeApiClient(onGet: (path, _) {
        if (path == '/tmdb/376867') return {'success': true, 'data': {'id': 376867, 'title': 'Moonlight'}};
        if (path == '/movies/list') return <Object>[];
        if (path == '/polls/active') return {'success': true, 'data': <Object>[]};
        if (path == '/communities/$_club/movies') return {'success': true, 'data': <Object>[]};
        return {'success': true, 'data': <Object>[]};
      });
      // Navigate before the first frame so the splash (and its launch timer)
      // never builds.
      app_routes.router.go(location, extra: extra);
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          currentUserIdProvider.overrideWith((ref) async => 'me'),
          joinedCommunitiesProvider.overrideWith(() => FakeJoinedCommunities(() => [fakeClub(_club, 'Cinema Sundays')])),
        ],
        child: MaterialApp.router(theme: AppTheme.theme, routerConfig: app_routes.router),
      ));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('/movie/:id opens Movie Detail for that TMDB id', (t) async {
      await open(t, '/movie/376867');
      expect(t.widget<MovieDetailScreen>(find.byType(MovieDetailScreen)).movieId, '376867');
      expect(find.text('Moonlight'), findsWidgets);
    });

    testWidgets('/communities/:id/vote opens Vote with the club name from extra', (t) async {
      await open(t, '/communities/$_club/vote', extra: {'club': 'Cinema Sundays'});
      final screen = t.widget<VoteSummaryScreen>(find.byType(VoteSummaryScreen));
      expect(screen.communityId, _club);
      expect(screen.clubName, 'Cinema Sundays');
    });

    testWidgets('/communities/:id/discussion opens the club discussions', (t) async {
      await open(t, '/communities/$_club/discussion');
      expect(t.widget<ClubDiscussionsScreen>(find.byType(ClubDiscussionsScreen)).communityId, _club);
    });
  });
}
