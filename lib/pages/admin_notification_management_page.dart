import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/advanced_notification_service.dart';
import '../services/order_notification_service.dart';

class AdminNotificationManagementPage extends StatefulWidget {
  @override
  State<AdminNotificationManagementPage> createState() => _AdminNotificationManagementPageState();
}

class _AdminNotificationManagementPageState extends State<AdminNotificationManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการการแจ้งเตือน'),
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'ระบบการแจ้งเตือน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'จัดการและทดสوบระบบการแจ้งเตือน FCM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // FCM Information Card
            _buildInfoCard(
              title: 'ข้อมูล FCM Configuration',
              icon: Icons.info_outline,
              color: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Sender ID', AdvancedNotificationService.senderId),
                  SizedBox(height: 8),
                  _buildInfoRow('VAPID Key', '${AdvancedNotificationService.vapidKey.substring(0, 30)}...'),
                  SizedBox(height: 8),
                  _buildInfoRow(
                    'FCM Token', 
                    AdvancedNotificationService.fcmToken?.substring(0, 30) ?? 'ไม่พบ Token'
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Test Notifications Section
            _buildInfoCard(
              title: 'ทดสอบการแจ้งเตือน',
              icon: Icons.play_circle_outline,
              color: Colors.green,
              child: Column(
                children: [
                  _buildActionButton(
                    title: 'ทดสอบการแจ้งเตือนพื้นฐาน',
                    subtitle: 'ส่งการแจ้งเตือนทดสอบทั่วไป',
                    icon: Icons.notification_important,
                    color: Colors.orange,
                    onTap: _sendTestNotification,
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    title: 'ทดสอบการแจ้งเตือนแชท',
                    subtitle: 'จำลองข้อความแชทใหม่',
                    icon: Icons.chat_bubble_outline,
                    color: Colors.blue,
                    onTap: _sendTestChatNotification,
                  ),
                  SizedBox(height: 12),
                  _buildActionButton(
                    title: 'ทดสอบการแจ้งเตือนคำสั่งซื้อ',
                    subtitle: 'จำลองอัปเดตสถานะสินค้า',
                    icon: Icons.shopping_cart_outlined,
                    color: Colors.purple,
                    onTap: _sendTestOrderNotification,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Notification History Card
            _buildInfoCard(
              title: 'ประวัติการแจ้งเตือน',
              icon: Icons.history,
              color: Colors.indigo,
              child: Container(
                height: 200,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('notifications')
                      .orderBy('createdAt', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'ยังไม่มีการแจ้งเตือน',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final notification = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        final createdAt = notification['createdAt'] as Timestamp?;
                        
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: _getNotificationColor(notification['type']),
                            child: Icon(
                              _getNotificationIcon(notification['type']),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            notification['title'] ?? 'ไม่มีหัวข้อ',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            notification['body'] ?? 'ไม่มีเนื้อหา',
                            style: TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            createdAt != null 
                                ? _formatTime(createdAt.toDate())
                                : 'ไม่ทราบเวลา',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: 16),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.startsWith('✅') ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: _statusMessage.startsWith('✅') ? Colors.green : Colors.red,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.startsWith('✅') ? Colors.green[800] : Colors.red[800],
                    fontSize: 14,
                  ),
                ),
              ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 20,
              child: _isLoading 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 20),
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
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังส่งการแจ้งเตือนทดสอบ...';
    });

    try {
      await AdvancedNotificationService.sendTestNotification();
      setState(() {
        _statusMessage = '✅ ส่งการแจ้งเตือนทดสอบสำเร็จ!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  Future<void> _sendTestChatNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังส่งการแจ้งเตือนแชททดสอบ...';
    });

    try {
      await AdvancedNotificationService.sendChatNotification(
        toUserId: 'test_user',
        fromUserName: 'ระบบทดสอบ',
        message: 'นี่คือการทดสอบการแจ้งเตือนแชท 💬',
        chatRoomId: 'test_chat_${DateTime.now().millisecondsSinceEpoch}',
      );
      setState(() {
        _statusMessage = '✅ ส่งการแจ้งเตือนแชททดสอบสำเร็จ!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  Future<void> _sendTestOrderNotification() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังส่งการแจ้งเตือนคำสั่งซื้อทดสอบ...';
    });

    try {
      await AdvancedNotificationService.sendOrderStatusNotification(
        toUserId: 'test_user',
        orderId: 'TEST_ORDER_${DateTime.now().millisecondsSinceEpoch}',
        status: 'shipped',
        productName: 'iPhone 15 Pro Max - สีไทเทเนียมธรรมชาติ',
      );
      
      await OrderNotificationService.notifyNewOrder(
        orderId: 'NEW_ORDER_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'ลูกค้าทดสอบ',
        productName: 'MacBook Pro M3',
        totalAmount: 89900.00,
      );
      
      setState(() {
        _statusMessage = '✅ ส่งการแจ้งเตือนคำสั่งซื้อทดสอบสำเร็จ!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = '';
          });
        }
      });
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'chat': return Colors.blue;
      case 'order_status': return Colors.green;
      case 'new_order': return Colors.purple;
      case 'low_stock': return Colors.orange;
      case 'new_review': return Colors.amber;
      default: return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'chat': return Icons.chat_bubble;
      case 'order_status': return Icons.shopping_cart;
      case 'new_order': return Icons.shopping_bag;
      case 'low_stock': return Icons.warning;
      case 'new_review': return Icons.star;
      default: return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
