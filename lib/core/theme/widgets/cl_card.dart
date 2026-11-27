import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_pressable.dart';

/// Base card: one surface step up from bg + hairline border. No shadow.
class ClCard extends StatelessWidget {
  const ClCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Defaults to none; lists should space cards with gaps, not margins.
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double radius;

  /// Clip children (e.g. images) to the rounded shape.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.card),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: br,
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
    if (onTap != null) {
      card = ClPressable(onTap: onTap, borderRadius: br, child: card);
    }
    if (margin != null) card = Padding(padding: margin!, child: card);
    return card;
  }
}
