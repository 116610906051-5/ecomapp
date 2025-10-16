import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/home_page.dart';
import '../pages/product_list_page.dart';
import '../pages/cart_page.dart';
import '../pages/profile_page.dart';
import '../pages/admin_dashboard_page.dart';
import '../providers/auth_provider.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    HomePage(),
    ProductListPage(),
    CartPage(),
    ProfilePage(),
    AdminDashboardPage(), // เพิ่มหน้า Admin Dashboard
  ];

  // ตรวจสอบว่าผู้ใช้เป็น admin หรือไม่
  bool _isAdmin(String? email) {
    if (email == null) return false;
    final adminEmails = [
      'admin@appecom.com',
      'owner@appecom.com',
      'pang@gmail.com',
    ];
    return adminEmails.contains(email.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final firebaseUser = authProvider.user;
        
        // ตรวจสอบว่าเป็น admin หรือไม่
        bool isAdmin = false;
        if (user != null && _isAdmin(user.email)) {
          isAdmin = true;
        } else if (firebaseUser != null && _isAdmin(firebaseUser.email)) {
          isAdmin = true;
        }
        
        // สร้าง navigation items ตามสิทธิ์ผู้ใช้
        List<BottomNavigationBarItem> navItems = [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];
        
        // เพิ่ม Admin tab หากเป็น admin
        if (isAdmin) {
          navItems.add(
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          );
        }

        return Scaffold(
          body: _currentIndex < _pages.length ? _pages[_currentIndex] : _pages[0],
          bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Color(0xFF6366F1),
          unselectedItemColor: Color(0xFF94A3B8),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: navItems,
        ),
      ),
        );
      },
    );
  }
}
