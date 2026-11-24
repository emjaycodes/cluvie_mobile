import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';

/// Animated circular progress (countdowns, vote share). Fills over
/// AppMotion.slow; instant under reduced motion.
class ClProgressRing extends StatelessWidget {
  const ClProgressRing({
    super.key,
    required this.value,
    this.size = 96,
    this.strokeWidth = 7,
    this.color = AppColors.gold,
    this.trackColor = AppColors.surfaceRaised,
    this.child,
    this.semanticLabel,
  });

  /// 0..1
  final double value;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    return Semantics(
      label: semanticLabel,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: motion.slow,
          curve: AppMotion.emphasized,
          builder: (context, v, c) => CustomPaint(
            painter: _RingPainter(v, strokeWidth, color, trackColor),
            child: Center(child: c),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke, this.color, this.track);
  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (value <= 0) return;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value, false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.stroke != stroke;
}
