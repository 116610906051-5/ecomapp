import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/advanced_notification_service.dart';
import 'services/order_notification_service.dart';

class DebugLoginPage extends StatefulWidget {
  const DebugLoginPage({super.key});

  @override
  State<DebugLoginPage> createState() => _DebugLoginPageState();
}

class _DebugLoginPageState extends State<DebugLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';

  @override
  void initState() {
    super.initState();
    // Set admin credentials for testing
    _emailController.text = 'pang@gmail.com';
    _passwordController.text = '';
  }

  Future<void> _testDirectLogin() async {
    try {
      setState(() {
        _message = 'Attempting direct Firebase login...';
      });

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      setState(() {
        _message = 'SUCCESS! Logged in as: ${userCredential.user?.email}';
      });
    } catch (e) {
      setState(() {
        _message = 'ERROR: $e';
      });
    }
  }

  Future<void> _testListUsers() async {
    try {
      setState(() {
        _message = 'Checking current user...';
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _message = 'Already signed in: ${currentUser.email}';
        });
      } else {
        setState(() {
          _message = 'No user currently signed in';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'ERROR checking user: $e';
      });
    }
  }

  Future<void> _updateAdminRoles() async {
    try {
      setState(() {
        _message = 'กำลังอัปเดต role สำหรับ admin...';
      });

      final adminEmails = [
        'pang@gmail.com',
        'p@p.com',
        'test1@gmail.com',
        'admin@appecom.com',
        'owner@appecom.com',
      ];

      final firestore = FirebaseFirestore.instance;
      List<String> results = [];

      for (String email in adminEmails) {
        final querySnapshot = await firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

        if (querySnapshot.docs.isEmpty) {
          results.add('⚠️ ไม่พบ: $email');
          continue;
        }

        for (var doc in querySnapshot.docs) {
          await doc.reference.update({'role': 'admin'});
          results.add('✅ อัปเดต: $email');
        }
      }

      setState(() {
        _message = results.join('\n');
      });
    } catch (e) {
      setState(() {
        _message = 'ERROR: $e';
      });
    }
  }

  Future<void> _checkUserRole() async {
    try {
      setState(() {
        _message = 'กำลังตรวจสอบ role ของผู้ใช้...';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _message = 'ไม่มีผู้ใช้ล็อกอิน';
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        setState(() {
          _message = 'ไม่พบข้อมูลผู้ใช้ใน Firestore';
        });
        return;
      }

      final data = doc.data();
      final role = data?['role'] ?? 'ไม่มี role';
      final email = data?['email'] ?? 'ไม่มี email';
      final name = data?['name'] ?? 'ไม่มีชื่อ';

      setState(() {
        _message = '''
ผู้ใช้ปัจจุบัน:
- ชื่อ: $name
- Email: $email
- Role: $role
- UID: ${user.uid}
        ''';
      });
    } catch (e) {
      setState(() {
        _message = 'ERROR: $e';
      });
    }
  }

  Future<void> _testNotifications() async {
    try {
      setState(() {
        _message = 'กำลังทดสอบระบบการแจ้งเตือน...';
      });

      // ทดสอบการแจ้งเตือนพื้นฐาน
      await AdvancedNotificationService.sendTestNotification();
      
      setState(() {
        _message = '✅ ทดสอบการแจ้งเตือนสำเร็จ!\nตรวจสอบแถบการแจ้งเตือนของระบบ';
      });
    } catch (e) {
      setState(() {
        _message = '❌ เกิดข้อผิดพลาดในการทดสอบ: $e';
      });
    }
  }

  Future<void> _testChatNotification() async {
    try {
      setState(() {
        _message = 'กำลังทดสอบการแจ้งเตือนแชท...';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _message = 'กรุณาล็อกอินก่อนทดสอบ';
        });
        return;
      }

      await AdvancedNotificationService.sendChatNotification(
        toUserId: user.uid,
        fromUserName: 'ระบบทดสอบ',
        message: 'สวัสดีครับ! นี่คือการทดสอบการแจ้งเตือนแชท 💬',
        chatRoomId: 'test_chat_${DateTime.now().millisecondsSinceEpoch}',
        fromUserImage: null,
      );
      
      setState(() {
        _message = '✅ ทดสอบการแจ้งเตือนแชทสำเร็จ!\nคุณควรเห็นการแจ้งเตือนแชทในระบบ';
      });
    } catch (e) {
      setState(() {
        _message = '❌ เกิดข้อผิดพลาดในการทดสอบแชท: $e';
      });
    }
  }

  Future<void> _testOrderNotification() async {
    try {
      setState(() {
        _message = 'กำลังทดสอบการแจ้งเตือนคำสั่งซื้อ...';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _message = 'กรุณาล็อกอินก่อนทดสอบ';
        });
        return;
      }

      // ทดสอบการแจ้งเตือนสถานะคำสั่งซื้อ
      await AdvancedNotificationService.sendOrderStatusNotification(
        toUserId: user.uid,
        orderId: 'TEST_ORDER_${DateTime.now().millisecondsSinceEpoch}',
        status: 'shipped',
        productName: 'สินค้าทดสอบ - iPhone 15 Pro Max',
        productImage: null,
      );

      // ทดสอบการแจ้งเตือนคำสั่งซื้อใหม่ (สำหรับ admin)
      await OrderNotificationService.notifyNewOrder(
        orderId: 'NEW_ORDER_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'ลูกค้าทดสอบ',
        productName: 'MacBook Pro M3',
        totalAmount: 89900.00,
      );
      
      setState(() {
        _message = '''✅ ทดสอบการแจ้งเตือนคำสั่งซื้อสำเร็จ!

ทดสอบ:
- การแจ้งเตือนสถานะสินค้า (สำหรับลูกค้า)
- การแจ้งเตือนคำสั่งซื้อใหม่ (สำหรับแอดมิน)

ตรวจสอบการแจ้งเตือนในระบบ''';
      });
    } catch (e) {
      setState(() {
        _message = '❌ เกิดข้อผิดพลาดในการทดสอบคำสั่งซื้อ: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Login'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testDirectLogin,
              child: const Text('Test Direct Login'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testListUsers,
              child: const Text('Check Current User'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {
                  _message = 'Signed out';
                });
              },
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateAdminRoles,
              child: const Text('Update Admin Roles'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkUserRole,
              child: const Text('Check User Role'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Notifications'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testChatNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Chat Notification'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testOrderNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Order Notification'),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
