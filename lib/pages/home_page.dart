import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _currentInput = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      // Navigate to products page with search query
      Navigator.pushNamed(
        context, 
        '/products',
        arguments: {'searchQuery': query.trim()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, Welcome!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Find your dream product',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Search Bar
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          setState(() {
                            _currentInput = value;
                          });
                        },
                        onSubmitted: (value) {
                          _performSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          prefixIcon: InkWell(
                            onTap: () {
                              if (_currentInput.isNotEmpty) {
                                _performSearch(_currentInput);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.search,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          suffixIcon: _currentInput.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _currentInput = '';
                                    });
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: Color(0xFF64748B),
                                  ),
                                )
                              : Icon(
                                  Icons.tune,
                                  color: Color(0xFF64748B),
                                ),
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Categories Section
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to products page to show all categories
                            Navigator.pushNamed(context, '/products');
                          },
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryCard('Electronics', Icons.phone_android, Color(0xFF3B82F6)),
                          _buildCategoryCard('Fashion', Icons.checkroom, Color(0xFFEF4444)),
                          _buildCategoryCard('Home & Garden', Icons.home, Color(0xFF10B981)),
                          _buildCategoryCard('Sports', Icons.sports_soccer, Color(0xFFF59E0B)),
                          _buildCategoryCard('Books', Icons.menu_book, Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Featured Products Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Products',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/products');
                          },
                          child: Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Consumer<ProductProvider>(
                      builder: (context, productProvider, child) {
                        if (productProvider.featuredProducts.isEmpty) {
                          return Container(
                            height: 280,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No products available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Please enable Firestore database to see products',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return Container(
                          height: 280,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: productProvider.featuredProducts.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.featuredProducts[index];
                              return _buildProductCard(
                                product.name,
                                '฿${product.price.toStringAsFixed(0)}',
                                _getProductImageUrl(product),
                                product.rating,
                                context,
                                product: product,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Special Offers Banner
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF374151)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Special Offer',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Get 50% off on selected items',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/special-offers');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF1E293B),
                            ),
                            child: Text('Shop Now'),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.local_offer,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate to products page with selected category
        Navigator.pushNamed(
          context,
          '/products',
          arguments: {'category': title},
        );
      },
      child: Container(
        width: 100,
        height: 100, // กำหนดความสูงคงที่เพื่อป้องกัน overflow
        margin: EdgeInsets.only(right: 16),
        padding: EdgeInsets.all(12), // ลด padding จาก 16 เป็น 12
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ใช้พื้นที่เท่าที่จำเป็น
          children: [
            Container(
              padding: EdgeInsets.all(8), // ลด padding จาก 12 เป็น 8
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20, // ลดขนาด icon จาก 24 เป็น 20
              ),
            ),
            SizedBox(height: 8), // ลดจาก 12 เป็น 8
            Flexible( // ใช้ Flexible แทน Text ธรรมดา
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11, // ลดขนาดตัวอักษรจาก 12 เป็น 11
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(String name, String price, String imageUrl, double rating, BuildContext context, {Product? product}) {
    return GestureDetector(
      onTap: () {
        if (product != null) {
          Navigator.pushNamed(
            context, 
            '/product-detail',
            arguments: product,
          );
        }
      },
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Sale Badge
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl.isNotEmpty 
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          ),
                        );
                      },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 60,
                                color: Color(0xFF94A3B8),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 60,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                  ),
                ),
                
                // Sale Badge
                if (product != null && product.isCurrentlyOnSale && product.discountText.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        product.discountText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Color(0xFFFBBF24)),
                      SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price Display - แสดงราคาแบบ Lazada
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product != null && product.isCurrentlyOnSale && product.originalPrice != null) ...[
                              // Original Price (crossed out)
                              Text(
                                '฿${product.displayOriginalPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey[500],
                                  decorationThickness: 2,
                                ),
                              ),
                              // Current Price (discounted)
                              Row(
                                children: [
                                  Text(
                                    '฿${product.displayPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  if (product.discountPercentage != null) ...[
                                    SizedBox(width: 6),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-${product.discountPercentage!.toInt()}%',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ] else ...[
                              // Regular Price
                              Text(
                                price,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_shopping_cart,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method เพื่อดึง URL รูปภาพที่เหมาะสม
  String _getProductImageUrl(Product product) {
    // ใช้รูปแรกจาก imageUrls ถ้ามี
    if (product.imageUrls.isNotEmpty && product.imageUrls.first.isNotEmpty) {
      return product.imageUrls.first;
    }
    // ถ้าไม่มีใน imageUrls ให้ใช้ imageUrl (backward compatibility)
    return product.imageUrl;
  }
}
