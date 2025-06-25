import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static final TextStyle appBarTitle = GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle heading1 = GoogleFonts.quicksand(
    fontSize: 32,
    fontWeight: FontWeight.w900,
  );

  static final TextStyle heading2 = GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle body = GoogleFonts.quicksand(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle caption = GoogleFonts.quicksand(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static final TextStyle button = GoogleFonts.quicksand(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextTheme get textTheme => TextTheme(
        titleLarge: heading1,
        titleMedium: heading2,
        bodyLarge: body,
        bodyMedium: body,
        labelSmall: caption,
      );
}
