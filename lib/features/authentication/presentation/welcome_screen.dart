import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';
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
              Text("CLUVIE🍿", style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.sm),
              Text("Join the club", style: AppTextStyles.heading1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                          "Log in to continue using Cluvie.",
                          style: AppTextStyles.heading2,
                        ),
              Center(
                child: AuthGlassmorphicContainer(
                  child: Column(
                    
                    children: [
                      AuthButton(
                        label: 'Continue with Apple',
                        onPressed: () {},
                        icon: SvgPicture.asset(
                          'assets/icons/apple.svg',
                          width: 24,
                          height: 24,
                        ),
                        color: AppColors.black,
                        // style: ElevatedButton.styleFrom(
                        //   backgroundColor: Colors.black,
                        //   foregroundColor: Colors.white,
                        // ),
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

                      SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Divider(
                            color: Colors.white,
                            thickness: 1,
                            endIndent: 8,
                            indent: 8,
                          ),
                          const Text(
                            'or',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Divider(
                            color: Colors.white,
                            thickness: 1,
                            endIndent: 8,
                            indent: 8,
                          ),
                        ],
                      ),

                      AuthButton(
                        label: 'Continue with Email',
                        onPressed: () => context.pushNamed('signup'),
                        icon: Icon(Icons.email, size: 24, color: Colors.white),
                        color: AppColors.darkSurface,
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
      label: Text(label, style: AppTextStyles.button.copyWith(color: AppColors.darkTextPrimary)),
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
