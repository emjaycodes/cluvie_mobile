import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// App bar. Opaque `bg` by default; [frosted] for screens whose content
/// scrolls underneath (with `extendBodyBehindAppBar`); [transparent] over heroes.
/// Shows a back button only when the route can actually pop.
class ClAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ClAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.centerTitle = false,
    this.transparent = false,
    this.frosted = false,
    this.bottom,
    this.fallbackRoute,
  });

  final String title;
  final bool showBackButton;

  /// Where back goes when there's nothing to pop (a deep link). With it set,
  /// the back button always shows; without it, only when there's a page to
  /// pop.
  final String? fallbackRoute;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool transparent;
  final bool frosted;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.maybeOf(context)?.canPop() ?? Navigator.of(context).canPop();
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: transparent
          ? Colors.transparent
          : frosted
              ? AppColors.surfaceGlass
              : AppColors.bg,
      leading: showBackButton && (canPop || fallbackRoute != null) ? ClBackButton(fallbackRoute: fallbackRoute) : null,
      title: Text(title, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis),
      centerTitle: centerTitle,
      actions: actions == null ? null : [...actions!, const SizedBox(width: 8)],
      bottom: bottom,
      flexibleSpace: frosted && !transparent
          ? ClipRect(
              child: BackdropFilter.grouped(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: const SizedBox.expand(),
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// Circular glass back button (44 visual / 48 hit).
class ClBackButton extends StatelessWidget {
  const ClBackButton({super.key, this.onPressed, this.fallbackRoute});

  final VoidCallback? onPressed;

  /// Where to go when there's nothing to pop (a deep link).
  final String? fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClIconButton(
        icon: AppIcons.back,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ??
            () {
              final router = GoRouter.maybeOf(context);
              if (router != null && router.canPop()) {
                router.pop();
              } else if (router != null && fallbackRoute != null) {
                router.go(fallbackRoute!);
              } else {
                Navigator.maybePop(context);
              }
            },
      ),
    );
  }
}

/// Glass circle icon button used on app bars and over posters.
class ClIconButton extends StatelessWidget {
  const ClIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.badge = false,
    this.badgeLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  /// Shows a small purple dot (e.g. unread notifications).
  final bool badge;

  /// Spoken with the tooltip when [badge] is on, e.g. "3 unread".
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final label = badge && badgeLabel != null ? '$tooltip, $badgeLabel' : tooltip;
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.glassFlat,
        fixedSize: const Size(44, 44),
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: Stack(clipBehavior: Clip.none, children: [
        Icon(icon, size: 20, color: AppColors.textPrimary),
        if (badge)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.purpleBadge,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg, width: 1.5),
              ),
            ),
          ),
      ]),
    );
  }
}
