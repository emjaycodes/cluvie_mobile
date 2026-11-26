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
  Future<void> _sessionEnded(Object error) async {
    if (_endingSession) return;
    _endingSession = true;
    try {
      await ref.read(authNotifierProvider.notifier).logout();
      clearUserState(ref.invalidate);
      router.goNamed(RouteNames.login);
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ClSnackbar.show(context, message: 'You were signed out. Log in again to continue.', type: ClSnackbarType.warning);
      }
    } finally {
      _endingSession = false;
    }
  }

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
