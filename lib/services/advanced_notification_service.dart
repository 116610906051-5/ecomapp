import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_settings_service.dart';

/// ระบบการแจ้งเตือนด้วย Firebase Cloud Messaging
/// รองรับการแจ้งเตือนสำหรับแชทและการอัปเดตสถานะสินค้า
class AdvancedNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // FCM Configuration
  static const String senderId = '236498123851';
  static const String vapidKey = 'BE5DRXtADIaD0JlnCnienovezvIoM5fKa27pJ5UyFeFbL6O_JWsUgwZdjuAhcK7lhQ6S3WSVHuhY7Q8Jy5004sY';
  
  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;
  
  // Navigation callbacks
  static Function(String, String)? onChatNotificationTap; // (chatRoomId, fromUserName)
  static Function(String, String)? onOrderNotificationTap; // (orderId, status)
  
  /// เริ่มต้นระบบการแจ้งเตือน
  static Future<void> initialize() async {
    print('🔔 Initializing advanced notification service...');
    
    try {
      // เริ่มต้น Local Notifications
      await _initializeLocalNotifications();
      
      // ขอสิทธิ์การแจ้งเตือน
      await _requestPermissions();
      
      // เริ่มต้น FCM
      await _initializeFirebaseMessaging();
      
      // รับ FCM token
      await _getFCMToken();
      
      print('✅ Advanced notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }
  
  /// ขอสิทธิ์การแจ้งเตือน
  static Future<void> _requestPermissions() async {
    // ขอสิทธิ์จากระบบปฏิบัติการ
    final permission = await Permission.notification.request();
    print('📱 System notification permission: $permission');
    
    // ขอสิทธิ์จาก Firebase
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 Firebase notification permission: ${settings.authorizationStatus}');
  }
  
  /// เริ่มต้น Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    // ตั้งค่าการแสดงการแจ้งเตือนตอนแอปเปิดอยู่
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // จัดการข้อความใน background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // จัดการข้อความตอนแอปเปิดอยู่
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // จัดการเมื่อคลิกที่การแจ้งเตือน
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // ตรวจสอบการแจ้งเตือนเมื่อเปิดแอป
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  
  /// รับ FCM token
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken(vapidKey: vapidKey);
      print('🔑 FCM Token: $_fcmToken');
      
      // ฟัง token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        print('🔄 FCM Token refreshed: $token');
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }
  
  /// จัดการข้อความตอนแอปเปิดอยู่
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message received:');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    print('   Data: ${message.data}');
    
    // Firebase จะแสดงการแจ้งเตือนอัตโนมัติ
    print('📱 System notification displayed automatically');
  }
  
  /// จัดการเมื่อคลิกที่การแจ้งเตือน
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.data}');
    
    final type = message.data['type'];
    
    if (type == 'chat') {
      final chatRoomId = message.data['chatRoomId'];
      final fromUserName = message.data['fromUserName'];
      if (chatRoomId != null && onChatNotificationTap != null) {
        onChatNotificationTap!(chatRoomId, fromUserName ?? '');
      }
    } else if (type == 'order_status') {
      final orderId = message.data['orderId'];
      final status = message.data['status'];
      if (orderId != null && onOrderNotificationTap != null) {
        onOrderNotificationTap!(orderId, status ?? '');
      }
    }
  }
  
  /// ส่งการแจ้งเตือนข้อความแชทใหม่
  static Future<void> sendChatNotification({
    required String toUserId,
    required String fromUserName,
    required String message,
    required String chatRoomId,
    String? fromUserImage,
  }) async {
    try {
      print('📤 Sending chat notification to $toUserId');
      
      // ตรวจสอบการตั้งค่าการแจ้งเตือน
      final shouldSend = await NotificationSettingsService.shouldSendNotification('chat');
      if (!shouldSend) {
        print('🚫 Chat notifications are disabled');
        return;
      }
      
      // ดึง FCM token ของผู้รับ
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) {
        print('⚠️ No FCM token found for user $toUserId');
        return;
      }
      
      // ส่งการแจ้งเตือนแชทจริง
      await _sendLocalNotification(
        title: '💬 ข้อความใหม่จาก $fromUserName',
        body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
        data: {
          'type': 'chat',
          'chatRoomId': chatRoomId,
          'fromUserName': fromUserName,
          'fromUserImage': fromUserImage ?? '',
        },
      );
      
      print('✅ Chat notification sent successfully');
    } catch (e) {
      print('❌ Error sending chat notification: $e');
    }
  }
  
  /// ส่งการแจ้งเตือนการอัปเดตสถานะสินค้า
  static Future<void> sendOrderStatusNotification({
    required String toUserId,
    required String orderId,
    required String status,
    required String productName,
    String? productImage,
  }) async {
    try {
      print('📤 Sending order status notification to $toUserId');
      
      // ตรวจสอบการตั้งค่าการแจ้งเตือน
      final shouldSend = await NotificationSettingsService.shouldSendNotification('order_status');
      if (!shouldSend) {
        print('🚫 Order status notifications are disabled');
        return;
      }
      
      // ดึง FCM token ของผู้รับ
      final userDoc = await _firestore.collection('users').doc(toUserId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) {
        print('⚠️ No FCM token found for user $toUserId');
        return;
      }
      
      String statusText = _getStatusText(status);
      String emoji = _getStatusEmoji(status);
      
      // ส่งการแจ้งเตือน local notification
      await _sendLocalNotification(
        title: '$emoji อัปเดตสถานะคำสั่งซื้อ',
        body: '$productName - $statusText',
        data: {
          'type': 'order_status',
          'orderId': orderId,
          'status': status,
          'productName': productName,
          'productImage': productImage ?? '',
        },
      );
      
      print('✅ Order status notification sent successfully');
    } catch (e) {
      print('❌ Error sending order status notification: $e');
    }
  }
  


  /// ส่งการแจ้งเตือน Local Notification จริง
  static Future<void> _sendLocalNotification({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    print('🔔 Sending local notification:');
    print('   📱 Title: $title');
    print('   💬 Body: $body');
    print('   📊 Data: $data');
    
    try {
      // เลือก channel ตามประเภท notification
      final isChat = data['type'] == 'chat';
      final channelId = isChat ? 'chat_messages' : 'order_updates';
      final channelName = isChat ? 'Chat Messages' : 'Order Updates';
      final channelDesc = isChat 
          ? 'Notifications for chat messages'
          : 'Notifications for order status updates';
      
      // กำหนดค่า Android notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      // กำหนดค่า iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default.wav',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ส่งการแจ้งเตือน local notification
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // สร้าง payload ที่มีข้อมูลครบถ้วน
      final payloadData = {
        'type': data['type'],
        'id': isChat ? data['chatRoomId'] : data['orderId'],
        'fromUserName': data['fromUserName'] ?? '',
      };
      final payload = payloadData.entries.map((e) => '${e.key}:${e.value}').join('|');
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      // ส่งการแจ้งเตือนแบบ foreground เพิ่มเติม (สำหรับ in-app)
      final message = RemoteMessage(
        messageId: 'local_${DateTime.now().millisecondsSinceEpoch}',
        data: data,
        notification: RemoteNotification(
          title: title,
          body: body,
          android: AndroidNotification(
            channelId: data['type'] == 'chat' ? 'chat_messages' : 'order_updates',
            priority: AndroidNotificationPriority.highPriority,
          ),
          apple: AppleNotification(
            subtitle: data['type'] == 'chat' ? 'แชท' : 'คำสั่งซู้อ',
          ),
        ),
      );
      
      await _handleForegroundMessage(message);
      
      print('✅ Local notification sent successfully');
    } catch (e) {
      print('❌ Error sending local notification: $e');
    }
  }
  
  /// อัปเดต FCM token ใน Firestore
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
  
  /// ส่งการแจ้งเตือนทดสอบ
  static Future<void> sendTestNotification() async {
    print('🧪 Sending test notification...');
    
    try {
      await _sendLocalNotification(
        title: '🔔 ทดสอบระบบการแจ้งเตือน',
        body: 'ระบบการแจ้งเตือนทำงานได้ปกติแล้ว!',
        data: {
          'type': 'test',
          'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      
      print('✅ Test notification sent successfully');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }
  
  /// แปลงสถานะเป็นข้อความไทย
  static String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'รอการยืนยัน';
      case 'packing': return 'กำลังเตรียมสินค้า';
      case 'processing': return 'กำลังจัดส่ง';
      case 'shipped': return 'ออกจากคลังแล้ว';
      case 'delivered': return 'จัดส่งสำเร็จ';
      case 'cancelled': return 'ยกเลิกแล้ว';
      default: return status;
    }
  }
  
  /// ดึง emoji ตามสถานะ
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
  
  /// ล้าง notification badge
  static Future<void> clearBadge() async {
    try {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: false,
        sound: true,
      );
      print('✅ Notification badge cleared');
    } catch (e) {
      print('❌ Error clearing badge: $e');
    }
  }

  /// เริ่มต้น Local Notifications
  static Future<void> _initializeLocalNotifications() async {
    // กำหนดค่าสำหรับ Android
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // กำหนดค่าสำหรับ iOS
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // การตั้งค่ารวม
    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );
    
    // เริ่มต้น plugin
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // สร้าง notification channels สำหรับ Android
    await _createNotificationChannels();
  }

  /// สร้าง Notification Channels สำหรับ Android
  static Future<void> _createNotificationChannels() async {
    const orderChannel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Notifications for order status updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    const chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages', 
      description: 'Notifications for chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);
        
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(chatChannel);
  }

  /// จัดการเมื่อผู้ใช้แตะการแจ้งเตือน
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('📱 Notification tapped with payload: $payload');
      
      try {
        // แยกข้อมูลจาก payload
        final parts = payload.split('|');
        final data = <String, String>{};
        for (final part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            data[keyValue[0]] = keyValue[1];
          }
        }
        
        final type = data['type'];
        final id = data['id'];
        
        if (type == 'chat' && id != null) {
          // เรียกใช้ callback สำหรับแชท
          if (onChatNotificationTap != null) {
            final fromUserName = data['fromUserName'] ?? 'Unknown';
            onChatNotificationTap!(id, fromUserName);
          }
        } else if (type == 'order_status' && id != null) {
          // เรียกใช้ callback สำหรับออเดอร์
          if (onOrderNotificationTap != null) {
            onOrderNotificationTap!(id, 'status_update');
          }
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }
}

/// Background message handler (ต้องเป็นฟังก์ชันระดับ top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message received: ${message.messageId}');
  print('📱 Background notification displayed automatically');
}
