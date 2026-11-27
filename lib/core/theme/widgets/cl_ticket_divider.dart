import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';

/// Dashed divider with half-circle notches — the ticket-stub detail used on
/// watch-party cards. [notchColor] must match the surface behind the card.
class ClTicketDivider extends StatelessWidget {
  const ClTicketDivider({super.key, this.notchColor = AppColors.bg});

  final Color notchColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: 16,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned.fill(child: CustomPaint(painter: _DashPainter())),
          Positioned(left: -8, child: _Notch(color: notchColor)),
          Positioned(right: -8, child: _Notch(color: notchColor)),
        ]),
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (double x = 14; x < size.width - 14; x += 9) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}
