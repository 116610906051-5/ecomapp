import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's cart items
  Stream<List<CartItem>> getCartItems() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItem.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Add item to cart
  Future<void> addToCart(CartItem item) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Check if item already exists in cart
      final existingItems = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .where('productId', isEqualTo: item.productId)
          .where('selectedColor', isEqualTo: item.selectedColor)
          .where('selectedSize', isEqualTo: item.selectedSize)
          .get();

      if (existingItems.docs.isNotEmpty) {
        // Update quantity if item exists
        final existingItem = existingItems.docs.first;
        final currentQuantity = existingItem.data()['quantity'] ?? 0;
        await existingItem.reference.update({
          'quantity': currentQuantity + item.quantity,
        });
      } else {
        // Add new item to cart
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .add(item.toMap());
      }
    } catch (e) {
      print('Error adding to cart: $e');
      throw e;
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String itemId, int quantity) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      if (quantity <= 0) {
        await removeFromCart(itemId);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(itemId)
            .update({'quantity': quantity});
      }
    } catch (e) {
      print('Error updating cart item: $e');
      throw e;
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Error removing from cart: $e');
      throw e;
    }
  }

  // Clear entire cart
  Future<void> clearCart() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final cartItems = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      final batch = _firestore.batch();
      for (var doc in cartItems.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing cart: $e');
      throw e;
    }
  }

  // Get cart total
  Future<double> getCartTotal() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0.0;

    try {
      final cartItems = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      double total = 0.0;
      for (var doc in cartItems.docs) {
        final data = doc.data();
        final price = (data['price'] ?? 0).toDouble();
        final quantity = data['quantity'] ?? 0;
        total += price * quantity;
      }
      return total;
    } catch (e) {
      print('Error calculating cart total: $e');
      return 0.0;
    }
  }

  // Get cart items count
  Future<int> getCartItemsCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final cartItems = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      int count = 0;
      for (var doc in cartItems.docs) {
        count += (doc.data()['quantity'] ?? 0) as int;
      }
      return count;
    } catch (e) {
      print('Error getting cart count: $e');
      return 0;
    }
  }
}
