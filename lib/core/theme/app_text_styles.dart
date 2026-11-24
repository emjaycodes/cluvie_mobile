import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';

/// Type scale. Sora (display/headings) + Plus Jakarta Sans (body/UI), bundled
/// in `assets/fonts/`. Source of truth: `design/tokens.md`.
abstract final class AppTextStyles {
  static const String displayFamily = 'Sora';
  static const String bodyFamily = 'PlusJakartaSans';

  static const TextStyle display = TextStyle(
    fontFamily: displayFamily, fontSize: 40, height: 44 / 40, fontWeight: FontWeight.w800,
    letterSpacing: -1.2, color: AppColors.textPrimary,
  );
  static const TextStyle h1 = TextStyle(
    fontFamily: displayFamily, fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700,
    letterSpacing: -0.6, color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: displayFamily, fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.3, color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: displayFamily, fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, color: AppColors.textPrimary,
  );
  static const TextStyle title = TextStyle(
    fontFamily: bodyFamily, fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: bodyFamily, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily, fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.1, color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500,
    letterSpacing: 0.1, color: AppColors.textSecondary,
  );
  static const TextStyle overline = TextStyle(
    fontFamily: bodyFamily, fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700,
    letterSpacing: 1.4, color: AppColors.textMuted,
  );

  /// Button label (used by button themes).
  static const TextStyle button = TextStyle(
    fontFamily: bodyFamily, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  // ── Legacy aliases (removed in Phase 6) ────────────────────────────────────
  @Deprecated('Use AppTextStyles.display or h1') static const TextStyle heading1 = h1;
  @Deprecated('Use AppTextStyles.h2 / h3') static const TextStyle heading2 = h2;
  @Deprecated('Use AppTextStyles.h3') static const TextStyle appBarTitle = h3;

  static TextTheme get textTheme => const TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: h1,
        headlineLarge: h1,
        headlineMedium: h2,
        headlineSmall: h3,
        titleLarge: h3,
        titleMedium: title,
        titleSmall: label,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: bodySm,
        labelLarge: button,
        labelMedium: label,
        labelSmall: caption,
      );
}
