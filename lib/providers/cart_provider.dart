import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_services.dart';

class CartProvider with ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _currentUserId;

  Cart? get cart => _cart;
  List<CartItem> get cartItems => _cart?.items ?? [];
  bool get isLoading => _isLoading;

  int get itemCount {
    return _cart?.totalItems ?? 0;
  }

  double get subtotal {
    return _cart?.totalAmount ?? 0.0;
  }

  double get shippingFee {
    return subtotal > 1000 ? 0 : 50.0; // ฟรีค่าส่งเมื่อซื้อครบ 1000 บาท
  }

  double get tax {
    return 0.0; // ไม่มีภาษี
  }

  double get total {
    return subtotal + shippingFee + tax;
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    loadCartItems();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void loadCartItems() {
    if (_currentUserId == null) return;
    
    CartService.getCartStream(_currentUserId!).listen((cart) {
      _cart = cart;
      notifyListeners();
    });
  }

  Future<void> addToCart({
    required Product product,
    int quantity = 1,
    String? selectedColor,
    String? selectedSize,
  }) async {
    if (_currentUserId == null) return;
    
    try {
      setLoading(true);
      await CartService.addToCart(
        userId: _currentUserId!,
        product: product,
        quantity: quantity,
        selectedColor: selectedColor,
        selectedSize: selectedSize,
      );
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_currentUserId == null) return;
    
    try {
      await CartService.updateItemQuantity(
        userId: _currentUserId!,
        itemId: itemId,
        newQuantity: quantity,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    if (_currentUserId == null) return;
    
    try {
      await CartService.removeFromCart(
        userId: _currentUserId!,
        itemId: itemId,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> clearCart() async {
    if (_currentUserId == null) return;
    
    try {
      setLoading(true);
      await CartService.clearCart(_currentUserId!);
      setLoading(false);
    } catch (e) {
      setLoading(false);
      throw e;
    }
  }

  void increaseQuantity(String itemId) {
    final item = cartItems.firstWhere((item) => item.id == itemId);
    updateQuantity(itemId, item.quantity + 1);
  }

  void decreaseQuantity(String itemId) {
    final item = cartItems.firstWhere((item) => item.id == itemId);
    if (item.quantity > 1) {
      updateQuantity(itemId, item.quantity - 1);
    } else {
      removeFromCart(itemId);
    }
  }

  bool isInCart(String productId, String? color, String? size) {
    return cartItems.any((item) => 
        item.productId == productId && 
        item.selectedColor == color && 
        item.selectedSize == size);
  }

  CartItem? getCartItem(String productId, String? color, String? size) {
    try {
      return cartItems.firstWhere((item) => 
          item.productId == productId && 
          item.selectedColor == color && 
          item.selectedSize == size);
    } catch (e) {
      return null;
    }
  }
}
