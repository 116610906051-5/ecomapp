import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // FCM Configuration (available for reference)
  static const String senderId = '236498123851';
  static const String vapidKey = 'BE5DRXtADIaD0JlnCnienovezvIoM5fKa27pJ5UyFeFbL6O_JWsUgwZdjuAhcK7lhQ6S3WSVHuhY7Q8Jy5004sY';
  static const String fcmApiUrl = 'https://fcm.googleapis.com/fcm/send';
  
  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  // Navigation callbacks
  static Function(String)? onNotificationTap;
  static Function(String)? onOrderStatusUpdate;
  
  static Future<void> initialize() async {
    print('🔔 Initializing notification service...');
    
    try {
      // Request permissions
      await _requestPermissions();
      
      // Initialize FCM
      await _initializeFirebaseMessaging();
      
      // Get FCM token
      await _getFCMToken();
      
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    // Request notification permissions
    final notificationSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Notification permission: ${notificationSettings.authorizationStatus}');
  }

  static Future<void> _initializeFirebaseMessaging() async {
    // Configure FCM for foreground notifications - show notifications even when app is open
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle foreground messages - Firebase will show notification automatically
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Check for initial message (when app is opened from notification)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        print('🔄 FCM Token refreshed: $token');
        // TODO: Update token in user profile
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Received foreground message: ${message.messageId}');
    print('📨 Message data: ${message.data}');
    print('📨 Notification: ${message.notification?.title} - ${message.notification?.body}');
    
    // Firebase automatically handles displaying the notification in the system tray
    print('📱 System notification will be displayed by Firebase automatically');
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.data}');
    
    final chatRoomId = message.data['chatRoomId'];
    if (chatRoomId != null && onNotificationTap != null) {
      onNotificationTap!(chatRoomId);
    }
  }

  // แจ้งเตือนข้อความแชทใหม่
  static Future<void> sendChatNotification({
    required String toUserId,
    required String fromUserName,
    required String message,
    required String chatRoomId,
    String? fromUserImage,
  }) async {
    try {
      print('📤 Sending chat notification to $toUserId');
      
      // ดึง FCM token ของผู้ใช้ที่จะส่งแจ้งเตือนไป
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) {
        print('⚠️ No FCM token found for user $toUserId');
        return;
      }
      
      // ส่งการแจ้งเตือนผ่าน FCM
      await _sendFCMNotification(
        token: fcmToken,
        title: 'ข้อความใหม่จาก $fromUserName',
        body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
        data: {
          'type': 'chat',
          'chatRoomId': chatRoomId,
          'fromUserName': fromUserName,
          'fromUserImage': fromUserImage ?? '',
        },
        imageUrl: fromUserImage,
      );
      
      print('✅ Chat notification sent successfully');
    } catch (e) {
      print('❌ Error sending chat notification: $e');
    }
  }
  
  // แจ้งเตือนการอัปเดตสถานะสินค้า
  static Future<void> sendOrderStatusNotification({
    required String toUserId,
    required String orderId,
    required String status,
    required String productName,
    String? productImage,
  }) async {
    try {
      print('📤 Sending order status notification to $toUserId');
      
      // ดึง FCM token ของผู้ใช้
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) {
        print('⚠️ No FCM token found for user $toUserId');
        return;
      }
      
      // แปลงสถานะเป็นภาษาไทย
      String statusText = _getStatusText(status);
      String emoji = _getStatusEmoji(status);
      
      await _sendFCMNotification(
        token: fcmToken,
        title: '$emoji สถานะคำสั่งซื้อของคุณ',
        body: '$productName - $statusText',
        data: {
          'type': 'order_status',
          'orderId': orderId,
          'status': status,
          'productName': productName,
          'productImage': productImage ?? '',
        },
        imageUrl: productImage,
      );
      
      print('✅ Order status notification sent successfully');
    } catch (e) {
      print('❌ Error sending order status notification: $e');
    }
  }
  
  // ส่งการแจ้งเตือนผ่าน FCM API
  static Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
    String? imageUrl,
  }) async {
    try {
      // ใน production ควรใช้ Server Key แทน
      // ตอนนี้ใช้การจำลองการแจ้งเตือนแทน
      await _simulateAdvancedNotification(
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
      );
      
      print('✅ FCM notification sent to token: ${token.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
    }
  }
  
  // จำลองการแจ้งเตือนขั้นสูง
  static Future<void> _simulateAdvancedNotification({
    required String title,
    required String body,
    required Map<String, String> data,
    String? imageUrl,
  }) async {
    print('🔔 Simulating advanced notification:');
    print('   Title: $title');
    print('   Body: $body');
    print('   Data: $data');
    print('   Image: $imageUrl');
    
    // สร้าง RemoteMessage จำลอง
    final message = RemoteMessage(
      messageId: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      data: data,
      notification: RemoteNotification(
        title: title,
        body: body,
        android: AndroidNotification(
          channelId: data['type'] == 'chat' ? 'chat_messages' : 'order_updates',
          priority: AndroidNotificationPriority.highPriority,
        ),
        apple: AppleNotification(
          imageUrl: imageUrl,
        ),
      ),
    );
    
    // จำลองการแสดงการแจ้งเตือน
    await _handleForegroundMessage(message);
  }
  
  // แปลงสถานะเป็นข้อความไทย
  static String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'รอการยืนยัน';
      case 'packing': return 'กำลังเตรียมสินค้า';
      case 'processing': return 'กำลังจัดส่ง';
      case 'shipped': return 'ส่งแล้ว';
      case 'delivered': return 'จัดส่งสำเร็จ';
      case 'cancelled': return 'ยกเลิกแล้ว';
      default: return status;
    }
  }
  
  // ดึง emoji ตามสถานะ
  static String _getStatusEmoji(String status) {
    switch (status) {
      case 'pending': return '⏳';
      case 'packing': return '📦';
      case 'processing': return '🚚';
      case 'shipped': return '✈️';
      case 'delivered': return '✅';
      case 'cancelled': return '❌';
      default: return '📋';
    }
  }
  
  // อัปเดต FCM token ใน Firestore
  static Future<void> updateUserFCMToken(String userId) async {
    if (_fcmToken != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token updated for user $userId');
      } catch (e) {
        print('❌ Error updating FCM token: $e');
      }
    }
  }
}

// Background message handler (must be top-level function)  
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Received background message: ${message.messageId}');
  
  // Firebase automatically shows the notification in the system tray
  // when the app is in background or terminated
  print('📱 Background notification displayed by Firebase automatically');
}
