import 'package:cluvie_mobile/core/router/routes.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: AppTheme.darkTheme,
  // MovieListScreen
      // home: const OnboardingScreen() ,
      routerConfig: router,
    );
  }

}

