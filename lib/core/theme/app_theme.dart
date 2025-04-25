import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'app_text_styles.dart';

import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: Colors.white,
        
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: AppTextStyles.appBarTitle,
          iconTheme: IconThemeData(color: AppColors.primary),
        ),

        textTheme: AppTextStyles.textTheme,

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          filled: true,
          fillColor:  AppColors.primary.withOpacity(0.05)
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.button, // optional: match design
          ),
        ),

        // ✅ Add TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.button, // ensure visual consistency
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),

        // Optional: IconButton style if your app uses a lot of them
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(AppColors.primary),
          ),
        ),
      );
}

