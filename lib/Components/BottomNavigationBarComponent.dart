import 'package:flutter/material.dart';
import '../Utils/Utils.dart';
import '../services/auth_service.dart';

class BottomNavigationBarComponent extends StatelessWidget {
  const BottomNavigationBarComponent({super.key});

  void _tabItemClick(int index) async {
    Utils.selectIndex = index;
    BuildContext context = Utils.navigatorKey.currentContext!;

    switch (index) {
      case 0: // Home
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        break;

      case 1: // Explore
        Navigator.of(context).pushNamed('/explore');
        break;

      case 2: // Bookmark
        Navigator.of(context).pushNamed('/bookmark');
        break;

      case 3: // Account
        final authService = AuthService();
        final isLoggedIn = await authService.isLoggedIn();

        if (!context.mounted) return;

        if (!isLoggedIn) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vui lòng đăng nhập để xem thông tin tài khoản'),
              backgroundColor: Colors.orange.shade900,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return;
        }

        Navigator.of(context).pushNamed('/profile');
        break;
    }
  }

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
        currentIndex: Utils.selectIndex,
        onTap: (index) => _tabItemClick(index),
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
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Lưu trữ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
