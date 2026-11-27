import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';

/// Fire with `controller.burst()`. Lives in a Stack over the content.
class ClConfettiController extends ChangeNotifier {
  void burst() => notifyListeners();
}

/// Native confetti burst (winner reveal, RSVP confirmed). Brand colours only.
/// Draws nothing under reduced motion.
class ClConfetti extends StatefulWidget {
  const ClConfetti({super.key, required this.controller, this.count = 48});

  final ClConfettiController controller;
  final int count;

  @override
  State<ClConfetti> createState() => _ClConfettiState();
}

class _ClConfettiState extends State<ClConfetti> with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  List<_Piece> _pieces = const [];
  final _rand = math.Random();

  static const _colors = [AppColors.gold, AppColors.goldDeep, AppColors.purpleText, AppColors.purple, AppColors.textPrimary];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_fire);
  }

  @override
  void didUpdateWidget(ClConfetti old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_fire);
      widget.controller.addListener(_fire);
    }
  }

  void _fire() {
    if (!mounted || AppMotion.of(context).reduced) return;
    setState(() {
      _pieces = List.generate(widget.count, (_) {
        final angle = -math.pi / 2 + (_rand.nextDouble() - 0.5) * math.pi * 0.9;
        final speed = 0.55 + _rand.nextDouble() * 0.55;
        return _Piece(
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          spin: (_rand.nextDouble() - 0.5) * 14,
          size: 5 + _rand.nextDouble() * 5,
          color: _colors[_rand.nextInt(_colors.length)],
          circle: _rand.nextBool(),
        );
      });
    });
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fire);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => _anim.isAnimating
            ? CustomPaint(painter: _ConfettiPainter(_pieces, _anim.value), size: Size.infinite)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
    required this.circle,
  });
  final double vx, vy, spin, size;
  final Color color;
  final bool circle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.55);
    final scale = size.shortestSide;
    const gravity = 1.3;
    final paint = Paint();
    for (final p in pieces) {
      final dx = p.vx * t * scale;
      final dy = (p.vy * t + 0.5 * gravity * t * t) * scale;
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
              const Radius.circular(1)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
