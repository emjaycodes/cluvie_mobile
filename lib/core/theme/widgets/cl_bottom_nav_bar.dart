import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';

class ClBottomNavBar extends StatelessWidget {
  final Widget child;

  const ClBottomNavBar({
    super.key,
    required this.child,
  });

  // M1+M2 spec: Home (/home alias for /), Discover (/discover), Suggest (/suggest), Communities (/communities), Profile (/profile)
  static const List<String> routes = [
    '/home',
    '/discover',
    '/suggest',
    '/communities',
    '/profile',
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString().toLowerCase();
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/suggest')) return 2;
    if (location.startsWith('/communities') || location.startsWith('/allcommunities')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/users/')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          context.go(routes[index]);
        },
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        backgroundColor: AppColors.darkBackground,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Discover",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: "Suggest",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: "Clubs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
