import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class MiqraBottomNav extends StatelessWidget {
  final String currentLocation;
  final Function(String path) onTabSelected;

  const MiqraBottomNav({
    super.key,
    required this.currentLocation,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(),
      onTap: (index) {
        final path = _getPathForIndex(index);
        onTabSelected(path);
      },
      selectedItemColor: miqraPrimary,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.trending_up),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.menu_book,
            size: 28,
          ),
          label: 'Read',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Group',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getCurrentIndex() {
    switch (currentLocation) {
      case '/':
        return 0;
      case '/progress':
        return 1;
      case '/read':
        return 2;
      case '/group':
        return 3;
      case '/profile':
        return 4;
      default:
        if (currentLocation.startsWith('/read/')) {
          return 2;
        }
        return 0;
    }
  }

  String _getPathForIndex(int index) {
    switch (index) {
      case 0:
        return '/';
      case 1:
        return '/progress';
      case 2:
        return '/read';
      case 3:
        return '/group';
      case 4:
        return '/profile';
      default:
        return '/';
    }
  }
}


