import 'package:firebase_messaging/firebase_messaging.dart';
//import 'dart:convert';
import 'chat_service.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  // Navigation callback
  static Function(String)? onNotificationTap;
  
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

  // Send notification to specific user
  static Future<void> sendChatNotification({
    required String toUserId,
    required String fromUserName,
    required String message,
    required String chatRoomId,
  }) async {
    print('📤 Sending notification to $toUserId: $fromUserName: $message');
    
    // In a real app, this would trigger a backend API to send FCM message
    // For now, we'll simulate it by triggering a fake message
    await _simulateNotification(
      title: 'ข้อความใหม่จาก $fromUserName',
      body: message,
      chatRoomId: chatRoomId,
      fromUserName: fromUserName,
    );
  }

  // Simulate a notification for testing purposes
  static Future<void> _simulateNotification({
    required String title,
    required String body,
    required String chatRoomId,
    required String fromUserName,
  }) async {
    // Create a simulated FCM message
    final simulatedMessage = RemoteMessage(
      messageId: 'simulated_${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'chatRoomId': chatRoomId,
        'fromUserName': fromUserName,
      },
      notification: RemoteNotification(
        title: title,
        body: body,
        android: AndroidNotification(
          channelId: 'chat_messages',
          priority: AndroidNotificationPriority.highPriority,
        ),
      ),
    );
    
    // Trigger the foreground message handler to simulate notification
    await _handleForegroundMessage(simulatedMessage);
  }

  // Send test notification - simulate real Firebase notification
  static Future<void> sendTestNotification() async {
    print('🧪 Sending test notification...');
    
    try {
      await _simulateNotification(
        title: 'ข้อความใหม่จาก ทีมงานสนับสนุน',
        body: 'สวัสดีครับ! นี่คือการทดสอบระบบการแจ้งเตือน 🔔',
        chatRoomId: 'test_chat_room_123',
        fromUserName: 'ทีมงานสนับสนุน',
      );
      
      print('📤 Test notification sent successfully');
      print('📱 Firebase will display the notification in the system tray!');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  // Clear notification badge when user reads messages
  static Future<void> clearNotificationBadge() async {
    try {
      // Clear Firebase badge count
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: false,
        sound: true,
      );
      
      print('✅ Notification badge cleared');
    } catch (e) {
      print('❌ Error clearing notification badge: $e');
    }
  }

  // Mark chat messages as read and clear badge
  static Future<void> markChatAsRead(String chatRoomId) async {
    print('👀 Marking chat $chatRoomId as read');
    
    // Clear the notification badge
    await clearNotificationBadge();
    
    // Mark messages as read in Firestore (isAdmin = false for customer)
    try {
      await ChatService.markMessagesAsRead(chatRoomId, false);
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
    
    print('✅ Chat marked as read and badge cleared');
  }

  // Clear all unread messages for current user
  static Future<void> clearAllUnreadMessages(String userId) async {
    print('🧹 Clearing all unread messages for user: $userId');
    
    try {
      // Clear the problematic room that's causing the red dot
      await ChatService.markMessagesAsRead('qUBZ3vW0ERjdDA9i9p3Y', false);
      
      print('✅ All unread messages cleared');
    } catch (e) {
      print('❌ Error clearing all unread messages: $e');
    }
  }

  // Update FCM token in user profile
  static Future<void> updateUserFCMToken(String userId) async {
    if (_fcmToken != null) {
      try {
        // TODO: Update user's FCM token in Firestore
        print('📝 Would update FCM token for user $userId: $_fcmToken');
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
