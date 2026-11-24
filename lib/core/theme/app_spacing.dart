import 'package:flutter/material.dart';

/// 4-pt spacing scale. Source of truth: `design/tokens.md`.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal screen gutter.
  static const double gutter = 20;

  /// Vertical gap between screen sections.
  static const double section = 28;

  /// Inner card padding.
  static const double card = 16;

  /// Minimum touch target (dp).
  static const double minTouch = 48;

  /// Height of the floating nav bar incl. its bottom offset — screens inside
  /// the shell pad their scroll content by this so nothing hides behind it.
  static const double navClearance = 68 + 16 + 16;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: gutter);

  @Deprecated('Use AppSpacing.screen or EdgeInsets.all(AppSpacing.lg)')
  static const EdgeInsetsGeometry clPadding = EdgeInsets.all(lg);
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(xl));
}

/// Depth on dark = surface step + border + optional glow. No Material shadows.
abstract final class AppShadows {
  static const List<BoxShadow> glowGold = [
    BoxShadow(color: Color(0x59FFD27D), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> glowPurple = [
    BoxShadow(color: Color(0x737C5CFF), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 12)),
  ];
}
