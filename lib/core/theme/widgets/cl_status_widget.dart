import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

enum ClStatusType { success, error, warning, loading }

/// Inline status banner. Text stays textPrimary (status colour is on the icon
/// and border only) so it passes AA on the tinted background.
class ClStatusBanner extends StatelessWidget {
  const ClStatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.show = true,
    this.dismissible = false,
    this.onDismiss,
  });

  final ClStatusType type;
  final String message;
  final bool show;
  final bool dismissible;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    final (IconData icon, Color color) = switch (type) {
      ClStatusType.success => (AppIcons.success, AppColors.success),
      ClStatusType.error => (AppIcons.error, AppColors.error),
      ClStatusType.warning => (AppIcons.warning, AppColors.warning),
      ClStatusType.loading => (AppIcons.loading, AppColors.textSecondary),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(message, style: AppTextStyles.label)),
          if (dismissible && onDismiss != null)
            IconButton(
              tooltip: 'Dismiss',
              icon: const Icon(AppIcons.close, size: 18),
              color: AppColors.textSecondary,
              onPressed: onDismiss,
            ),
        ]),
      ),
    );
  }
}
