import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// Shared atmosphere for splash → onboarding → welcome → auth: near-black,
/// a faint topographic texture and a purple brand glow from the top.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child, this.intensity = 1});

  final Widget child;

  /// 0..1 — form screens use a quieter glow than splash / welcome.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ColoredBox(
      color: AppColors.bg,
      child: Stack(
        children: [
          Positioned(
            top: -size.width * 0.55,
            left: -size.width * 0.35,
            width: size.width * 1.5,
            height: size.width * 1.5,
            child: IgnorePointer(
              child: Opacity(
                opacity: intensity,
                child: const DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGlow),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.35 * intensity,
                child: SvgPicture.asset(
                  'assets/images/topography.svg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Two-line display heading with the second line in brand purple (CineFlow
/// pattern), plus an optional supporting line.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.line1, required this.line2, this.body, this.center = false});

  final String line1;
  final String line2;
  final String? body;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          label: '$line1 $line2',
          excludeSemantics: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$line1\n'),
                TextSpan(text: line2, style: const TextStyle(color: AppColors.purpleText)),
              ],
            ),
            style: AppTextStyles.display.copyWith(fontSize: 34, height: 40 / 34),
            textAlign: align,
          ),
        ),
        if (body != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            body!,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 16),
            textAlign: align,
          ),
        ],
      ],
    );
  }
}

/// "New to Cluvie? Create an account" style footer.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.prompt, required this.action, required this.onTap});

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppTextStyles.bodySm),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.purpleText,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}
