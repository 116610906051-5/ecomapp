import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/notification_badge.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Profile Image and Edit Button
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.currentUser;
                      final firebaseUser = authProvider.user;
                      
                      return Column(
                        children: [
                          // Display Name
                          Text(
                            user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'ผู้ใช้งาน',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Email
                          Text(
                            firebaseUser?.email ?? user?.email ?? 'ไม่มีอีเมล',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          SizedBox(height: 8),
                          // User Status
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'กำลังออนไลน์',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('15', 'Orders'),
                      _buildStatItem('4.8', 'Rating'),
                      _buildStatItem('2', 'Years'),
                    ],
                  ),
                ],
              ),
            ),

            // Account Information Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final user = authProvider.currentUser;
                  final firebaseUser = authProvider.user;
                  
                  return Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_circle,
                              color: Color(0xFF6366F1),
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'ข้อมูลบัญชี',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildAccountInfoRow('ชื่อผู้ใช้', user?.displayName ?? user?.name ?? firebaseUser?.displayName ?? 'ยังไม่ได้ตั้งชื่อ'),
                        _buildAccountInfoRow('อีเมล', firebaseUser?.email ?? user?.email ?? 'ไม่มีอีเมล'),
                        _buildAccountInfoRow('UID', firebaseUser?.uid ?? 'ไม่มี UID'),
                        _buildAccountInfoRow('สถานะการยืนยัน', firebaseUser?.emailVerified == true ? 'ยืนยันแล้ว ✅' : 'ยังไม่ได้ยืนยัน ⚠️'),
                        _buildAccountInfoRow('เข้าร่วมเมื่อ', firebaseUser?.metadata.creationTime != null 
                          ? _formatDate(firebaseUser!.metadata.creationTime!) 
                          : 'ไม่ทราบ'),
                        _buildAccountInfoRow('เข้าสู่ระบบล่าสุด', firebaseUser?.metadata.lastSignInTime != null 
                          ? _formatDate(firebaseUser!.metadata.lastSignInTime!) 
                          : 'ไม่ทราบ'),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 24),

            // Menu Items
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Account Section
                  _buildSectionHeader('Account'),
                  SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.person_outline,
                    'Personal Information',
                    'Update your details and preferences',
                    () => Navigator.pushNamed(context, '/personal-information'),
                  ),
                  _buildMenuItem(
                    Icons.location_on_outlined,
                    'Addresses',
                    'Manage your delivery addresses',
                    () => Navigator.pushNamed(context, '/addresses'),
                  ),
                  _buildMenuItem(
                    Icons.credit_card_outlined,
                    'Payment Methods',
                    'Add or remove payment methods',
                    () => _showComingSoon(context),
                  ),

                  SizedBox(height: 24),

                  // Orders Section
                  _buildSectionHeader('Orders'),
                  SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.shopping_bag_outlined,
                    'My Orders',
                    'Track your current and past orders',
                    () => Navigator.pushNamed(context, '/my-orders'),
                  ),
                  _buildMenuItem(
                    Icons.favorite_outline,
                    'Wishlist',
                    'View your saved items',
                    () => Navigator.pushNamed(context, '/wishlist'),
                  ),
                  _buildMenuItem(
                    Icons.history,
                    'Order History',
                    'See all your previous purchases',
                    () => Navigator.pushNamed(context, '/order-history'),
                  ),

                  SizedBox(height: 24),

                  // Support Section
                  _buildSectionHeader('Support'),
                  SizedBox(height: 12),
                  _buildMenuItem(
                    Icons.help_outline,
                    'Help Center',
                    'Get help with your orders and account',
                    () => _showComingSoon(context),
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return _buildMenuItem(
                        Icons.chat,
                        'Live Chat',
                        'Chat with our support team in real-time',
                        () => Navigator.pushNamed(context, '/live-chat'),
                        showBadge: true,
                      );
                    },
                  ),
                  _buildMenuItem(
                    Icons.chat_bubble_outline,
                    'Contact Us',
                    'Reach out to our support team',
                    () => Navigator.pushNamed(context, '/contact-us'),
                  ),
                  _buildMenuItem(
                    Icons.history_outlined,
                    'My Contacts',
                    'View your contact history',
                    () => Navigator.pushNamed(context, '/my-contacts'),
                  ),
                  _buildMenuItem(
                    Icons.star_outline,
                    'Rate Our App',
                    'Share your experience with others',
                    () => _showComingSoon(context),
                  ),

                  SizedBox(height: 24),

                  // Settings Section
                  _buildSectionHeader('Settings'),
                  SizedBox(height: 12),
                  
                  // Admin Dashboard - แสดงเฉพาะสำหรับ admin
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.currentUser;
                      if (user != null && _isAdmin(user.email)) {
                        return Column(
                          children: [
                            _buildMenuItem(
                              Icons.admin_panel_settings,
                              'Admin Dashboard',
                              'จัดการร้านค้าและสินค้า',
                              () => Navigator.pushNamed(context, '/admin'),
                              color: Color(0xFF6366F1),
                            ),
                            _buildMenuItem(
                              Icons.support_agent,
                              'Chat Management',
                              'จัดการแชทจากลูกค้า',
                              () => Navigator.pushNamed(context, '/admin-chat'),
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(height: 8),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                  
                  _buildMenuItem(
                    Icons.notifications_outlined,
                    'Notifications',
                    'Manage your notification preferences',
                    () => _showNotificationSettings(context),
                  ),
                  _buildMenuItem(
                    Icons.language_outlined,
                    'Language',
                    'Change your app language',
                    () => _showComingSoon(context),
                  ),
                  _buildMenuItem(
                    Icons.security_outlined,
                    'Privacy & Security',
                    'Manage your privacy settings',
                    () => _showComingSoon(context),
                  ),
                  _buildMenuItem(
                    Icons.info_outline,
                    'About',
                    'Learn more about our app',
                    () => _showAboutDialog(context),
                  ),

                  SizedBox(height: 32),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showLogoutDialog(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // App Version
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color,
    bool showBadge = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (color ?? Color(0xFF6366F1)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: showBadge
                      ? NotificationBadge(
                          child: Icon(
                            icon,
                            color: color ?? Color(0xFF6366F1),
                            size: 20,
                          ),
                        )
                      : Icon(
                          icon,
                          color: color ?? Color(0xFF6366F1),
                          size: 20,
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Text('This feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20),
            _buildNotificationToggle('Order Updates', true),
            _buildNotificationToggle('Promotional Offers', false),
            _buildNotificationToggle('New Products', true),
            _buildNotificationToggle('Price Drops', false),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Save Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(String title, bool value) {
    return StatefulBuilder(
      builder: (context, setState) => Container(
        margin: EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            Switch(
              value: value,
              onChanged: (newValue) {
                setState(() {
                  value = newValue;
                });
              },
              activeColor: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About E-Commerce App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('A modern e-commerce app built with Flutter.'),
            SizedBox(height: 16),
            Text(
              '© 2025 E-Commerce App. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error logging out: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFEF4444)),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper method สำหรับแสดงข้อมูลบัญชี
  Widget _buildAccountInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method สำหรับจัดรูปแบบวันที่
  String _formatDate(DateTime dateTime) {
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year + 543}';
  }

  // ตรวจสอบว่าผู้ใช้เป็น admin หรือไม่
  bool _isAdmin(String email) {
    final adminEmails = [
      'admin@appecom.com',
      'owner@appecom.com',
      'pang@gmail.com', // เพิ่มบัญชีที่มีอยู่เป็น admin ด้วย
    ];
    return adminEmails.contains(email.toLowerCase());
  }
}
