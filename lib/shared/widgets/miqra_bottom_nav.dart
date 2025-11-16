import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/home.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/home.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              miqraPrimary,
              BlendMode.srcIn,
            ),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/progress.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/progress.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              miqraPrimary,
              BlendMode.srcIn,
            ),
          ),
          label: 'Progress',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/book.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/book.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              miqraPrimary,
              BlendMode.srcIn,
            ),
          ),
          label: 'Read',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/group.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/group.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              miqraPrimary,
              BlendMode.srcIn,
            ),
          ),
          label: 'Group',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/profile.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          activeIcon: SvgPicture.asset(
            'assets/icons/profile.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              miqraPrimary,
              BlendMode.srcIn,
            ),
          ),
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


