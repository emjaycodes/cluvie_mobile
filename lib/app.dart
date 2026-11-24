import 'package:cluvie_mobile/core/router/routes.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
