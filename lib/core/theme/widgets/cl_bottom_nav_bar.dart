import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClBottomNavBar extends StatefulWidget {

  const ClBottomNavBar({
    super.key, required this.child,

  });
  final Widget child;
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
        context.go('/movies');
        break;
      case 1:  
        context.go('/communities');
        break;
      case 2:  
        context.go('/Discussions');
        break;
      case 3:  
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

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: changeTab,
        type: BottomNavigationBarType.fixed,

        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_creation_outlined),
            label: 'Movies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            label: 'Communities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Discussions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
    
  }
}

