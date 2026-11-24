import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_pressable.dart';

/// Button variants. Gold ([primary]) is opt-in: one gold owner per screen
/// (tokens.md → Gold budget). Card-level CTAs use [inverse] or [secondary].
enum ClButtonVariant {
  /// Gold gradient — the screen's single primary action.
  primary,

  /// Flat glass with hairline border.
  secondary,

  /// White fill, dark text — card CTAs (RSVP, Join).
  inverse,

  /// Brand purple fill, white text.
  purple,

  /// Text only.
  ghost,

  /// Destructive.
  danger,
}

enum ClButtonSize { sm, md, lg }

class ClButton extends StatelessWidget {
  const ClButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant,
    this.size = ClButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    @Deprecated('Use variant: ClButtonVariant.secondary') this.isSecondary = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final ClButtonVariant? variant;
  final ClButtonSize size;
  final IconData? icon;
  final bool isLoading;

  /// Fill the available width when it is bounded.
  final bool expand;
  final bool isSecondary;

  ClButtonVariant get resolvedVariant =>
      variant ?? (isSecondary ? ClButtonVariant.secondary : ClButtonVariant.primary);

  double get _height => switch (size) {
        ClButtonSize.sm => 40,
        ClButtonSize.md => 48,
        ClButtonSize.lg => 56,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final v = resolvedVariant;

    final (Color? fill, Gradient? gradient, Color fg, BorderSide? side, List<BoxShadow>? glow) =
        !enabled && !isLoading
            ? (AppColors.surfaceRaised, null, AppColors.textMuted, null, null)
            : switch (v) {
                ClButtonVariant.primary =>
                  (null, AppColors.goldGradient, AppColors.onGold, null, AppShadows.glowGold),
                ClButtonVariant.secondary => (
                    AppColors.glassFlat,
                    null,
                    AppColors.textPrimary,
                    const BorderSide(color: AppColors.borderStrong),
                    null
                  ),
                ClButtonVariant.inverse => (AppColors.textPrimary, null, AppColors.onGold, null, null),
                ClButtonVariant.purple =>
                  (AppColors.purpleBadge, null, AppColors.onPurpleBadge, null, AppShadows.glowPurple),
                ClButtonVariant.ghost => (null, null, AppColors.textSecondary, null, null),
                ClButtonVariant.danger => (AppColors.error, null, AppColors.onSemantic, null, null),
              };

    final textStyle = AppTextStyles.button.copyWith(
      color: fg,
      fontSize: size == ClButtonSize.sm ? 14 : 15,
    );

    final content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: size == ClButtonSize.sm ? 18 : 20, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ],
          );

    final shape = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        gradient: gradient,
        borderRadius: AppRadius.pillAll,
        border: side == null ? null : Border.fromBorderSide(side),
        boxShadow: glow,
      ),
      child: SizedBox(
        height: _height,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size == ClButtonSize.sm ? AppSpacing.lg : AppSpacing.xl,
          ),
          child: Center(widthFactor: 1, child: content),
        ),
      ),
    );

    // sm is 40 visual; pad to the 48dp minimum hit area.
    final hitPad = size == ClButtonSize.sm ? (AppSpacing.minTouch - _height) / 2 : 0.0;

    return LayoutBuilder(builder: (context, constraints) {
      final fillWidth = expand && constraints.hasBoundedWidth;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: hitPad),
        child: SizedBox(
          width: fillWidth ? double.infinity : null,
          child: ClPressable(
            onTap: enabled ? onPressed : null,
            borderRadius: AppRadius.pillAll,
            semanticLabel: isLoading ? '$label, loading' : null,
            child: shape,
          ),
        ),
      );
    });
  }
}
