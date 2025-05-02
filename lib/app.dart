import 'package:cluvie_mobile/core/router/routes.dart';
import 'package:cluvie_mobile/core/theme/app_theme.dart';
import 'package:cluvie_mobile/features/authentication/presentation/onboarding_screen.dart';
import 'package:cluvie_mobile/features/movies/presentation/movie_list_screen.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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

