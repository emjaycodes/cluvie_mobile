// ignore_for_file: use_build_context_synchronously

import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/widgets.dart';
import 'package:cluvie_mobile/features/authentication/components/auth_backdrop.dart';
import 'package:cluvie_mobile/features/authentication/data/launch_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Logo reveal while the launch gate resolves (session / first run).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.launchState});

  /// Injectable for tests.
  final LaunchState? launchState;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // Let the reveal play; resolve the gate in parallel.
    final results = await Future.wait([
      (widget.launchState ?? LaunchState()).resolve(),
      Future<void>.delayed(const Duration(milliseconds: 1100)),
    ]);
    if (!mounted) return;
    switch (results.first as LaunchDestination) {
      case LaunchDestination.home:
        context.goNamed(RouteNames.home);
      case LaunchDestination.welcome:
        context.goNamed(RouteNames.welcome);
      case LaunchDestination.onboarding:
        context.goNamed(RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    Widget logo = const ClLogo(size: 56);
    Widget tagline = Text(
      'Movie nights, decided together.',
      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    );
    if (!motion.reduced) {
      logo = logo
          .animate()
          .fadeIn(duration: motion.slow, curve: AppMotion.emphasized)
          .scale(begin: const Offset(0.92, 0.92), duration: motion.slow, curve: AppMotion.emphasized);
      tagline = tagline
          .animate(delay: const Duration(milliseconds: 250))
          .fadeIn(duration: motion.standard)
          .moveY(begin: 8, end: 0, duration: motion.standard, curve: AppMotion.emphasized);
    }
    return Scaffold(
      body: AuthBackdrop(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            logo,
            const SizedBox(height: AppSpacing.lg),
            tagline,
          ]),
        ),
      ),
    );
  }
}
