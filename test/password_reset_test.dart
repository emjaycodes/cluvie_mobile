import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/api/api_client_provider.dart';
import 'package:cluvie_mobile/core/errors/api_exceptions.dart';
import 'package:cluvie_mobile/core/router/routes.dart' show resetPasswordRedirect;
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/presentation/forgot_password_screen.dart';
import 'package:cluvie_mobile/features/authentication/presentation/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/design_checks.dart';
import 'helpers/fakes.dart';
import 'helpers/real_fonts.dart';

const _token = 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';

ApiException _error(int? status, [Object? body]) => ApiException(message: 'x', statusCode: status, responseBody: body);

Widget _app(FakeApiClient api, String initial, {Size size = const Size(390, 844), double scale = 1}) {
  final router = GoRouter(initialLocation: initial, routes: [
    GoRoute(path: '/login', name: 'login', builder: (_, __) => const Scaffold(body: Text('login screen'))),
    GoRoute(path: '/forgotPassword', name: 'forgotPassword', builder: (_, __) => const ForgotPasswordScreen(resetAvailable: true)),
    GoRoute(path: '/reset-password', builder: (_, st) => ResetPasswordScreen(token: st.uri.queryParameters['token'])),
  ]);
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(api)],
    child: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
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

Finder _field(String label) => find.ancestor(of: find.text(label), matching: find.byType(ClTextField)).first;

Future<void> _enter(WidgetTester t, String label, String text) async {
  await t.enterText(find.descendant(of: _field(label), matching: find.byType(EditableText)), text);
  await t.pump();
}

Future<void> _press(WidgetTester t, String label) async {
  final f = find.text(label);
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadRealFonts();
    ClPosterImage.debugDisableNetwork = true;
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the emailed link', () {
    test('every platform form lands on /reset-password with the token', () {
      for (final link in [
        'cluvie://reset-password?token=$_token',
        '/?token=$_token',
        '?token=$_token',
      ]) {
        expect(resetPasswordRedirect(Uri.parse(link)), '/reset-password?token=$_token', reason: link);
      }
      expect(resetPasswordRedirect(Uri.parse('cluvie://reset-password')), '/reset-password');
      expect(resetPasswordRedirect(Uri.parse('/reset-password?token=$_token')), isNull); // already there
      expect(resetPasswordRedirect(Uri.parse('/login')), isNull);
      expect(resetPasswordRedirect(Uri.parse('/communities/abc')), isNull);
    });
  });

  group('Forgot password', () {
    testWidgets('sends the trimmed email and never says whether the account exists', (t) async {
      final api = FakeApiClient(onPost: (_, __) => {'success': true});
      await _pump(t, _app(api, '/forgotPassword'));
      await _enter(t, 'Email', '  ada@example.com ');
      await _press(t, 'Send reset link');
      expect(api.calls.single.path, '/auth/forgot-password');
      expect(api.calls.single.data, {'email': 'ada@example.com'});
      expect(find.textContaining('If an account exists for ada@example.com'), findsOneWidget);
    });

    testWidgets('429 says to wait; offline says to check the connection', (t) async {
      final api = FakeApiClient(onPost: (_, __) => throw _error(429));
      await _pump(t, _app(api, '/forgotPassword'));
      await _enter(t, 'Email', 'ada@example.com');
      await _press(t, 'Send reset link');
      expect(find.textContaining('Wait 15 minutes'), findsOneWidget);
      api.onPost = (_, __) => throw _error(null);
      await _press(t, 'Send reset link');
      expect(find.textContaining('Check your connection'), findsOneWidget);
    });
  });

  group('Set a new password', () {
    testWidgets('checks length (8) and match before sending, then signs in fresh', (t) async {
      final api = FakeApiClient(onPost: (_, __) => {'success': true});
      await _pump(t, _app(api, '/reset-password?token=$_token'));
      await _enter(t, 'New password', 'short12');
      await _enter(t, 'Confirm new password', 'short12');
      await _press(t, 'Update password');
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      await _enter(t, 'New password', 'longenough');
      await _enter(t, 'Confirm new password', 'longenougg');
      await _press(t, 'Update password');
      expect(find.text("The passwords don't match."), findsOneWidget);
      expect(api.calls, isEmpty);

      await _enter(t, 'Confirm new password', 'longenough');
      await _press(t, 'Update password');
      expect(api.calls.single.path, '/auth/reset-password');
      expect(api.calls.single.data, {'token': _token, 'password': 'longenough'});
      expect(find.text('Password updated'), findsOneWidget);
      await _press(t, 'Log in');
      expect(find.text('login screen'), findsOneWidget);
    });

    testWidgets('an invalid or used link offers a new one', (t) async {
      final api = FakeApiClient(
        onPost: (_, __) => throw _error(400, {'success': false, 'message': 'Reset link is invalid or has expired', 'code': 'INVALID_RESET_TOKEN'}),
      );
      await _pump(t, _app(api, '/reset-password?token=$_token'));
      await _enter(t, 'New password', 'longenough');
      await _enter(t, 'Confirm new password', 'longenough');
      await _press(t, 'Update password');
      expect(find.text('This link is invalid or expired'), findsOneWidget);
      await _press(t, 'Get a new link');
      expect(find.text('Send reset link'), findsOneWidget);
    });

    testWidgets('a link without a token is invalid at once, without a request', (t) async {
      final api = FakeApiClient();
      await _pump(t, _app(api, '/reset-password'));
      expect(find.text('This link is invalid or expired'), findsOneWidget);
      expect(api.calls, isEmpty);
    });

    testWidgets("another 400 shows the server's message", (t) async {
      final api = FakeApiClient(onPost: (_, __) => throw _error(400, {'message': 'Password must be at least 8 characters'}));
      await _pump(t, _app(api, '/reset-password?token=$_token'));
      await _enter(t, 'New password', 'longenough');
      await _enter(t, 'Confirm new password', 'longenough');
      await _press(t, 'Update password');
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });
  });

  test('a 401 ends the session only on signed-in, session-using routes', () {
    ApiException e(String path, [int status = 401]) => ApiException(message: 'x', statusCode: status, path: path);
    expect(ApiClient.endsSession(e('/auth/me'), signedIn: true), isTrue);
    expect(ApiClient.endsSession(e('/auth/profile'), signedIn: true), isTrue);
    expect(ApiClient.endsSession(e('/communities/joined'), signedIn: true), isTrue);
    for (final p in ['/auth/login', '/auth/register', '/auth/forgot-password', '/auth/reset-password']) {
      expect(ApiClient.endsSession(e(p), signedIn: true), isFalse, reason: p);
    }
    expect(ApiClient.endsSession(e('/auth/me'), signedIn: false), isFalse);
    expect(ApiClient.endsSession(e('/auth/me', 403), signedIn: true), isFalse);
  });

  testWidgets('the real router opens the reset screen from the platform link', (t) async {
    final router = GoRouter(
      initialLocation: '/login',
      redirect: (_, st) => resetPasswordRedirect(st.uri),
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('login screen'))),
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('root'))),
        GoRoute(path: '/reset-password', builder: (_, st) => ResetPasswordScreen(token: st.uri.queryParameters['token'])),
      ],
    );
    await t.pumpWidget(ProviderScope(child: MaterialApp.router(theme: AppTheme.theme, routerConfig: router)));
    await t.pumpAndSettle();
    for (final link in ['cluvie://reset-password?token=$_token', '?token=$_token']) {
      router.go('/login');
      await t.pumpAndSettle();
      final message = const JSONMethodCodec().encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': link, 'state': null}),
      );
      await t.binding.defaultBinaryMessenger.handlePlatformMessage('flutter/navigation', message, (_) {});
      await t.pumpAndSettle();
      final screen = t.widget<ResetPasswordScreen>(find.byType(ResetPasswordScreen));
      expect(screen.token, _token, reason: link);
    }
  });

  test('ApiException.fromDio keeps an already-mapped error (status survives re-wrapping)', () {
    final e = _error(401, {'code': 'SESSION_REVOKED'});
    expect(identical(ApiException.fromDio(e), e), isTrue);
  });

  group('layout and gold', () {
    for (final size in const [Size(320, 568), Size(390, 844)]) {
      for (final scale in const [1.0, 2.0]) {
        for (final (route, gold) in [
          ('/reset-password?token=$_token', 'Update password'),
          ('/reset-password', 'Get a new link'),
          ('/forgotPassword', 'Send reset link'),
        ]) {
          testWidgets('$route ${size.width.toInt()} @${scale}x', (t) async {
            await _pump(t, _app(FakeApiClient(), route, size: size, scale: scale), size: size);
            expect(t.takeException(), isNull);
            expectNoBrokenWords(t);
            expect(goldViolations(t, allowed: [find.ancestor(of: find.text(gold), matching: find.byType(ClButton))]), isEmpty);
          });
        }
      }
    }
  });
}
