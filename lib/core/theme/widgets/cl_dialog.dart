import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';

Future<void> showClDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Confirm',
  String closeText = 'Close',
  bool showCancel = true,
  bool showConfirm = false
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(closeText),
        ),
        showConfirm? ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cinematicPurple,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(confirmText),
        ) : Container()
      ],
    ),
  );
}
