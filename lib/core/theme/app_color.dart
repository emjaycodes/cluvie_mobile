import 'package:flutter/material.dart';


class AppColors {
  // === Brand Core ===
  static const Color cinematicPurple = Color(0xFF2E1F4A); // Main brand tone
  static const Color goldenPopcorn = Color(0xFFFFD27D); // Accent color (CTAs)
  static const Color popTeal = Color(0xFF4DC8B5); // Success / Active states
  static const Color softRed = Color(0xFFFF6B6B); // Error / Destructive
  static const Color amberWarning = Color(0xFFFFC107); // Warnings

  // === Semantic Tokens ===
  static const Color accent = goldenPopcorn;
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color success = popTeal;
  static const Color error = softRed;
  static const Color warning = amberWarning;

  // === Light Theme ===
  static const Color lightBackground = Color(0xFFF5F5F7); // Clean off-white
  static const Color lightSurface = Color(0xFFFFFFFF); // Cards/sheets
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecondary = Color(0xFF6E6E73);

  // === Dark Theme ===
  static const Color darkBackground = Color(0xFF0D0D0F); // Night Slate
  static const Color darkSurface = Color(0xFF1A122A); // Cards/panels
  static const Color darkBorder = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9EA2);

  // === Gradients & FX ===
  static const LinearGradient cinematicGradient = LinearGradient(
    colors: [cinematicPurple, Color(0xFF6A1B9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}


