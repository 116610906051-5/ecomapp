import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's wishlist
  Future<List<Product>> getWishlist(String userId) async {
    try {
      final wishlistDoc = await _firestore
          .collection('wishlists')
          .doc(userId)
          .get();

      if (!wishlistDoc.exists) {
        return [];
      }

      final productIds = List<String>.from(wishlistDoc.data()?['productIds'] ?? []);
      
      if (productIds.isEmpty) {
        return [];
      }

      // Fetch all products in wishlist
      final List<Product> products = [];
      for (String productId in productIds) {
        final productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists && productDoc.data() != null) {
          final data = productDoc.data()!;
          data['id'] = productDoc.id;
          products.add(Product.fromMap(data));
        }
      }

      return products;
    } catch (e) {
      print('Error getting wishlist: $e');
      return [];
    }
  }

  // Add product to wishlist
  Future<void> addToWishlist(String userId, String productId) async {
    try {
      final wishlistRef = _firestore.collection('wishlists').doc(userId);
      
      await wishlistRef.set({
        'productIds': FieldValue.arrayUnion([productId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding to wishlist: $e');
      rethrow;
    }
  }

  // Remove product from wishlist
  Future<void> removeFromWishlist(String userId, String productId) async {
    try {
      final wishlistRef = _firestore.collection('wishlists').doc(userId);
      
      await wishlistRef.update({
        'productIds': FieldValue.arrayRemove([productId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing from wishlist: $e');
      rethrow;
    }
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String userId, String productId) async {
    try {
      final wishlistDoc = await _firestore
          .collection('wishlists')
          .doc(userId)
          .get();

      if (!wishlistDoc.exists) {
        return false;
      }

      final productIds = List<String>.from(wishlistDoc.data()?['productIds'] ?? []);
      return productIds.contains(productId);
    } catch (e) {
      print('Error checking wishlist: $e');
      return false;
    }
  }

  // Clear entire wishlist
  Future<void> clearWishlist(String userId) async {
    try {
      await _firestore.collection('wishlists').doc(userId).delete();
    } catch (e) {
      print('Error clearing wishlist: $e');
      rethrow;
    }
  }
}
