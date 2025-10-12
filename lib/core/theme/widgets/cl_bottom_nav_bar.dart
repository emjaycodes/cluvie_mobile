import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cluvie_mobile/core/theme/app_color.dart';

class ClBottomNavBar extends StatelessWidget {
  final Widget child;

  const ClBottomNavBar({
    super.key,
    required this.child,
  });

  static const List<String> routes = [
    '/home',
    '/discover',
    '/suggest',
    '/allCommunities',
    '/profile',
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString().toLowerCase();
    if (location.startsWith('/discover')) return 1;
    if (location.startsWith('/suggest')) return 2;
    if (location.startsWith('/allcommunities')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // default to home
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
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Discover",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Suggest",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: "Clubs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
