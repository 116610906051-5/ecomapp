import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class SpecialOffersPage extends StatefulWidget {
  @override
  _SpecialOffersPageState createState() => _SpecialOffersPageState();
}

class _SpecialOffersPageState extends State<SpecialOffersPage> {
  String _sortBy = 'Discount: High to Low';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Special Offers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFEF4444),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'Discount: High to Low',
                child: Text('Discount: High to Low'),
              ),
              PopupMenuItem(
                value: 'Discount: Low to High',
                child: Text('Discount: Low to High'),
              ),
              PopupMenuItem(
                value: 'Price: Low to High',
                child: Text('Price: Low to High'),
              ),
              PopupMenuItem(
                value: 'Price: High to Low',
                child: Text('Price: High to Low'),
              ),
              PopupMenuItem(
                value: 'Newest',
                child: Text('Newest'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Filter products that are currently on sale
          final saleProducts = productProvider.products
              .where((product) => product.isCurrentlyOnSale)
              .toList();

          if (saleProducts.isEmpty) {
            return _buildEmptyState();
          }

          // Sort products based on selected option
          _sortProducts(saleProducts);

          return Column(
            children: [
              // Special Offers Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          '🔥 HOT DEALS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${saleProducts.length} products on sale',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Limited Time Offer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Products Grid
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: saleProducts.length,
                  itemBuilder: (context, index) {
                    return _buildSpecialOfferCard(saleProducts[index]);
                  },
                ),
              ),
            ],
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
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.local_offer_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Special Offers Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Check back soon for amazing deals\nand discounts!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/products');
            },
            icon: Icon(Icons.shopping_bag),
            label: Text('Browse All Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOfferCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: product,
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Discount Badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      child: product.imageUrls.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrls.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text(
                                      'No Image',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    'No Image',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  
                  // Discount Badge
                  if (product.discountText.isNotEmpty)
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
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          product.discountText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                  // Sale Timer (if available)
                  if (product.saleEndDate != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _getTimeRemaining(product.saleEndDate!),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name
                    Flexible(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Pricing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Original Price (crossed out)
                        if (product.originalPrice != null)
                          Text(
                            '฿${NumberFormat('#,##0').format(product.displayOriginalPrice)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey[500],
                              decorationThickness: 2,
                            ),
                          ),
                        
                        // Current Price
                        Text(
                          '฿${NumberFormat('#,##0').format(product.displayPrice)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 2),
                    
                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: Color(0xFFFBBF24),
                        ),
                        SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sortProducts(List<Product> products) {
    switch (_sortBy) {
      case 'Discount: High to Low':
        products.sort((a, b) => (b.discountPercentage ?? 0).compareTo(a.discountPercentage ?? 0));
        break;
      case 'Discount: Low to High':
        products.sort((a, b) => (a.discountPercentage ?? 0).compareTo(b.discountPercentage ?? 0));
        break;
      case 'Price: Low to High':
        products.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
        break;
      case 'Price: High to Low':
        products.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
        break;
      case 'Newest':
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  String _getTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return '<1m';
    }
  }
}
