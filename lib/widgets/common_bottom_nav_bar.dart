import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CommonBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CommonBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) async {
          if (onTap != null) {
            onTap!(index);
            return;
          }

          // Default navigation logic
          await _handleNavigation(context, index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE20035),
        unselectedItemColor: const Color(0xFF8E8E93),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Bookmark',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Future<void> _handleNavigation(BuildContext context, int index) async {
    // Prevent navigation if already on the same tab
    if (index == currentIndex) {
      return;
    }

    switch (index) {
      case 0: // Home
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        break;

      case 1: // Explore
        Navigator.of(context).pushNamed('/explore');
        break;

      case 2: // Bookmark
        // TODO: Implement bookmark screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bookmark feature coming soon'),
            backgroundColor: Colors.orange.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        break;

      case 3: // Notifications
        // TODO: Implement notifications screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications feature coming soon'),
            backgroundColor: Colors.orange.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        break;

      case 4: // Account
        // Check if user is logged in before navigating to profile
        final authService = AuthService();
        final isLoggedIn = await authService.isLoggedIn();

        if (!context.mounted) return;

        if (!isLoggedIn) {
          // Not logged in, redirect to login
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng đăng nhập để xem thông tin tài khoản'),
              backgroundColor: Colors.orange.shade900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
          return;
        }

        // User is logged in, navigate to profile
        Navigator.of(context).pushNamed('/profile');
        break;
    }
  }
}

