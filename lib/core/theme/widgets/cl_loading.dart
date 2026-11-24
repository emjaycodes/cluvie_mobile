import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';

/// Inline spinner. Prefer [ClSkeleton] for content that has a known shape.
class ClLoading extends StatelessWidget {
  const ClLoading({super.key, this.size = 28, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: color ?? AppColors.gold),
        ),
      );
}

/// Shape-matched loading block. Static under reduced motion.
class ClSkeleton extends StatelessWidget {
  const ClSkeleton({super.key, this.width, this.height, this.radius = AppRadius.md, this.circle = false});

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
    if (AppMotion.of(context).reduced) return block;
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceRaised,
      highlightColor: const Color(0xFF2A2342),
      period: const Duration(milliseconds: 1400),
      child: block,
    );
  }
}

/// Skeleton for a list row: thumbnail + two text lines.
class ClSkeletonRow extends StatelessWidget {
  const ClSkeletonRow({super.key, this.thumbWidth = 56, this.thumbHeight = 80});

  final double thumbWidth;
  final double thumbHeight;

  @override
  Widget build(BuildContext context) => Row(children: [
        ClSkeleton(width: thumbWidth, height: thumbHeight),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClSkeleton(height: 14, width: 160),
            SizedBox(height: AppSpacing.sm),
            ClSkeleton(height: 12, width: 220),
            SizedBox(height: AppSpacing.xs),
            ClSkeleton(height: 12, width: 120),
          ]),
        ),
      ]);
}
