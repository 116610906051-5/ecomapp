import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/advanced_notification_service.dart';

/// Service สำหรับการแจ้งเตือนเกี่ยวกับคำสั่งซื้อ
class OrderNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// ส่งการแจ้งเตือนเมื่อสถานะคำสั่งซื้อเปลี่ยนแปลง
  static Future<void> notifyOrderStatusUpdate({
    required String orderId,
    required String customerId,
    required String newStatus,
    required String productName,
    String? productImage,
  }) async {
    try {
      print('📦 Notifying order status update: $orderId -> $newStatus');
      
      // ตรวจสอบว่า customerId ไม่เป็นค่าว่าง
      if (customerId.isEmpty) {
        print('⚠️ Warning: customerId is empty, skipping notification');
        return;
      }
      
      print('📤 Sending order status notification to $customerId');
      
      // บันทึกประวัติการแจ้งเตือน
      await _logOrderNotification(
        orderId: orderId,
        customerId: customerId,
        status: newStatus,
        productName: productName,
      );
      
      // ส่งการแจ้งเตือนผ่าน FCM
      await AdvancedNotificationService.sendOrderStatusNotification(
        toUserId: customerId,
        orderId: orderId,
        status: newStatus,
        productName: productName,
        productImage: productImage,
      );
      
      print('✅ Order status notification sent successfully');
    } catch (e) {
      print('❌ Error sending order status notification: $e');
    }
  }
  
  /// ส่งการแจ้งเตือนเมื่อมีคำสั่งซื้อใหม่ (สำหรับ Admin)
  static Future<void> notifyNewOrder({
    required String orderId,
    required String customerName,
    required String productName,
    required double totalAmount,
  }) async {
    try {
      print('🛒 Notifying new order: $orderId');
      
      // ส่งการแจ้งเตือนไปยัง Admin ทุกคน
      await _notifyAllAdmins(
        title: '🛒 คำสั่งซื้อใหม่!',
        body: 'คำสั่งซื้อจาก $customerName\n$productName (฿${totalAmount.toStringAsFixed(2)})',
        data: {
          'type': 'new_order',
          'orderId': orderId,
          'customerName': customerName,
          'productName': productName,
          'totalAmount': totalAmount.toString(),
        },
      );
      
      print('✅ New order notification sent to admins');
    } catch (e) {
      print('❌ Error sending new order notification: $e');
    }
  }
  
  /// ส่งการแจ้งเตือนเมื่อสินค้าใกล้หมด (สำหรับ Admin)
  static Future<void> notifyLowStock({
    required String productId,
    required String productName,
    required int currentStock,
    required int minStock,
  }) async {
    try {
      print('📦 Notifying low stock: $productName ($currentStock left)');
      
      await _notifyAllAdmins(
        title: '⚠️ สินค้าใกล้หมด',
        body: '$productName เหลือเพียง $currentStock ชิ้น (ต่ำกว่าขีดจำกัด $minStock ชิ้น)',
        data: {
          'type': 'low_stock',
          'productId': productId,
          'productName': productName,
          'currentStock': currentStock.toString(),
          'minStock': minStock.toString(),
        },
      );
      
      print('✅ Low stock notification sent to admins');
    } catch (e) {
      print('❌ Error sending low stock notification: $e');
    }
  }
  
  /// ส่งการแจ้งเตือนเมื่อมีการรีวิวใหม่ (สำหรับ Admin)
  static Future<void> notifyNewReview({
    required String productId,
    required String productName,
    required String customerName,
    required int rating,
    required String reviewText,
  }) async {
    try {
      print('⭐ Notifying new review: $productName - $rating stars');
      
      final stars = '⭐' * rating;
      
      await _notifyAllAdmins(
        title: '⭐ รีวิวใหม่!',
        body: '$customerName ให้คะแนน $productName\n$stars ($rating/5)\n"$reviewText"',
        data: {
          'type': 'new_review',
          'productId': productId,
          'productName': productName,
          'customerName': customerName,
          'rating': rating.toString(),
          'reviewText': reviewText,
        },
      );
      
      print('✅ New review notification sent to admins');
    } catch (e) {
      print('❌ Error sending new review notification: $e');
    }
  }
  
  /// ส่งการแจ้งเตือนไปยัง Admin ทุกคน
  static Future<void> _notifyAllAdmins({
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // ดึงรายชื่อ Admin ทั้งหมด
      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      
      for (var adminDoc in adminsQuery.docs) {
        final adminId = adminDoc.id;
        final adminData = adminDoc.data();
        final fcmToken = adminData['fcmToken'];
        
        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          // จำลองการส่งการแจ้งเตือนไปยัง admin
          print('📤 Sending notification to admin: ${adminData['name']} ($adminId)');
          
          // จำลองการส่งการแจ้งเตือน (ในระบบจริงจะใช้ FCM API)
          print('📱 Would send FCM to admin ${adminData['name']}: $title - $body');
        }
      }
    } catch (e) {
      print('❌ Error notifying all admins: $e');
    }
  }
  
  /// บันทึกประวัติการแจ้งเตือน
  static Future<void> _logOrderNotification({
    required String orderId,
    required String customerId,
    required String status,
    required String productName,
  }) async {
    try {
      // ตรวจสอบว่า customerId ไม่เป็นค่าว่าง
      if (customerId.isEmpty) {
        print('⚠️ Warning: Cannot log notification with empty customerId');
        return;
      }
      
      await _firestore.collection('notifications').add({
        'type': 'order_status',
        'orderId': orderId,
        'customerId': customerId,
        'status': status,
        'productName': productName,
        'title': '${_getStatusEmoji(status)} อัปเดตสถานะคำสั่งซื้อ',
        'body': '$productName - ${_getStatusText(status)}',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('❌ Error logging notification: $e');
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
  
  /// ส่งการแจ้งเตือนทดสอบ
  static Future<void> sendTestOrderNotification(String customerId) async {
    await notifyOrderStatusUpdate(
      orderId: 'TEST_ORDER_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      newStatus: 'shipped',
      productName: 'สินค้าทดสอบ',
      productImage: null,
    );
  }
}
