import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/cart.dart';
import '../services/product_service.dart';
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
              // Navigate to products page
              Navigator.pushNamed(context, '/products');
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
    return GestureDetector(
      onTap: () async {
        // Fetch product and navigate to product detail page
        try {
          final productService = ProductService();
          final product = await productService.getProductById(item.productId);
          if (product != null && mounted) {
            Navigator.pushNamed(
              context,
              '/product-detail',
              arguments: product,
            );
          }
        } catch (e) {
          print('Error fetching product: $e');
        }
      },
      child: Container(
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
        child: Column(
          children: [
            // Header row với รูป, ชื่อ, และปุ่มลบ
            Row(
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
                      SizedBox(height: 8),
                      
                      // สีและขนาด
                      Row(
                        children: [
                          if (item.selectedColor != null && item.selectedColor!.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Color(0xFF0EA5E9), width: 0.5),
                              ),
                              child: Text(
                                'สี: ${item.selectedColor}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                          ],
                          if (item.selectedSize != null && item.selectedSize!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Color(0xFF22C55E), width: 0.5),
                              ),
                              child: Text(
                                'ขนาด: ${item.selectedSize}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF22C55E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
            
            SizedBox(height: 16),
            
            // Bottom row กับราคาและปุ่มจำนวน
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ราคาต่อชิ้น
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ราคาต่อชิ้น',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '฿${NumberFormat('#,##0.00').format(item.price)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                
                // ปุ่มควบคุมจำนวน
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ปุ่มลดจำนวน
                      GestureDetector(
                        onTap: () {
                          if (item.quantity == 1) {
                            // ถ้าจำนวนเหลือ 1 แล้วกดลบอีก ให้แสดงการยืนยัน
                            _showDeleteConfirmation(context, item, cartProvider);
                          } else {
                            // ถ้ามีมากกว่า 1 ก็ลดจำนวนได้เลย
                            cartProvider.decreaseQuantity(item.id);
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      
                      // จำนวน
                      Container(
                        width: 60,
                        height: 36,
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ),
                      
                      // ปุ่มเพิ่มจำนวน
                      GestureDetector(
                        onTap: () {
                          cartProvider.increaseQuantity(item.id);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ราคารวม
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'รวม',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '฿${NumberFormat('#,##0.00').format(item.totalPrice)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
            // สรุปราคา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ราคารวม (${cartProvider.itemCount} รายการ)',
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
                  cartProvider.shippingFee > 0 
                      ? '฿${NumberFormat('#,##0.00').format(cartProvider.shippingFee)}'
                      : 'ฟรี',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cartProvider.shippingFee > 0 
                        ? Color(0xFF1F2937)
                        : Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            
            Divider(height: 32, thickness: 1, color: Color(0xFFE5E7EB)),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ยอดรวมทั้งหมด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '฿${NumberFormat('#,##0.00').format(cartProvider.total)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            
            if (cartProvider.shippingFee == 0 && cartProvider.subtotal < 1000)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'ซื้อเพิ่ม ฿${NumberFormat('#,##0.00').format(1000 - cartProvider.subtotal)} เพื่อได้ฟรีค่าส่ง',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF059669),
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('ยืนยันการลบสินค้า'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'คุณต้องการลบสินค้านี้ออกจากตะกร้าหรือไม่?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        item.productImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'จำนวน: ${item.quantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // ปิด dialog ก่อน
                Navigator.of(context).pop();
                
                // รอให้ dialog ปิดสนิท
                await Future.delayed(Duration(milliseconds: 100));
                
                // แล้วค่อยลบสินค้า
                cartProvider.removeFromCart(item.id);
                
                // แสดง SnackBar หลังจากลบเสร็จ
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('ลบสินค้าออกจากตะกร้าแล้ว'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ลบออก',
                style: TextStyle(fontSize: 16),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_sweep, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('ยืนยันการล้างตะกร้า'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'คุณต้องการลบสินค้าทั้งหมดออกจากตะกร้าหรือไม่?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'จะลบสินค้าทั้งหมด ${cartProvider.cartItems.length} รายการ',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // ปิด dialog ก่อน
                Navigator.of(context).pop();
                
                // รอให้ dialog ปิดสนิท
                await Future.delayed(Duration(milliseconds: 100));
                
                // แล้วค่อยล้างตะกร้า
                cartProvider.clearCart();
                
                // แสดง SnackBar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('ล้างตะกร้าเรียบร้อยแล้ว'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ล้างทั้งหมด',
                style: TextStyle(fontSize: 16),
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
