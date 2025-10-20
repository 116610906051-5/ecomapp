import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
//import '../models/cart.dart';
import 'stripe_service.dart';
import 'cart_services.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ordersRef = _firestore.collection('orders');

  /// สร้างคำสั่งซื้อจากตะกร้า
  static Future<Order> createOrderFromCart({
    required String userId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required ShippingAddress shippingAddress,
    PaymentMethod paymentMethod = PaymentMethod.creditCard,
    double shippingFee = 50.0,
  }) async {
    try {
      print('📦 Creating order from cart for user: $userId');
      
      // ดึงข้อมูลตะกร้า
      final cart = await CartService.getCart(userId);
      if (cart == null || cart.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      // ตรวจสอบสต็อกสินค้า
      final isValidCart = await CartService.validateCartItems(userId);
      if (!isValidCart) {
        throw Exception('Some items in cart are out of stock');
      }

      // สร้าง Order Items จาก Cart Items
      final orderItems = cart.items.map((cartItem) => OrderItem(
        id: cartItem.id,
        productId: cartItem.productId,
        productName: cartItem.productName,
        productImage: cartItem.productImage,
        price: cartItem.price,
        quantity: cartItem.quantity,
        selectedColor: cartItem.selectedColor,
        selectedSize: cartItem.selectedSize,
      )).toList();

      final subtotal = cart.totalAmount;
      final totalAmount = subtotal + shippingFee;

      // สร้าง Order
      final orderId = _ordersRef.doc().id;
      final order = Order(
        id: orderId,
        userId: userId,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        shippingAddress: shippingAddress,
        items: orderItems,
        subtotal: subtotal,
        shippingFee: shippingFee,
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // บันทึกลง Firestore
      await _ordersRef.doc(orderId).set(order.toMap());
      
      print('✅ Order created: ${order.formattedOrderNumber}');
      return order;
    } catch (e) {
      print('❌ Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  /// สร้าง Payment Intent สำหรับคำสั่งซื้อ
  static Future<Map<String, dynamic>> createPaymentIntentForOrder({
    required String orderId,
    required double amount,
    String currency = 'thb',
  }) async {
    try {
      print('💳 Creating payment intent for order: $orderId');
      
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: amount,
        currency: currency,
        metadata: {
          'order_id': orderId,
          'source': 'mobile_app',
        },
      );

      // อัพเดท Payment Intent ID ในคำสั่งซื้อ
      await _ordersRef.doc(orderId).update({
        'paymentIntentId': paymentIntent['id'],
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Payment intent created for order: $orderId');
      return paymentIntent;
    } catch (e) {
      print('❌ Error creating payment intent for order: $e');
      throw Exception('Failed to create payment intent: $e');
    }
  }

  /// อัพเดทสถานะการชำระเงิน
  static Future<void> updatePaymentStatus({
    required String orderId,
    required OrderStatus status,
    String? paymentIntentId,
  }) async {
    try {
      print('💰 Updating payment status for order: $orderId -> ${status.name}');
      
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (paymentIntentId != null) {
        updateData['paymentIntentId'] = paymentIntentId;
      }

      await _ordersRef.doc(orderId).update(updateData);
      
      // ถ้าการชำระเงินสำเร็จ ให้ล้างตะกร้า
      if (status == OrderStatus.paid) {
        final orderDoc = await _ordersRef.doc(orderId).get();
        if (orderDoc.exists) {
          final order = Order.fromMap(orderDoc.data() as Map<String, dynamic>);
          await CartService.clearCart(order.userId);
          print('🛒 Cart cleared after successful payment');
        }
      }
      
      print('✅ Payment status updated');
    } catch (e) {
      print('❌ Error updating payment status: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// อัพเดทสถานะคำสั่งซื้อ
  static Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    String? trackingNumber,
  }) async {
    try {
      print('📦 Updating order status: $orderId -> ${status.name}');
      
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (trackingNumber != null) {
        updateData['trackingNumber'] = trackingNumber;
      }

      // เพิ่มวันที่สำหรับสถานะเฉพาะ
      switch (status) {
        case OrderStatus.shipped:
          updateData['shippedAt'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.delivered:
          updateData['deliveredAt'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      await _ordersRef.doc(orderId).update(updateData);
      print('✅ Order status updated');
    } catch (e) {
      print('❌ Error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  /// รับคำสั่งซื้อโดย ID
  static Future<Order?> getOrder(String orderId) async {
    try {
      final orderDoc = await _ordersRef.doc(orderId).get();
      
      if (orderDoc.exists) {
        return Order.fromMap(orderDoc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting order: $e');
      throw Exception('Failed to get order: $e');
    }
  }

  /// รับคำสั่งซื้อของผู้ใช้
  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _ordersRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting user orders: $e');
      throw Exception('Failed to get user orders: $e');
    }
  }

  /// Stream คำสั่งซื้อของผู้ใช้
  static Stream<List<Order>> getUserOrdersStream(String userId) {
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          // Sort in memory to avoid compound index requirement
          final orders = snapshot.docs
              .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          // Sort by createdAt descending
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return orders;
        });
  }

  /// รับคำสั่งซื้อทั้งหมด (สำหรับ Admin)
  static Future<List<Order>> getAllOrders({
    OrderStatus? statusFilter,
    int limit = 50,
  }) async {
    try {
      Query query = _ordersRef.orderBy('createdAt', descending: true);
      
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }
      
      query = query.limit(limit);
      
      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting all orders: $e');
      throw Exception('Failed to get all orders: $e');
    }
  }

  /// Stream คำสั่งซื้อทั้งหมด (สำหรับ Admin)
  static Stream<List<Order>> getAllOrdersStream({
    OrderStatus? statusFilter,
    int limit = 50,
  }) {
    Query query = _ordersRef.orderBy('createdAt', descending: true);
    
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }
    
    query = query.limit(limit);
    
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// ยกเลิกคำสั่งซื้อ
  static Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      print('❌ Cancelling order: $orderId');
      
      final order = await getOrder(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // ยกเลิก Payment Intent ถ้ามี
      if (order.paymentIntentId != null && order.status == OrderStatus.pending) {
        try {
          await StripeService.cancelPaymentIntent(order.paymentIntentId!);
        } catch (e) {
          print('⚠️ Could not cancel payment intent: $e');
        }
      }

      // อัพเดทสถานะเป็น cancelled
      await updateOrderStatus(
        orderId: orderId,
        status: OrderStatus.cancelled,
      );

      print('✅ Order cancelled');
    } catch (e) {
      print('❌ Error cancelling order: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// คืนเงินคำสั่งซื้อ
  static Future<void> refundOrder({
    required String orderId,
    double? amount,
    String? reason,
  }) async {
    try {
      print('💰 Processing refund for order: $orderId');
      
      final order = await getOrder(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (order.paymentIntentId == null) {
        throw Exception('No payment to refund');
      }

      // สร้าง Refund ใน Stripe
      await StripeService.createRefund(
        paymentIntentId: order.paymentIntentId!,
        amount: amount ?? order.totalAmount,
        reason: reason ?? 'requested_by_customer',
        metadata: {
          'order_id': orderId,
        },
      );

      // อัพเดทสถานะเป็น refunded
      await updateOrderStatus(
        orderId: orderId,
        status: OrderStatus.refunded,
      );

      print('✅ Order refunded');
    } catch (e) {
      print('❌ Error refunding order: $e');
      throw Exception('Failed to refund order: $e');
    }
  }

  /// สถิติคำสั่งซื้อ (สำหรับ Admin Dashboard)
  static Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      
      // นับคำสั่งซื้อทั้งหมด
      final totalOrdersQuery = await _ordersRef.get();
      final totalOrders = totalOrdersQuery.docs.length;
      
      // นับคำสั่งซื้อในเดือนนี้
      final monthOrdersQuery = await _ordersRef
          .where('createdAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
          .get();
      final monthOrders = monthOrdersQuery.docs.length;
      
      // คำนวณยอดขายรวม
      double totalRevenue = 0.0;
      double monthRevenue = 0.0;
      
      for (final doc in totalOrdersQuery.docs) {
        final order = Order.fromMap(doc.data() as Map<String, dynamic>);
        if (order.status == OrderStatus.paid || 
            order.status == OrderStatus.processing ||
            order.status == OrderStatus.shipped ||
            order.status == OrderStatus.delivered) {
          totalRevenue += order.totalAmount;
          
          if (order.createdAt.isAfter(startOfMonth)) {
            monthRevenue += order.totalAmount;
          }
        }
      }
      
      return {
        'totalOrders': totalOrders,
        'monthOrders': monthOrders,
        'totalRevenue': totalRevenue,
        'monthRevenue': monthRevenue,
      };
    } catch (e) {
      print('❌ Error getting order statistics: $e');
      return {
        'totalOrders': 0,
        'monthOrders': 0,
        'totalRevenue': 0.0,
        'monthRevenue': 0.0,
      };
    }
  }
}
