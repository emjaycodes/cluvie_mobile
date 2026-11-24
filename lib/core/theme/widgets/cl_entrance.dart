import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';

/// Staggered rise-in for list items and sections (360ms, 40ms step, capped).
/// Returns the child untouched under reduced motion.
class ClEntrance extends StatelessWidget {
  const ClEntrance({super.key, required this.child, this.index = 0, this.offset = 12});

  final Widget child;

  /// Position in the list; drives the stagger delay.
  final int index;

  /// Rise distance in logical pixels.
  final double offset;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    if (motion.reduced) return child;
    return child
        .animate(delay: motion.staggerAt(index))
        .fadeIn(duration: motion.standard, curve: AppMotion.emphasized)
        .moveY(begin: offset, end: 0, duration: motion.standard, curve: AppMotion.emphasized);
  }
}

extension ClEntranceX on Widget {
  /// `myCard.entrance(i)` — sugar for [ClEntrance].
  Widget entrance([int index = 0]) => ClEntrance(index: index, child: this);
}
