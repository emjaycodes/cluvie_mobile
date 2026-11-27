import 'package:flutter/material.dart';

/// Cluvie colour tokens — dark only. Source of truth: `design/tokens.md` (v1.1).
///
/// Rules (see tokens.md):
/// * Gold budget: one gold content owner per screen + active nav tab + logo + focus ring.
/// * [textMuted] only on [bg], [surface], [surfaceRaised]. On tints/glass/scrims use [textSecondary].
/// * Every fill has an "on" colour ([onGold], [onPurpleBadge], [onSemantic]). Never put text on [purple].
abstract final class AppColors {
  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFF0A0812);
  static const Color surface = Color(0xFF14101F);
  static const Color surfaceRaised = Color(0xFF1D1730);

  /// Tinted glass base for the blurred nav bar / app bar (88% surface).
  static const Color surfaceGlass = Color(0xE014101F);

  /// 96% bg panel: solid enough for copy over any poster colour.
  static const Color bgPanel = Color(0xF50A0812);

  /// Flat glass for chips / secondary buttons over known dark surfaces (no blur).
  static const Color glassFlat = Color(0x14FFFFFF);

  static const Color border = Color(0x14FFFFFF); // 8%
  static const Color borderStrong = Color(0x24FFFFFF); // 14%
  static const Color borderInput = Color(0xFF6A6380); // ≥3:1 on surfaces
  static const Color focusRing = gold;

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F3FA);
  static const Color textSecondary = Color(0xFFA8A3B8);
  static const Color textMuted = Color(0xFF8F899F);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFFFD27D);
  static const Color goldDeep = Color(0xFFF2B544);

  /// Glows and progress tracks only. **No text on or in this colour.**
  static const Color purple = Color(0xFF7C5CFF);

  /// Purple used as text (links, tags, mentions).
  static const Color purpleText = Color(0xFFA48BFF);

  /// The original brand purple, used as a container: tags, selected chips,
  /// poll leader, own chat bubbles, badges.
  static const Color purpleContainer = Color(0xFF2E1F4A);

  /// Solid purple fill that carries white text: centre "+", count badges.
  static const Color purpleBadge = Color(0xFF6545E0);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4DC8B5);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFC107);

  // ── "On" colours ──────────────────────────────────────────────────────────
  static const Color onGold = Color(0xFF14101F);
  static const Color onPurpleBadge = Color(0xFFFFFFFF);
  static const Color onSemantic = Color(0xFF14101F);

  /// Text on the white `inverse` button fill (#F5F3FA) — ≈16:1.
  static const Color onInverse = Color(0xFF14101F);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Bottom poster scrim (tokens.md): 0% to 35%, 85% at 55%, 96% at 100%.
  /// Text blocks must start at or below the 55% stop.
  static const LinearGradient scrimBottom = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000A0812), Color(0x000A0812), Color(0xD90A0812), Color(0xF50A0812)],
    stops: [0.0, 0.35, 0.55, 1.0],
  );

  /// Opacity of `bg` behind any text or control on a poster (tokens.md
  /// `scrimSolid`). Worst case, white poster: textPrimary ≥ 12:1.
  static const double scrimSolid = 0.9;

  /// Alias used in tokens.md "Gradients".
  static const LinearGradient posterScrim = scrimBottom;

  /// Top poster scrim behind status bar / icon buttons (apply over top ~120dp).
  static const LinearGradient scrimTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xB30A0812), Color(0x000A0812)],
  );

  static const RadialGradient brandGlow = RadialGradient(
    colors: [Color(0x597C5CFF), Color(0x007C5CFF)],
  );
  // ── Avatar palette ────────────────────────────────────────────────────────
  /// Deterministic tints for initials avatars (R12-N6). Indexed by the
  /// person's name hash so the same member keeps the same colour.
  static const List<Color> avatarTints = [
    Color(0xFF3A2D5C),
    Color(0xFF2B3D55),
    Color(0xFF4A2F3F),
    Color(0xFF2F4A43),
    Color(0xFF4A402A),
  ];
}
