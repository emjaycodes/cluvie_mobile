import 'package:cluvie_mobile/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClBottomNavBar extends StatefulWidget {

  const ClBottomNavBar({
    super.key,

  });
  @override
  State<ClBottomNavBar> createState() => _ClBottomNavBarState();
}

class _ClBottomNavBarState extends State<ClBottomNavBar> {
 int currentIndex = 0; 

  @override
  Widget build(BuildContext context) {

    void changeTab(int index) {
    switch(index){
      case 0:  
        context.go('/home');
        break;
      case 1:  
        context.go('/discover');
        break;
      case 2:  
        context.go('/suggest');
        break;
      case 3:  
        context.go('/allCommunities');
        break;
        case 4:  
        context.go('/profile');
        break;
      default:
        context.go('/');
        break;
    }
    setState(() {
      currentIndex = index;
    });
  }

    return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: changeTab,
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
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
    );
    
  }
}

// bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 2,
//         backgroundColor: AppColors.darkBackground,
//         selectedItemColor: AppColors.accent,
//         unselectedItemColor: AppColors.darkTextSecondary,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_outlined),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_circle_outline),
//             label: "Suggest",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.group_outlined),
//             label: "Clubs",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline),
//             label: "Profile",
//           ),
//         ],
//       ),