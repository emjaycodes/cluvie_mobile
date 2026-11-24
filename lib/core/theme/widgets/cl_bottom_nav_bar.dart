import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';
import 'package:cluvie_mobile/core/theme/widgets/cl_pressable.dart';

/// Shell with a floating frosted nav: 4 tabs + a raised purple "+" (Suggest).
///
/// Content contract: the body extends behind the bar. Scroll views pad their
/// bottom by `MediaQuery.paddingOf(context).bottom` (includes the bar); inner
/// Scaffold FABs and SnackBars are lifted automatically.
class ClBottomNavBar extends StatelessWidget {
  const ClBottomNavBar({super.key, required this.child});

  final Widget child;

  static const List<String> routes = ['/home', '/discover', '/suggest', '/communities', '/profile'];

  /// Index of the tab owning [location]; 2 is the centre "+".
  @visibleForTesting
  static int indexForLocation(String location) {
    final l = location.toLowerCase();
    if (l.startsWith('/discover')) return 1;
    if (l.startsWith('/suggest')) return 2;
    if (l.startsWith('/communities') || l.startsWith('/allcommunities')) return 3;
    if (l.startsWith('/profile') || l.startsWith('/users/')) return 4;
    return 0;
  }

  /// Bottom padding for scroll content inside the shell.
  static double contentPadding(BuildContext context) => MediaQuery.paddingOf(context).bottom + AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final index = indexForLocation(GoRouterState.of(context).uri.toString());
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      extendBody: true,
      // Inner Scaffolds place FABs using viewPadding; with extendBody only
      // `padding` carries the bar height, so mirror it into viewPadding.
      body: Builder(builder: (context) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            viewPadding: mq.viewPadding.copyWith(bottom: math.max(mq.viewPadding.bottom, mq.padding.bottom)),
          ),
          child: child,
        );
      }),
      bottomNavigationBar: keyboardUp
          ? null
          : _FloatingNav(
              index: index,
              onTap: (i) {
                if (i == index) return;
                HapticFeedback.selectionClick();
                context.go(routes[i]);
              },
            ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _items = [
  _NavItem('Home', AppIcons.home, AppIcons.homeFill),
  _NavItem('Discover', AppIcons.discover, AppIcons.discoverFill),
  _NavItem('Suggest', AppIcons.add, AppIcons.add),
  _NavItem('Clubs', AppIcons.clubs, AppIcons.clubsFill),
  _NavItem('Profile', AppIcons.profile, AppIcons.profileFill),
];

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const double _barHeight = 68;
  static const double _plusOverhang = 14;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final pad = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        math.max(AppSpacing.lg, pad.left),
        0,
        math.max(AppSpacing.lg, pad.right),
        pad.bottom > 0 ? pad.bottom : AppSpacing.lg,
      ),
      child: SizedBox(
        height: _barHeight + _plusOverhang,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(borderRadius: AppRadius.xlAll, boxShadow: AppShadows.float),
              child: ClipRRect(
                borderRadius: AppRadius.xlAll,
                child: BackdropFilter.grouped(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: AppRadius.xlAll,
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: LayoutBuilder(builder: (context, c) {
                      final slot = c.maxWidth / _items.length;
                      return Stack(children: [
                        // Sliding gold pill under the active tab (hidden on "+").
                        AnimatedPositioned(
                          duration: motion.quick,
                          curve: AppMotion.emphasized,
                          left: slot * index + 4,
                          width: slot - 8,
                          top: 8,
                          height: _barHeight - 18,
                          child: AnimatedOpacity(
                            duration: motion.quick,
                            opacity: index == 2 ? 0 : 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.12),
                                borderRadius: AppRadius.lgAll,
                              ),
                            ),
                          ),
                        ),
                        Row(children: [
                          for (var i = 0; i < _items.length; i++)
                            Expanded(
                              child: i == 2
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: _Tab(item: _items[i], active: i == index, onTap: () => onTap(i)),
                                    ),
                            ),
                        ]),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 0, child: _PlusButton(active: index == 2, onTap: () => onTap(2))),
        ]),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final color = active ? AppColors.gold : AppColors.textSecondary;
    return ClPressable(
      onTap: onTap,
      haptic: false, // the shell fires a selection click
      selected: active,
      semanticLabel: item.label,
      excludeChildSemantics: true,
      borderRadius: AppRadius.lgAll,
      child: SizedBox.expand(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedSwitcher(
            duration: motion.quick,
            transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(a), child: c),
            child: Icon(active ? item.activeIcon : item.icon, key: ValueKey(active), size: 24, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
        ]),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  const _PlusButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClPressable(
      onTap: onTap,
      haptic: false,
      selected: active,
      semanticLabel: 'Suggest a film',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.purpleBadge,
          boxShadow: AppShadows.glowPurple,
          border: Border.all(
            color: active ? AppColors.gold : AppColors.bg,
            width: active ? 2.5 : 4,
          ),
        ),
        child: const Icon(AppIcons.add, color: AppColors.onPurpleBadge, size: 26),
      ),
    );
  }
}
