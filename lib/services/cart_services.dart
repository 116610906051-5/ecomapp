import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _cartsRef = _firestore.collection('carts');

  /// เพิ่มสินค้าลงตะกร้า
  static Future<void> addToCart({
    required String userId,
    required Product product,
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
  }) async {
    try {
      print('🛒 Adding to cart: ${product.name} x$quantity');
      
      // ตรวจสอบว่ามีตะกร้าอยู่แล้วหรือไม่
      final cartDoc = await _cartsRef.doc(userId).get();
      
      if (cartDoc.exists) {
        // อัพเดทตะกร้าที่มีอยู่
        final cart = Cart.fromMap(cartDoc.data() as Map<String, dynamic>);
        
        // ตรวจสอบว่ามีสินค้าชิ้นนี้ในตะกร้าแล้วหรือไม่
        final existingItemIndex = cart.items.indexWhere((item) =>
          item.productId == product.id &&
          item.selectedColor == selectedColor &&
          item.selectedSize == selectedSize
        );
        
        List<CartItem> updatedItems = List.from(cart.items);
        
        if (existingItemIndex >= 0) {
          // เพิ่มจำนวนสินค้าที่มีอยู่
          updatedItems[existingItemIndex] = updatedItems[existingItemIndex].copyWith(
            quantity: updatedItems[existingItemIndex].quantity + quantity,
          );
        } else {
          // เพิ่มสินค้าใหม่
          final cartItem = CartItem(
            id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            productName: product.name,
            productImage: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
            price: product.price,
            quantity: quantity,
            selectedColor: selectedColor,
            selectedSize: selectedSize,
          );
          updatedItems.add(cartItem);
        }
        
        final updatedCart = cart.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        
        await _cartsRef.doc(userId).update(updatedCart.toMap());
      } else {
        // สร้างตะกร้าใหม่
        final cartItem = CartItem(
          id: '${product.id}_${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          productImage: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
          price: product.price,
          quantity: quantity,
          selectedColor: selectedColor,
          selectedSize: selectedSize,
        );
        
        final cart = Cart(
          id: userId,
          userId: userId,
          items: [cartItem],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _cartsRef.doc(userId).set(cart.toMap());
      }
      
      print('✅ Added to cart successfully');
    } catch (e) {
      print('❌ Error adding to cart: $e');
      throw Exception('Failed to add to cart: $e');
    }
  }

  /// รับตะกร้าของผู้ใช้
  static Future<Cart?> getCart(String userId) async {
    try {
      final cartDoc = await _cartsRef.doc(userId).get();
      
      if (cartDoc.exists) {
        return Cart.fromMap(cartDoc.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting cart: $e');
      throw Exception('Failed to get cart: $e');
    }
  }

  /// Stream ตะกร้าของผู้ใช้
  static Stream<Cart?> getCartStream(String userId) {
    return _cartsRef.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Cart.fromMap(snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// อัพเดทจำนวนสินค้าในตะกร้า
  static Future<void> updateItemQuantity({
    required String userId,
    required String itemId,
    required int newQuantity,
  }) async {
    try {
      print('🔄 Updating item quantity: $itemId -> $newQuantity');
      
      final cartDoc = await _cartsRef.doc(userId).get();
      if (!cartDoc.exists) return;
      
      final cart = Cart.fromMap(cartDoc.data() as Map<String, dynamic>);
      
      final updatedItems = cart.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: newQuantity);
        }
        return item;
      }).toList();
      
      final updatedCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      
      await _cartsRef.doc(userId).update(updatedCart.toMap());
      print('✅ Item quantity updated');
    } catch (e) {
      print('❌ Error updating item quantity: $e');
      throw Exception('Failed to update item quantity: $e');
    }
  }

  /// ลบสินค้าออกจากตะกร้า
  static Future<void> removeFromCart({
    required String userId,
    required String itemId,
  }) async {
    try {
      print('🗑️ Removing item from cart: $itemId');
      
      final cartDoc = await _cartsRef.doc(userId).get();
      if (!cartDoc.exists) return;
      
      final cart = Cart.fromMap(cartDoc.data() as Map<String, dynamic>);
      
      final updatedItems = cart.items.where((item) => item.id != itemId).toList();
      
      if (updatedItems.isEmpty) {
        // ลบตะกร้าทั้งหมดถ้าไม่มีสินค้า
        await _cartsRef.doc(userId).delete();
      } else {
        final updatedCart = cart.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
        
        await _cartsRef.doc(userId).update(updatedCart.toMap());
      }
      
      print('✅ Item removed from cart');
    } catch (e) {
      print('❌ Error removing from cart: $e');
      throw Exception('Failed to remove from cart: $e');
    }
  }

  /// ล้างตะกร้าทั้งหมด
  static Future<void> clearCart(String userId) async {
    try {
      print('🗑️ Clearing cart for user: $userId');
      await _cartsRef.doc(userId).delete();
      print('✅ Cart cleared');
    } catch (e) {
      print('❌ Error clearing cart: $e');
      throw Exception('Failed to clear cart: $e');
    }
  }

  /// นับจำนวนสินค้าในตะกร้า
  static Future<int> getCartItemCount(String userId) async {
    try {
      final cart = await getCart(userId);
      return cart?.totalItems ?? 0;
    } catch (e) {
      print('❌ Error getting cart item count: $e');
      return 0;
    }
  }

  /// คำนวณราคารวมในตะกร้า
  static Future<double> getCartTotal(String userId) async {
    try {
      final cart = await getCart(userId);
      return cart?.totalAmount ?? 0.0;
    } catch (e) {
      print('❌ Error getting cart total: $e');
      return 0.0;
    }
  }

  /// ตรวจสอบสินค้าในสต็อก
  static Future<bool> validateCartItems(String userId) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return true;
      
      // TODO: ตรวจสอบสต็อกสินค้าแต่ละรายการ
      // สำหรับตอนนี้ return true ไปก่อน
      return true;
    } catch (e) {
      print('❌ Error validating cart items: $e');
      return false;
    }
  }
}
