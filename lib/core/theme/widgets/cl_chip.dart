import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';

class ClChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const ClChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary :Theme.of(context).brightness == Brightness.dark
      ? AppColors.backgroundDark
      : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary :Theme.of(context).brightness == Brightness.dark
      ? AppColors.borderDark
      : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
