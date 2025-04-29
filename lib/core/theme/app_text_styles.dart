import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';


class AppTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white, //todo: reminder AppColors.textOnPrimary 
);

  static TextTheme get textTheme => const TextTheme(
        titleLarge: heading1,
        titleMedium: heading2,
        bodyLarge: body,
        bodyMedium: body,
        labelSmall: caption,
      );
}
