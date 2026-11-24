import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:cluvie_mobile/core/theme/app_icons.dart';
import 'package:cluvie_mobile/core/theme/app_motion.dart';
import 'package:cluvie_mobile/core/theme/app_spacing.dart';
import 'package:cluvie_mobile/core/theme/app_text_styles.dart';

/// Shell with a floating frosted nav: 4 tabs + a raised purple "+" (Suggest).
///
/// The body extends behind the bar; scroll views must pad their bottom by
/// `MediaQuery.paddingOf(context).bottom` (which includes the bar) — see
/// [ClBottomNavBar.contentPadding].
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

  /// Bottom padding for scroll content inside the shell so the last item
  /// clears the floating bar.
  static double contentPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final index = indexForLocation(GoRouterState.of(context).uri.toString());
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingNav(
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
  static const double _inner = 6;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, (safeBottom > 0 ? safeBottom : AppSpacing.lg)),
      child: SizedBox(
        height: _barHeight + 14, // room for the raised "+"
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          // Frosted bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(borderRadius: AppRadius.xlAll, boxShadow: AppShadows.float),
              child: ClipRRect(
                borderRadius: AppRadius.xlAll,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: AppRadius.xlAll,
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: _inner),
                    child: LayoutBuilder(builder: (context, c) {
                      final slot = c.maxWidth / _items.length;
                      return Stack(children: [
                        // Sliding gold pill under the active tab (hidden on "+")
                        AnimatedPositioned(
                          duration: motion.quick,
                          curve: AppMotion.emphasized,
                          left: slot * index + 6,
                          width: slot - 12,
                          top: 10,
                          height: _barHeight - 20,
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
                                  : _Tab(item: _items[i], active: i == index, onTap: () => onTap(i)),
                            ),
                        ]),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
          ),
          // Raised centre action
          Positioned(
            top: 0,
            child: _PlusButton(active: index == 2, onTap: () => onTap(2)),
          ),
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
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        highlightColor: Colors.transparent,
        child: SizedBox.expand(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedSwitcher(
              duration: motion.quick,
              transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(a), child: c),
              child: Icon(active ? item.activeIcon : item.icon,
                  key: ValueKey(active), size: 24, color: color),
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
      ),
    );
  }
}

class _PlusButton extends StatefulWidget {
  const _PlusButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

class _PlusButtonState extends State<_PlusButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    return Semantics(
      button: true,
      selected: widget.active,
      label: 'Suggest a film',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1,
          duration: motion.instant,
          curve: AppMotion.overshoot,
          child: AnimatedRotation(
            turns: _pressed ? 0.125 : 0,
            duration: motion.quick,
            curve: AppMotion.overshoot,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.purpleBadge,
                boxShadow: AppShadows.glowPurple,
                border: Border.all(
                  color: widget.active ? AppColors.gold : AppColors.bg,
                  width: widget.active ? 2.5 : 4,
                ),
              ),
              child: const Icon(AppIcons.add, color: AppColors.onPurpleBadge, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
