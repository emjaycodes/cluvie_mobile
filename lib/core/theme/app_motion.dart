import 'package:flutter/widgets.dart';

/// Motion tokens. Source of truth: `design/tokens.md`.
///
/// Always read durations through [AppMotion.of] so reduced-motion
/// (`MediaQuery.disableAnimations`) zeroes them in one place.
class AppMotion {
  const AppMotion._(this.reduced);

  /// True when the OS asks for reduced motion.
  final bool reduced;

  static const Duration _instant = Duration(milliseconds: 120);
  static const Duration _quick = Duration(milliseconds: 220);
  static const Duration _standard = Duration(milliseconds: 360);
  static const Duration _slow = Duration(milliseconds: 600);
  static const Duration _stagger = Duration(milliseconds: 40);

  /// Max items that get a stagger delay; later items share the last delay.
  static const int staggerCap = 8;

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  static const SpringDescription spring = SpringDescription(mass: 1, stiffness: 400, damping: 28);

  /// Scale applied while a control is pressed.
  static const double pressScale = 0.97;

  static AppMotion of(BuildContext context) =>
      AppMotion._(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  Duration get instant => reduced ? Duration.zero : _instant;
  Duration get quick => reduced ? Duration.zero : _quick;
  Duration get standard => reduced ? Duration.zero : _standard;
  Duration get slow => reduced ? Duration.zero : _slow;

  /// Delay for the item at [index] in a staggered list.
  Duration staggerAt(int index) =>
      reduced ? Duration.zero : _stagger * (index < staggerCap ? index : staggerCap);
}
