import 'package:cluvie_mobile/core/api/api_client.dart';
import 'package:cluvie_mobile/core/router/routes.dart';
import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/data/auth_provider.dart';
import 'package:cluvie_mobile/features/authentication/data/sign_out.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _endingSession = false;

  @override
  void initState() {
    super.initState();
    ApiClient.onSessionEnded = _sessionEnded;
  }

  @override
  void dispose() {
    ApiClient.onSessionEnded = null;
    super.dispose();
  }

  /// A signed-in request got 401: sign out once, open Log in, say why.
  Future<void> _sessionEnded(Object error) => endSessionOnce(
        isEnding: () => _endingSession,
        setEnding: (v) => _endingSession = v,
        // Navigate first, so mounted tabs aren't refetching while the
        // session is cleared (R10-N7).
        goToLogin: () => router.goNamed(RouteNames.login),
        signOut: () async {
          await ref.read(authNotifierProvider.notifier).logout();
          clearUserState(ref.invalidate);
        },
        tellUser: () {
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            ClSnackbar.show(context, message: 'You were signed out. Log in again to continue.', type: ClSnackbarType.warning);
          }
        },
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cluvie',
      theme: AppTheme.theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Nav bar, frosted app bars and the composer share one backdrop pass.
      builder: (context, child) => BackdropGroup(child: child!),
    );
  }
}

/// Ends the session at most once at a time: concurrent 401s sign out once
/// and show one message. Errors in signing out are swallowed (the user is
/// on Log in either way).
Future<void> endSessionOnce({
  required bool Function() isEnding,
  required void Function(bool) setEnding,
  required void Function() goToLogin,
  required Future<void> Function() signOut,
  required void Function() tellUser,
}) async {
  if (isEnding()) return;
  setEnding(true);
  try {
    goToLogin();
    await signOut();
    tellUser();
  } catch (_) {
    // Already on Log in; nothing more to do.
  } finally {
    setEnding(false);
  }
}
