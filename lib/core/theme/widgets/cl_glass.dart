import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';

/// Frosted container: surfaceGlass (88% surface) + σ20 blur + hairline border.
/// Real blur is expensive on Android — reserve for nav bar / app bar / composer
/// (tokens.md). Use `blur: false` for everything else (flat glass).
class ClGlass extends StatelessWidget {
  const ClGlass({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.xlAll,
    this.padding,
    this.blur = true,
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
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: body),
    );
  }
}
