import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';

class ClTabBar extends StatelessWidget {
  final List<Tab> tabs;
  final TabController controller;

  const ClTabBar({
    super.key,
    required this.tabs,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: tabs,
      labelColor: AppColors.primary,
      unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
      ? AppColors.textSecondaryDark
      : AppColors.textSecondaryLight,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
