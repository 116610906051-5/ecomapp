import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  String selectedCategory = 'All';
  String sortBy = 'Popular';
  bool isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _currentInput = '';
  bool _showSearchBar = false;

  final List<String> categories = ['All', 'Electronics', 'Fashion', 'Home & Garden', 'Sports', 'Books'];
  final List<String> sortOptions = ['Popular', 'Price: Low to High', 'Price: High to Low', 'Newest'];

  @override
  void initState() {
    super.initState();
    // Check if we received search query from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['searchQuery'] != null) {
        setState(() {
          _searchQuery = args['searchQuery'];
          _currentInput = args['searchQuery'];
          _searchController.text = args['searchQuery'];
          _showSearchBar = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _currentInput = query.trim();
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Products',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
            icon: Icon(
              isGridView ? Icons.list : Icons.grid_view,
              color: Color(0xFF6366F1),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
              });
              if (_showSearchBar) {
                _searchFocusNode.requestFocus();
              }
            },
            icon: Icon(
              Icons.search,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (conditionally shown)
          if (_showSearchBar)
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE2E8F0)),
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
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    suffixIcon: _currentInput.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _currentInput = '';
                                _searchQuery = '';
                              });
                            },
                            icon: Icon(
                              Icons.clear,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : null,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          
          // Filter and Sort Section
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Categories Filter
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 12),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF6366F1) : Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected ? Color(0xFF6366F1) : Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                // Sort and Filter Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _showSortBottomSheet(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.sort, size: 20, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Text(
                              'Sort: $sortBy',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune, size: 20, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text(
                            'Filter',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Results Info
          if (_searchQuery.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Searching for "${_searchQuery}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _currentInput = '';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Products Grid/List
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: isGridView ? _buildGridView() : _buildListView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        var products = selectedCategory == 'All' 
            ? productProvider.products
            : productProvider.getProductsByCategory(selectedCategory);
            
        // Filter by search query if exists
        if (_searchQuery.isNotEmpty) {
          products = products.where((product) {
            return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   product.category.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
            
        // จัดเรียงข้อมูลตาม sortBy
        products = _sortProducts(List.from(products));
            
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 24),
                Text(
                  'No products available',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Please enable Firestore database\nto see products',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
          
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductGridCard(products[index]);
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        var products = selectedCategory == 'All' 
            ? productProvider.products
            : productProvider.getProductsByCategory(selectedCategory);
            
        // Filter by search query if exists
        if (_searchQuery.isNotEmpty) {
          products = products.where((product) {
            return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   product.category.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
            
        // จัดเรียงข้อมูลตาม sortBy
        products = _sortProducts(List.from(products));
            
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 24),
                Text(
                  'No products available',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Please enable Firestore database\nto see products',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
            
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductListCard(products[index]);
          },
        );
      },
    );
  }

  Widget _buildProductGridCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail', arguments: product);
      },
      child: Container(
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
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: _getProductImageUrl(product).isNotEmpty
                          ? Image.network(
                              _getProductImageUrl(product),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              key: ValueKey(product.id), // เพิ่ม key เพื่อให้ Widget รู้ว่าข้อมูลเปลี่ยน
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image,
                                  size: 50,
                                  color: Color(0xFF94A3B8),
                                );
                              },
                            )
                          : Icon(
                              Icons.image,
                              size: 50,
                              color: Color(0xFF94A3B8),
                            ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // ใช้พื้นที่เท่าที่จำเป็น
                  children: [
                    Flexible( // ใช้ Flexible แทน Text ธรรมดา
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 8), // ใช้ SizedBox แทน Spacer เพื่อควบคุมขนาดได้
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Color(0xFFFBBF24)),
                        SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
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
                        Text(
                          '฿${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            size: 14,
                            color: Colors.white,
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

  Widget _buildProductListCard(Product product) {

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _getProductImageUrl(product).isNotEmpty
                ? Image.network(
                    _getProductImageUrl(product),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    key: ValueKey(product.id), // เพิ่ม key เพื่อให้ Widget รู้ว่าข้อมูลเปลี่ยน
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image,
                        size: 40,
                        color: Color(0xFF94A3B8),
                      );
                    },
                  )
                : Icon(
                    Icons.image,
                    size: 40,
                    color: Color(0xFF94A3B8),
                  ),
            ),
          ),
          SizedBox(width: 16),
          // Product Info
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
                ),
                SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Color(0xFFFBBF24)),
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
              ],
            ),
          ),
          SizedBox(width: 16),
          // Price and Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '฿${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
              SizedBox(height: 8),
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
    );
  }

  // จัดเรียงสินค้าตามเงื่อนไขที่เลือก
  List<Product> _sortProducts(List<Product> products) {
    switch (sortBy) {
      case 'Price: Low to High':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest':
        // จัดเรียงตาม ID หรือวันที่สร้าง (ใหม่ที่สุดก่อน)
        products.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Popular':
      default:
        // จัดเรียงตาม rating สูงสุดก่อน
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return products;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort by',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 20),
            ...sortOptions.map((option) => ListTile(
              title: Text(option),
              trailing: sortBy == option ? Icon(Icons.check, color: Color(0xFF6366F1)) : null,
              onTap: () {
                setState(() {
                  sortBy = option;
                });
                Navigator.pop(context);
              },
            )).toList(),
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
