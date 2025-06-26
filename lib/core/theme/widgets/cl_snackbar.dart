import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

enum ClSnackbarType { success, error, warning, loading }

class ClSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    ClSnackbarType type = ClSnackbarType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final Color bgColor;
    final IconData icon;

    switch (type) {
      case ClSnackbarType.success:
        bgColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case ClSnackbarType.error:
        bgColor = AppColors.error;
        icon = Icons.error_rounded;
        break;
      case ClSnackbarType.warning:
        bgColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case ClSnackbarType.loading:
        bgColor = Colors.grey.shade600;
        icon = Icons.hourglass_top_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
