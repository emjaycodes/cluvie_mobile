import 'package:flutter/material.dart';

/// Tab bar; all styling comes from the theme's TabBarThemeData
/// (gold underline indicator, textPrimary / textSecondary labels).
class ClTabBar extends StatelessWidget implements PreferredSizeWidget {
  const ClTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    this.isScrollable = true,
  });

  final List<Tab> tabs;
  final TabController controller;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) => TabBar(
        controller: controller,
        tabs: tabs,
        isScrollable: isScrollable,
        tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
      );

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);
}
