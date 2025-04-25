import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';

Future<void> showClDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}
