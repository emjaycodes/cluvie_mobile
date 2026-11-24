import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_pressable.dart';

/// Filter / choice chip. Selected = purple container + purpleText + check
/// (not colour alone). 36 visual, 48 hit. Display-only when [onTap] is null.
class ClChip extends StatelessWidget {
  const ClChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final interactive = onTap != null;
    final fg = isSelected ? AppColors.purpleText : AppColors.textSecondary;
    return ClPressable(
      onTap: onTap,
      isButton: interactive,
      selected: interactive ? isSelected : null,
      borderRadius: AppRadius.pillAll,
      hitPadding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedContainer(
        duration: motion.quick,
        curve: AppMotion.easeOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purpleContainer : AppColors.surfaceRaised,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: isSelected ? AppColors.purpleText.withValues(alpha: 0.5) : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedSize(
            duration: motion.quick,
            curve: AppMotion.easeOut,
            child: isSelected
                ? const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(AppIcons.check, size: 14, color: AppColors.purpleText),
                  )
                : icon != null
                    ? Padding(padding: const EdgeInsets.only(right: 6), child: Icon(icon, size: 16, color: fg))
                    : const SizedBox.shrink(),
          ),
          Text(label, style: AppTextStyles.label.copyWith(color: fg, fontSize: 13)),
        ]),
      ),
    );
  }
}
