import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/wishlist_service.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();
  
  List<Product> _wishlistItems = [];
  bool _isLoading = false;

  List<Product> get wishlistItems => _wishlistItems;
  bool get isLoading => _isLoading;
  int get itemCount => _wishlistItems.length;

  // Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  // Load wishlist from Firestore
  Future<void> loadWishlist(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _wishlistItems = await _wishlistService.getWishlist(userId);
    } catch (e) {
      print('Error loading wishlist: $e');
      _wishlistItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add product to wishlist
  Future<void> addToWishlist(String userId, Product product) async {
    try {
      await _wishlistService.addToWishlist(userId, product.id);
      _wishlistItems.add(product);
      notifyListeners();
    } catch (e) {
      print('Error adding to wishlist: $e');
      rethrow;
    }
  }

  // Remove product from wishlist
  Future<void> removeFromWishlist(String userId, String productId) async {
    try {
      await _wishlistService.removeFromWishlist(userId, productId);
      _wishlistItems.removeWhere((item) => item.id == productId);
      notifyListeners();
    } catch (e) {
      print('Error removing from wishlist: $e');
      rethrow;
    }
  }

  // Toggle wishlist status
  Future<void> toggleWishlist(String userId, Product product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(userId, product.id);
    } else {
      await addToWishlist(userId, product);
    }
  }

  // Clear wishlist
  void clearWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
