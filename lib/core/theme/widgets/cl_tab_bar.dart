import 'package:flutter/material.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';

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
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.lightTextPrimary,
      indicatorColor: AppColors.accent,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
