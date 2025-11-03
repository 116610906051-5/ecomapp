import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'advanced_notification_service.dart';

/// บริการจัดการการตั้งค่าการแจ้งเตือน
class NotificationSettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Keys สำหรับ SharedPreferences
  static const String _orderUpdatesKey = 'notification_order_updates';
  static const String _chatMessagesKey = 'notification_chat_messages';
  static const String _promotionalOffersKey = 'notification_promotional_offers';
  static const String _newProductsKey = 'notification_new_products';
  static const String _priceDropsKey = 'notification_price_drops';
  static const String _systemNotificationsKey = 'notification_system';
  
  /// โหลดการตั้งค่าการแจ้งเตือนจาก SharedPreferences
  static Future<Map<String, bool>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'orderUpdates': prefs.getBool(_orderUpdatesKey) ?? true,
        'chatMessages': prefs.getBool(_chatMessagesKey) ?? true,
        'promotionalOffers': prefs.getBool(_promotionalOffersKey) ?? false,
        'newProducts': prefs.getBool(_newProductsKey) ?? true,
        'priceDrops': prefs.getBool(_priceDropsKey) ?? false,
        'systemNotifications': prefs.getBool(_systemNotificationsKey) ?? true,
      };
    } catch (e) {
      print('❌ Error loading notification settings: $e');
      // คืนค่า default ถ้าเกิดข้อผิดพลาด
      return {
        'orderUpdates': true,
        'chatMessages': true,
        'promotionalOffers': false,
        'newProducts': true,
        'priceDrops': false,
        'systemNotifications': true,
      };
    }
  }
  
  /// บันทึกการตั้งค่าการแจ้งเตือนใน SharedPreferences
  static Future<void> saveSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.setBool(_orderUpdatesKey, settings['orderUpdates'] ?? true),
        prefs.setBool(_chatMessagesKey, settings['chatMessages'] ?? true),
        prefs.setBool(_promotionalOffersKey, settings['promotionalOffers'] ?? false),
        prefs.setBool(_newProductsKey, settings['newProducts'] ?? true),
        prefs.setBool(_priceDropsKey, settings['priceDrops'] ?? false),
        prefs.setBool(_systemNotificationsKey, settings['systemNotifications'] ?? true),
      ]);
      
      print('✅ Notification settings saved successfully');
    } catch (e) {
      print('❌ Error saving notification settings: $e');
    }
  }
  
  /// อัปเดตการตั้งค่าการแจ้งเตือนของผู้ใช้ใน Firestore
  static Future<void> syncSettingsToFirestore(String userId, Map<String, bool> settings) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationSettings': settings,
        'notificationSettingsUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification settings synced to Firestore');
    } catch (e) {
      print('❌ Error syncing notification settings to Firestore: $e');
    }
  }
  
  /// โหลดการตั้งค่าการแจ้งเตือนจาก Firestore
  static Future<Map<String, bool>?> loadSettingsFromFirestore(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      
      if (data != null && data['notificationSettings'] != null) {
        final firestoreSettings = Map<String, dynamic>.from(data['notificationSettings']);
        return firestoreSettings.map((key, value) => MapEntry(key, value as bool? ?? true));
      }
      
      return null;
    } catch (e) {
      print('❌ Error loading notification settings from Firestore: $e');
      return null;
    }
  }
  
  /// ตรวจสอบว่าควรส่งการแจ้งเตือนประเภทนี้หรือไม่
  static Future<bool> shouldSendNotification(String notificationType) async {
    try {
      final settings = await loadSettings();
      
      switch (notificationType) {
        case 'order_status':
          return settings['orderUpdates'] ?? true;
        case 'chat':
          return settings['chatMessages'] ?? true;
        case 'promotional':
          return settings['promotionalOffers'] ?? false;
        case 'new_product':
          return settings['newProducts'] ?? true;
        case 'price_drop':
          return settings['priceDrops'] ?? false;
        case 'system':
          return settings['systemNotifications'] ?? true;
        default:
          return true; // ส่งถ้าไม่รู้จักประเภท
      }
    } catch (e) {
      print('❌ Error checking notification permission: $e');
      return true; // ส่งถ้าเกิดข้อผิดพลาด
    }
  }
  
  /// รีเซ็ตการตั้งค่าเป็นค่า default
  static Future<void> resetToDefault() async {
    final defaultSettings = {
      'orderUpdates': true,
      'chatMessages': true,
      'promotionalOffers': false,
      'newProducts': true,
      'priceDrops': false,
      'systemNotifications': true,
    };
    
    await saveSettings(defaultSettings);
    print('✅ Notification settings reset to default');
  }
  
  /// ปิดการแจ้งเตือนทั้งหมด
  static Future<void> disableAllNotifications() async {
    final allDisabled = {
      'orderUpdates': false,
      'chatMessages': false,
      'promotionalOffers': false,
      'newProducts': false,
      'priceDrops': false,
      'systemNotifications': false,
    };
    
    await saveSettings(allDisabled);
    print('✅ All notifications disabled');
  }
  
  /// เปิดการแจ้งเตือนทั้งหมด
  static Future<void> enableAllNotifications() async {
    final allEnabled = {
      'orderUpdates': true,
      'chatMessages': true,
      'promotionalOffers': true,
      'newProducts': true,
      'priceDrops': true,
      'systemNotifications': true,
    };
    
    await saveSettings(allEnabled);
    print('✅ All notifications enabled');
  }
  
  /// ทดสอบการส่งการแจ้งเตือนตามประเภท
  static Future<void> sendTestNotification(String type) async {
    final shouldSend = await shouldSendNotification(type);
    
    if (!shouldSend) {
      print('🚫 Notification type $type is disabled');
      return;
    }
    
    switch (type) {
      case 'order_status':
        await AdvancedNotificationService.sendOrderStatusNotification(
          toUserId: 'test',
          orderId: 'TEST_ORDER_${DateTime.now().millisecondsSinceEpoch}',
          status: 'processing',
          productName: 'สินค้าทดสอบ',
        );
        break;
      case 'chat':
        await AdvancedNotificationService.sendChatNotification(
          toUserId: 'test',
          fromUserName: 'ทดสอบแชท',
          message: 'นี่คือข้อความทดสอบ',
          chatRoomId: 'test_room',
        );
        break;
      default:
        await AdvancedNotificationService.sendTestNotification();
        break;
    }
  }
}
