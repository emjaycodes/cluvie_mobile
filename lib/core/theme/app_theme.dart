import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// The single (dark) app theme. Source of truth: `design/tokens.md`.
abstract final class AppTheme {
  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.gold,
    onPrimary: AppColors.onGold,
    primaryContainer: AppColors.goldDeep,
    onPrimaryContainer: AppColors.onGold,
    secondary: AppColors.purpleText,
    onSecondary: AppColors.bg,
    secondaryContainer: AppColors.purpleContainer,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.purpleBadge,
    onTertiary: AppColors.onPurpleBadge,
    error: AppColors.error,
    onError: AppColors.onSemantic,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceDim: AppColors.bg,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceRaised,
    surfaceContainerHighest: AppColors.surfaceRaised,
    outline: AppColors.borderInput,
    outlineVariant: AppColors.border,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.bg,
    inversePrimary: AppColors.goldDeep,
  );

  static const Size _minTouch = Size(AppSpacing.minTouch, AppSpacing.minTouch);

  static OutlinedBorder get _pill => const StadiumBorder();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _scheme,
      fontFamily: AppTextStyles.bodyFamily,
      textTheme: AppTextStyles.textTheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      focusColor: AppColors.gold.withValues(alpha: 0.24),
      highlightColor: Colors.white.withValues(alpha: 0.04),
      splashColor: Colors.white.withValues(alpha: 0.06),
      dividerColor: AppColors.border,

      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ReducedMotionPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.iOS: ReducedMotionPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
        TargetPlatform.macOS: ReducedMotionPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
      }),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.gutter,
        foregroundColor: AppColors.textPrimary,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary, size: 24),
        titleTextStyle: AppTextStyles.h3,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      // ── Buttons ───────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          minimumSize: _minTouch,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: _pill,
          textStyle: AppTextStyles.button,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.onGold,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: _minTouch,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: _pill,
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.glassFlat,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: _minTouch,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: _pill,
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: _minTouch,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: _pill,
          textStyle: AppTextStyles.label,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: _minTouch,
          iconSize: 24,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.purpleBadge,
        foregroundColor: AppColors.onPurpleBadge,
        elevation: 0,
        shape: CircleBorder(),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(_minTouch),
          textStyle: const WidgetStatePropertyAll(AppTextStyles.label),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.purpleContainer : AppColors.surface),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? AppColors.textPrimary : AppColors.textSecondary),
        ),
      ),

      // ── Inputs ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: AppTextStyles.label.copyWith(color: AppColors.gold),
        helperStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.borderInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.borderInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.focusRing, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.gold,
        selectionColor: AppColors.gold.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.gold,
      ),

      // ── Surfaces ──────────────────────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        modalBarrierColor: Color(0xB30A0812),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: Color(0xB30A0812),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlAll,
          side: BorderSide(color: AppColors.border),
        ),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: TextStyle(
          fontFamily: AppTextStyles.bodyFamily, fontSize: 15, height: 22 / 15,
          color: AppColors.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: AppTextStyles.label,
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.navClearance - 4),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedColor: AppColors.purpleContainer,
        disabledColor: AppColors.surface,
        checkmarkColor: AppColors.purpleText,
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        secondaryLabelStyle: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        showCheckmark: true,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.label,
        unselectedLabelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.gold, width: 2.5),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        dividerColor: AppColors.border,
        overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.04)),
        tabAlignment: TabAlignment.start,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AppTextStyles.title,
        subtitleTextStyle: AppTextStyles.bodySm,
        minVerticalPadding: AppSpacing.md,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.surfaceRaised,
        circularTrackColor: AppColors.surfaceRaised,
        refreshBackgroundColor: AppColors.surfaceRaised,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.onGold : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.gold : AppColors.surfaceRaised),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.borderInput),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.gold : Colors.transparent),
        checkColor: const WidgetStatePropertyAll(AppColors.onGold),
        side: const BorderSide(color: AppColors.borderInput, width: 1.5),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(AppColors.gold)),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.purpleBadge,
        textColor: AppColors.onPurpleBadge,
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: AppRadius.smAll),
        textStyle: AppTextStyles.caption,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: AppTextStyles.label,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: AppColors.borderStrong),
        ),
      ),
    );
  }

  @Deprecated('App is dark-only. Use AppTheme.theme')
  static ThemeData get darkTheme => theme;
  @Deprecated('App is dark-only. Use AppTheme.theme')
  static ThemeData get lightTheme => theme;
}

/// Delegates to [inner] unless the OS asks for reduced motion, in which case
/// pages appear without a transition (tokens.md → Motion → Reduced motion).
class ReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReducedMotionPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => inner.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return inner.buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}
