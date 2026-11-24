import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_button.dart';

/// Themed confirm dialog. Buttons stack full-width (48dp each).
Future<void> showClDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Confirm',
  String closeText = 'Close',
  bool showCancel = true,
  bool showConfirm = false,
  bool destructive = false,
}) {
  return showDialog(
    context: context,
    animationStyle: AppMotion.of(context).reduced ? AnimationStyle.noAnimation : null,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      actions: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          if (showConfirm)
            ClButton(
              label: confirmText,
              variant: destructive ? ClButtonVariant.danger : ClButtonVariant.primary,
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
            ),
          if (showConfirm && showCancel) const SizedBox(height: AppSpacing.sm),
          if (showCancel || !showConfirm)
            ClButton(
              label: closeText,
              variant: ClButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
            ),
        ]),
      ],
    ),
  );
}
