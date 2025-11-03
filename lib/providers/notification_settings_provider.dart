import 'package:flutter/foundation.dart';
import '../services/notification_settings_service.dart';

/// Provider สำหรับจัดการการตั้งค่าการแจ้งเตือน
class NotificationSettingsProvider with ChangeNotifier {
  Map<String, bool> _settings = {
    'orderUpdates': true,
    'chatMessages': true,
    'promotionalOffers': false,
    'newProducts': true,
    'priceDrops': false,
    'systemNotifications': true,
  };
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  /// การตั้งค่าปัจจุบัน
  Map<String, bool> get settings => _settings;
  
  /// สถานะการโหลด
  bool get isLoading => _isLoading;
  
  /// สถานะการบันทึก
  bool get isSaving => _isSaving;
  
  /// การตั้งค่าแต่ละประเภท
  bool get orderUpdates => _settings['orderUpdates'] ?? true;
  bool get chatMessages => _settings['chatMessages'] ?? true;
  bool get promotionalOffers => _settings['promotionalOffers'] ?? false;
  bool get newProducts => _settings['newProducts'] ?? true;
  bool get priceDrops => _settings['priceDrops'] ?? false;
  bool get systemNotifications => _settings['systemNotifications'] ?? true;
  
  /// เริ่มต้นและโหลดการตั้งค่า
  Future<void> initialize({String? userId}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // โหลดจาก Firestore ก่อน (ถ้ามี userId)
      if (userId != null) {
        final firestoreSettings = await NotificationSettingsService.loadSettingsFromFirestore(userId);
        if (firestoreSettings != null) {
          _settings = firestoreSettings;
          // บันทึกลง SharedPreferences เพื่อ sync
          await NotificationSettingsService.saveSettings(_settings);
        }
      }
      
      // โหลดจาก SharedPreferences
      final localSettings = await NotificationSettingsService.loadSettings();
      _settings = localSettings;
      
      print('✅ Notification settings loaded: $_settings');
    } catch (e) {
      print('❌ Error loading notification settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// อัปเดตการตั้งค่าเฉพาะประเภท
  Future<void> updateSetting(String key, bool value, {String? userId}) async {
    try {
      _settings[key] = value;
      notifyListeners();
      
      // บันทึกลง SharedPreferences
      await NotificationSettingsService.saveSettings(_settings);
      
      // Sync ไปยัง Firestore ถ้ามี userId
      if (userId != null) {
        await NotificationSettingsService.syncSettingsToFirestore(userId, _settings);
      }
      
      print('✅ Updated $key to $value');
    } catch (e) {
      print('❌ Error updating setting $key: $e');
      // Revert การเปลี่ยนแปลง
      _settings[key] = !value;
      notifyListeners();
    }
  }
  
  /// บันทึกการตั้งค่าทั้งหมด
  Future<void> saveAllSettings({String? userId}) async {
    try {
      _isSaving = true;
      notifyListeners();
      
      await NotificationSettingsService.saveSettings(_settings);
      
      if (userId != null) {
        await NotificationSettingsService.syncSettingsToFirestore(userId, _settings);
      }
      
      print('✅ All notification settings saved');
    } catch (e) {
      print('❌ Error saving all settings: $e');
      throw e;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
  
  /// รีเซ็ตเป็นค่า default
  Future<void> resetToDefault({String? userId}) async {
    try {
      _isSaving = true;
      notifyListeners();
      
      await NotificationSettingsService.resetToDefault();
      _settings = {
        'orderUpdates': true,
        'chatMessages': true,
        'promotionalOffers': false,
        'newProducts': true,
        'priceDrops': false,
        'systemNotifications': true,
      };
      
      if (userId != null) {
        await NotificationSettingsService.syncSettingsToFirestore(userId, _settings);
      }
      
      print('✅ Notification settings reset to default');
    } catch (e) {
      print('❌ Error resetting settings: $e');
      throw e;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
  
  /// เปิด/ปิดการแจ้งเตือนทั้งหมด
  Future<void> toggleAllNotifications(bool enabled, {String? userId}) async {
    try {
      _isSaving = true;
      notifyListeners();
      
      if (enabled) {
        await NotificationSettingsService.enableAllNotifications();
        _settings = _settings.map((key, value) => MapEntry(key, true));
      } else {
        await NotificationSettingsService.disableAllNotifications();
        _settings = _settings.map((key, value) => MapEntry(key, false));
      }
      
      if (userId != null) {
        await NotificationSettingsService.syncSettingsToFirestore(userId, _settings);
      }
      
      print('✅ All notifications ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('❌ Error toggling all notifications: $e');
      throw e;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
  
  /// ส่งการแจ้งเตือนทดสอบ
  Future<void> sendTestNotification(String type) async {
    try {
      await NotificationSettingsService.sendTestNotification(type);
    } catch (e) {
      print('❌ Error sending test notification: $e');
      throw e;
    }
  }
  
  /// ตรวจสอบว่าควรส่งการแจ้งเตือนประเภทนี้หรือไม่
  bool shouldSendNotificationType(String type) {
    switch (type) {
      case 'order_status':
        return orderUpdates;
      case 'chat':
        return chatMessages;
      case 'promotional':
        return promotionalOffers;
      case 'new_product':
        return newProducts;
      case 'price_drop':
        return priceDrops;
      case 'system':
        return systemNotifications;
      default:
        return true;
    }
  }
  
  /// นับจำนวนการแจ้งเตือนที่เปิดอยู่
  int get enabledNotificationsCount {
    return _settings.values.where((enabled) => enabled).length;
  }
  
  /// ตรวจสอบว่าเปิดการแจ้งเตือนทั้งหมดหรือไม่
  bool get allNotificationsEnabled {
    return _settings.values.every((enabled) => enabled);
  }
  
  /// ตรวจสอบว่าปิดการแจ้งเตือนทั้งหมดหรือไม่
  bool get allNotificationsDisabled {
    return _settings.values.every((enabled) => !enabled);
  }
}
