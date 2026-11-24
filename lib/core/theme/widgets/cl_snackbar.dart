import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

enum ClSnackbarType { success, error, warning, loading, info }

/// Floating toast: raised surface pill, coloured status icon, optional action.
class ClSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    ClSnackbarType type = ClSnackbarType.success,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (IconData icon, Color color) = switch (type) {
      ClSnackbarType.success => (AppIcons.success, AppColors.success),
      ClSnackbarType.error => (AppIcons.error, AppColors.error),
      ClSnackbarType.warning => (AppIcons.warning, AppColors.warning),
      ClSnackbarType.loading => (AppIcons.loading, AppColors.textSecondary),
      ClSnackbarType.info => (AppIcons.info, AppColors.purpleText),
    };

    if (type == ClSnackbarType.error) HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(children: [
          type == ClSnackbarType.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary),
                )
              : Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: AppTextStyles.label)),
        ]),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, textColor: AppColors.gold, onPressed: onAction),
      ),
    );
  }
}
