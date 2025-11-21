import 'package:cluvie_mobile/core/router/routes_name.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/features/authentication/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.clPadding,
          child: Column(
            children: [
               SvgPicture.asset(
                          'assets/images/cluvie_logo.svg',
                          width: 50,
                          height: 100,
                        ),
              const SizedBox(height: AppSpacing.xs * 5),
              Text("Join the club", style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                "Sign up to start suggesting, voting and discussing your favorite films.",
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl * 2),

              Center(
                child: AuthGlassmorphicContainer(
                  width: double.infinity,
                  height: 380,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl ),
                      AuthButton(
                        label: 'Continue with Apple',
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/apple.svg',
                          width: 24,
                          height: 24,
                        ),
                        color: AppColors.black,
                      ),

                      SizedBox(height: 16),

                      AuthButton(
                        label: 'Continue with Google',
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/google.svg',
                          width: 24,
                          height: 24,
                        ),
                        color: AppColors.darkSurface,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.darkBorder,
                                thickness: 1,
                                endIndent: 8,
                                indent: 32,
                              ),
                            ),
                            const Text(
                              'or',
                              style: TextStyle(
                                color: AppColors.white,

                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.darkBorder,
                                thickness: 1,
                                indent: 8,
                                endIndent: 32,
                              ),
                            ),
                          ],
                        ),
                      ),

                      AuthButton(
                        label: 'Continue with Email',
                        onPressed: () => context.pushNamed('signup'),
                        icon: Icon(Icons.email, size: 24, color: Colors.white),
                        color: AppColors.darkSurface,
                      ),

                      const SizedBox(height: AppSpacing.xl ),

                      Text("Already have an account?"),
                      // const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed:
                            () => context.pushNamed(RouteNames.login),
                        child: const Text("Log in"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? color;
  final ButtonStyle? style;
  const AuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      label: Text(
        label,
        style: AppTextStyles.button.copyWith(color: AppColors.darkTextPrimary),
      ),
      onPressed: onPressed ?? () {},
      icon: icon,
      style:
          style ??
          ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.white,
            foregroundColor: Colors.black,
            minimumSize: const Size(300.0, 50.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
    );
  }
}
