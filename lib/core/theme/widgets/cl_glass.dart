import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';

/// Glass container. Flat (no blur) by default — real blur is reserved for the
/// nav bar, app bar and chat composer (tokens.md → surfaceGlass) and is
/// grouped through the app-level `BackdropGroup` so blurs share one pass.
class ClGlass extends StatelessWidget {
  const ClGlass({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.xlAll,
    this.padding,
    this.blur = false,
    this.color,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool blur;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? (blur ? AppColors.surfaceGlass : AppColors.glassFlat),
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (!blur) return body;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter.grouped(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: body),
    );
  }
}
