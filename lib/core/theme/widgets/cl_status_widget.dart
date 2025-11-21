import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

enum ClStatusType { success, error, warning, loading }

class ClStatusBanner extends StatelessWidget {
  final ClStatusType type;
  final String message;
  final bool show;
  final bool dismissible;

  const ClStatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.show = true,
    this.dismissible = false,
  });

  Color _getColor() {
    switch (type) {
      case ClStatusType.success:
        return AppColors.success;
      case ClStatusType.error:
        return AppColors.error;
      case ClStatusType.warning:
        return AppColors.warning;
      case ClStatusType.loading:
        return Colors.grey.shade400;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case ClStatusType.success:
        return Icons.check_circle_rounded;
      case ClStatusType.error:
        return Icons.error_rounded;
      case ClStatusType.warning:
        return Icons.warning_amber_rounded;
      case ClStatusType.loading:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.15),
        border: Border.all(color: _getColor().withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_getIcon(), color: _getColor()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: _getColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (dismissible)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: _getColor(),
              onPressed: () {
               
              },
            ),
        ],
      ),
    );
  }
}
