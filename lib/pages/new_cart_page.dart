import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/cart.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      if (authProvider.isLoggedIn) {
        final userId = authProvider.currentUser?.id ?? authProvider.user?.uid;
        if (userId != null) {
          cartProvider.setCurrentUser(userId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'ตะกร้าสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartItems.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: cartProvider.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.cartItems[index];
                    return _buildCartItem(item, cartProvider);
                  },
                ),
              ),
              _buildCartSummary(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'ตะกร้าสินค้าว่างเปล่า',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เพิ่มสินค้าลงในตะกร้าเพื่อดำเนินการสั่งซื้อ',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'เลือกซื้อสินค้า',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปสินค้า
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                child: item.productImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.productImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image, color: Colors.grey[400]),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, color: Colors.grey[400]),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image, color: Colors.grey[400]),
                      ),
              ),
            ),
            SizedBox(width: 16),
            
            // ข้อมูลสินค้า
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  
                  // สี และ ขนาด
                  if (item.selectedColor != null || item.selectedSize != null)
                    Row(
                      children: [
                        if (item.selectedColor != null) ...[
                          Text(
                            'สี: ${item.selectedColor}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          if (item.selectedSize != null) SizedBox(width: 12),
                        ],
                        if (item.selectedSize != null)
                          Text(
                            'ขนาด: ${item.selectedSize}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  
                  SizedBox(height: 8),
                  
                  // ราคาและปุ่มจำนวน
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '฿${NumberFormat('#,##0.00').format(item.price)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                      Row(
                        children: [
                          // ปุ่มลดจำนวน
                          GestureDetector(
                            onTap: () {
                              cartProvider.decreaseQuantity(item.id);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          
                          // จำนวน
                          Container(
                            width: 50,
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          
                          // ปุ่มเพิ่มจำนวน
                          GestureDetector(
                            onTap: () {
                              cartProvider.increaseQuantity(item.id);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ปุ่มลบ
            GestureDetector(
              onTap: () {
                _showDeleteConfirmation(context, item, cartProvider);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ยอดรวมสินค้า',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '฿${NumberFormat('#,##0.00').format(cartProvider.subtotal)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ค่าจัดส่ง',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  cartProvider.shippingFee == 0 
                      ? 'ฟรี' 
                      : '฿${NumberFormat('#,##0.00').format(cartProvider.shippingFee)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cartProvider.shippingFee == 0 
                        ? Color(0xFF059669) 
                        : Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            if (cartProvider.shippingFee == 0)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'ฟรีค่าส่งเมื่อซื้อครบ ฿1,000',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รวมทั้งสิ้น',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '฿${NumberFormat('#,##0.00').format(cartProvider.total)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            Row(
              children: [
                // ปุ่มล้างตะกร้า
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showClearCartConfirmation(context, cartProvider);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFDC2626),
                      side: BorderSide(color: Color(0xFFDC2626)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ล้างตะกร้า',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                
                // ปุ่มดำเนินการสั่งซื้อ
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: cartProvider.isLoading ? null : () {
                      _proceedToCheckout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: cartProvider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'สั่งซื้อ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CartItem item, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบ "${item.productName}" ออกจากตะกร้าหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                cartProvider.removeFromCart(item.id);
                Navigator.of(context).pop();
              },
              child: Text(
                'ลบ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearCartConfirmation(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการล้างตะกร้า'),
          content: Text('คุณต้องการลบสินค้าทั้งหมดออกจากตะกร้าหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                cartProvider.clearCart();
                Navigator.of(context).pop();
              },
              child: Text(
                'ล้างตะกร้า',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _proceedToCheckout(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isLoggedIn) {
      // ถ้ายังไม่เข้าสู่ระบบ ให้ไปหน้า login
      Navigator.pushNamed(context, '/login');
      return;
    }
    
    // ไปหน้า checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(),
      ),
    );
  }
}
