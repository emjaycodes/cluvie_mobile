import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

enum ClBadgeTone {
  /// purpleContainer + purpleText — tags, "Pinned", genres.
  purple,

  /// purpleBadge + white — TONIGHT, counts.
  purpleSolid,

  /// glassFlat + textPrimary — tags over scrimmed posters.
  glass,

  /// Gold fill — winner only (counts toward the gold budget).
  gold,
  success,
  error,
  warning,
}

/// Small uppercase pill.
class ClBadge extends StatelessWidget {
  const ClBadge(this.label, {super.key, this.tone = ClBadgeTone.purple, this.icon, this.uppercase = true});

  final String label;
  final ClBadgeTone tone;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? border) = switch (tone) {
      ClBadgeTone.purple => (AppColors.purpleContainer, AppColors.purpleText, null),
      ClBadgeTone.purpleSolid => (AppColors.purpleBadge, AppColors.onPurpleBadge, null),
      ClBadgeTone.glass => (AppColors.glassFlat, AppColors.textPrimary, AppColors.borderStrong),
      ClBadgeTone.gold => (AppColors.gold, AppColors.onGold, null),
      ClBadgeTone.success => (AppColors.success, AppColors.onSemantic, null),
      ClBadgeTone.error => (AppColors.error, AppColors.onSemantic, null),
      ClBadgeTone.warning => (AppColors.warning, AppColors.onSemantic, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillAll,
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
        Text(
          uppercase ? label.toUpperCase() : label,
          style: AppTextStyles.overline.copyWith(color: fg, letterSpacing: uppercase ? 1.4 : 0.2),
        ),
      ]),
    );
  }
}
