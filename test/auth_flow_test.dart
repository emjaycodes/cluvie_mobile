import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_form_scaffold.dart';
import 'package:cluvie_mobile/features/authentication/data/auth_provider.dart';
import 'package:cluvie_mobile/features/authentication/data/launch_state.dart';
import 'package:cluvie_mobile/features/authentication/presentation/login_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedLaunch extends LaunchState {
  _FixedLaunch(this.dest);
  final LaunchDestination dest;
  @override
  Future<LaunchDestination> resolve() async => dest;
}

GoRouter _router(Widget splash) => GoRouter(initialLocation: '/splash', routes: [
      GoRoute(name: RouteNames.splash, path: '/splash', builder: (_, __) => splash),
      for (final n in [RouteNames.onboarding, RouteNames.welcome, RouteNames.home])
        GoRoute(name: n, path: '/$n', builder: (_, __) => Scaffold(body: Text('at $n'))),
    ]);

void main() {
  group('LaunchState.resolve', () {
    test('first launch → onboarding', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await LaunchState().resolve(), LaunchDestination.onboarding);
    });

    test('onboarding seen, no session → welcome', () async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      expect(await LaunchState().resolve(), LaunchDestination.welcome);
    });

    test('saved session → home', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'abc', 'onboarding_seen': true});
      expect(await LaunchState().resolve(), LaunchDestination.home);
    });

    test('markOnboardingSeen and genres persist', () async {
      SharedPreferences.setMockInitialValues({});
      await LaunchState.markOnboardingSeen();
      await LaunchState.saveFavoriteGenres({'Drama', 'Horror'});
      expect(await LaunchState().resolve(), LaunchDestination.welcome);
      expect(await LaunchState.favoriteGenres(), {'Drama', 'Horror'});
    });
  });

  group('Splash routing', () {
    for (final (dest, name) in [
      (LaunchDestination.onboarding, RouteNames.onboarding),
      (LaunchDestination.welcome, RouteNames.welcome),
      (LaunchDestination.home, RouteNames.home),
    ]) {
      testWidgets('$dest → $name', (t) async {
        await t.pumpWidget(MaterialApp.router(
          theme: AppTheme.theme,
          routerConfig: _router(SplashScreen(launchState: _FixedLaunch(dest))),
        ));
        await t.pump(const Duration(milliseconds: 1200));
        await t.pumpAndSettle();
        expect(find.text('at $name'), findsOneWidget);
      });
    }
  });

  group('friendlyAuthError', () {
    test('network failure', () {
      expect(friendlyAuthError(ApiException(message: 'x'), isLogin: true), contains("Can't reach Cluvie"));
    });
    test('wrong credentials', () {
      expect(friendlyAuthError(ApiException(message: 'x', statusCode: 401), isLogin: true), contains("don't match"));
    });
    test('duplicate account on signup', () {
      expect(friendlyAuthError(ApiException(message: 'x', statusCode: 409), isLogin: false), contains('already exists'));
    });
    test('server error', () {
      expect(friendlyAuthError(ApiException(message: 'x', statusCode: 503), isLogin: true), contains('our side'));
    });
    test('never leaks raw exception text', () {
      final msg = friendlyAuthError(ApiException(message: 'DioException [bad response]', statusCode: 418), isLogin: true);
      expect(msg, isNot(contains('Dio')));
    });
  });

  group('Validators', () {
    test('email', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('ada@'), isNotNull);
      expect(validateEmail(' ada@example.com '), isNull);
    });
    test('password', () {
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });
  });

  group('LoginScreen', () {
    testWidgets('empty submit shows inline errors and never calls the API', (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.theme, home: const LoginScreen()),
      ));
      await t.pumpAndSettle();
      await t.tap(find.text('Log in'));
      await t.pumpAndSettle();
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Use at least 6 characters.'), findsOneWidget);
      expect(container.read(authNotifierProvider).isLoading, isFalse);
    });
  });
}
