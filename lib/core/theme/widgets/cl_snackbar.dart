import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';

enum ClSnackType { success, error, info }

void showCluvieSnackBar({
  required BuildContext context,
  required String message,
  ClSnackType type = ClSnackType.info,
}) {
  final color = switch (type) {
    ClSnackType.success => AppColors.success,
    ClSnackType.error => AppColors.error,
    ClSnackType.info => AppColors.cinematicPurple,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      duration: const Duration(seconds: 3),
    ),
  );
}
