import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await wishlistProvider.loadWishlist(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'รายการโปรด',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              if (wishlistProvider.itemCount > 0) {
                return IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () => _showClearDialog(context),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, child) {
          if (wishlistProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (wishlistProvider.wishlistItems.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadWishlist,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: wishlistProvider.wishlistItems.length,
              itemBuilder: (context, index) {
                final product = wishlistProvider.wishlistItems[index];
                return _buildWishlistItem(context, product);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีรายการโปรด',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เพิ่มสินค้าที่คุณชอบเข้ารายการโปรด',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/products');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366F1),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              'ค้นหาสินค้า',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(BuildContext context, Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrls.isNotEmpty
                      ? Image.network(
                          product.imageUrls[0],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.grey,
                          ),
                        )
                      : product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.shopping_bag,
                                size: 40,
                                color: Colors.grey,
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag,
                              size: 40,
                              color: Colors.grey,
                            ),
                ),
              ),
              SizedBox(width: 12),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '฿${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        Row(
                          children: [
                            // Add to Cart Button
                            Consumer<CartProvider>(
                              builder: (context, cartProvider, child) {
                                return IconButton(
                                  icon: Icon(Icons.shopping_cart_outlined),
                                  color: Color(0xFF6366F1),
                                  onPressed: () async {
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    if (authProvider.user != null) {
                                      await cartProvider.addToCart(product: product);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('เพิ่มลงตะกร้าแล้ว'),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                            // Remove from Wishlist Button
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              color: Colors.red,
                              onPressed: () => _removeFromWishlist(context, product.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeFromWishlist(BuildContext context, String productId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        await wishlistProvider.removeFromWishlist(authProvider.user!.uid, productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบออกจากรายการโปรดแล้ว'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ล้างรายการโปรด'),
        content: Text('คุณต้องการลบรายการโปรดทั้งหมดหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
              
              if (authProvider.user != null) {
                try {
                  // Clear from Firebase
                  await wishlistProvider.removeFromWishlist(
                    authProvider.user!.uid,
                    '', // Will clear all
                  );
                  wishlistProvider.clearWishlist();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ล้างรายการโปรดแล้ว'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('ลบทั้งหมด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
