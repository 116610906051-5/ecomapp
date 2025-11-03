import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class AdminSpecialOffersPage extends StatefulWidget {
  @override
  _AdminSpecialOffersPageState createState() => _AdminSpecialOffersPageState();
}

class _AdminSpecialOffersPageState extends State<AdminSpecialOffersPage> {
  final ProductService _productService = ProductService();
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, on_sale, not_on_sale

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
          'Manage Special Offers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFEF4444),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                final saleProducts = productProvider.products
                    .where((p) => p.isCurrentlyOnSale)
                    .length;
                final totalProducts = productProvider.products.length;
                
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Products on Sale',
                        saleProducts.toString(),
                        Icons.local_fire_department,
                        Color(0xFFEF4444),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Products',
                        totalProducts.toString(),
                        Icons.inventory,
                        Color(0xFF6366F1),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Success Rate',
                        totalProducts > 0 ? '${((saleProducts / totalProducts) * 100).toInt()}%' : '0%',
                        Icons.trending_up,
                        Color(0xFF10B981),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Search and Filter
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color(0xFFF1F5F9),
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Products', 'all'),
                      SizedBox(width: 8),
                      _buildFilterChip('On Sale', 'on_sale'),
                      SizedBox(width: 8),
                      _buildFilterChip('Not on Sale', 'not_on_sale'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Products List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final filteredProducts = _filterProducts(productProvider.products);

                if (filteredProducts.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(filteredProducts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'all';
        });
      },
      selectedColor: Color(0xFFEF4444).withOpacity(0.2),
      checkmarkColor: Color(0xFFEF4444),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      )
                    : Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            ),
            
            SizedBox(width: 16),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.isCurrentlyOnSale)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ON SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Price Display
                  if (product.isCurrentlyOnSale && product.originalPrice != null) ...[
                    Row(
                      children: [
                        Text(
                          '฿${NumberFormat('#,##0').format(product.displayOriginalPrice)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '฿${NumberFormat('#,##0').format(product.displayPrice)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        if (product.discountPercentage != null) ...[
                          SizedBox(width: 8),
                          Text(
                            '(-${product.discountPercentage!.toInt()}%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    Text(
                      '฿${NumberFormat('#,##0').format(product.displayPrice)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 8),
                  
                  // Sale Period
                  if (product.isOnSale && product.saleStartDate != null && product.saleEndDate != null)
                    Text(
                      'Sale: ${DateFormat('dd/MM/yy').format(product.saleStartDate!)} - ${DateFormat('dd/MM/yy').format(product.saleEndDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            
            // Action Button
            Column(
              children: [
                if (product.isCurrentlyOnSale) ...[
                  ElevatedButton(
                    onPressed: () => _removeFromSale(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      minimumSize: Size(80, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Remove', style: TextStyle(fontSize: 12)),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _addToSpecialOffer(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      minimumSize: Size(80, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Add Sale', style: TextStyle(fontSize: 12)),
                  ),
                ],
                
                if (product.isOnSale)
                  TextButton(
                    onPressed: () => _editSpecialOffer(product),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF6366F1),
                      minimumSize: Size(80, 28),
                    ),
                    child: Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty &&
          !product.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !product.category.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Status filter
      switch (_filterStatus) {
        case 'on_sale':
          return product.isCurrentlyOnSale;
        case 'not_on_sale':
          return !product.isCurrentlyOnSale;
        default:
          return true;
      }
    }).toList();
  }

  void _addToSpecialOffer(Product product) {
    showDialog(
      context: context,
      builder: (context) => SpecialOfferDialog(
        product: product,
        onSave: (updatedProduct) async {
          try {
            await _productService.updateProduct(updatedProduct);
            Provider.of<ProductProvider>(context, listen: false).loadProducts();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Special offer added successfully!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
      ),
    );
  }

  void _editSpecialOffer(Product product) {
    showDialog(
      context: context,
      builder: (context) => SpecialOfferDialog(
        product: product,
        isEdit: true,
        onSave: (updatedProduct) async {
          try {
            await _productService.updateProduct(updatedProduct);
            Provider.of<ProductProvider>(context, listen: false).loadProducts();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Special offer updated successfully!')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
      ),
    );
  }

  void _removeFromSale(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from Sale'),
        content: Text('Are you sure you want to remove "${product.name}" from the special offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                final updatedProduct = Product(
                  id: product.id,
                  name: product.name,
                  description: product.description,
                  price: product.originalPrice ?? product.price,
                  imageUrl: product.imageUrl,
                  imageUrls: product.imageUrls,
                  category: product.category,
                  rating: product.rating,
                  reviewCount: product.reviewCount,
                  colors: product.colors,
                  sizes: product.sizes,
                  inStock: product.inStock,
                  stockQuantity: product.stockQuantity,
                  createdAt: product.createdAt,
                  updatedAt: DateTime.now(),
                  isOnSale: false,
                );
                
                await _productService.updateProduct(updatedProduct);
                Provider.of<ProductProvider>(context, listen: false).loadProducts();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product removed from sale successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class SpecialOfferDialog extends StatefulWidget {
  final Product product;
  final bool isEdit;
  final Function(Product) onSave;

  const SpecialOfferDialog({
    Key? key,
    required this.product,
    this.isEdit = false,
    required this.onSave,
  }) : super(key: key);

  @override
  _SpecialOfferDialogState createState() => _SpecialOfferDialogState();
}

class _SpecialOfferDialogState extends State<SpecialOfferDialog> {
  late TextEditingController _discountController;
  late TextEditingController _salePriceController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(
      text: widget.product.discountPercentage?.toString() ?? '10',
    );
    _salePriceController = TextEditingController(
      text: widget.product.isOnSale ? widget.product.price.toString() : '',
    );
    _startDate = widget.product.saleStartDate ?? DateTime.now();
    _endDate = widget.product.saleEndDate ?? DateTime.now().add(Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit Special Offer' : 'Add Special Offer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.product.name,
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            
            // Original Price Display
            Text(
              'Original Price: ฿${NumberFormat('#,##0').format(widget.product.originalPrice ?? widget.product.price)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            
            SizedBox(height: 16),
            
            // Discount Percentage
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Discount Percentage',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _calculateSalePrice();
              },
            ),
            
            SizedBox(height: 12),
            
            // Sale Price (calculated)
            TextField(
              controller: _salePriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Sale Price',
                prefixText: '฿',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            
            SizedBox(height: 16),
            
            // Start Date
            ListTile(
              leading: Icon(Icons.event),
              title: Text('Start Date'),
              subtitle: Text(
                _startDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                    : 'Select start date',
              ),
              onTap: () => _selectDate(context, true),
            ),
            
            // End Date
            ListTile(
              leading: Icon(Icons.event_busy),
              title: Text('End Date'),
              subtitle: Text(
                _endDate != null 
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'Select end date',
              ),
              onTap: () => _selectDate(context, false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDeal,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Save'),
        ),
      ],
    );
  }

  void _calculateSalePrice() {
    final discountText = _discountController.text;
    if (discountText.isNotEmpty) {
      try {
        final discount = double.parse(discountText);
        final originalPrice = widget.product.originalPrice ?? widget.product.price;
        final salePrice = originalPrice - (originalPrice * discount / 100);
        _salePriceController.text = salePrice.toStringAsFixed(0);
      } catch (e) {
        // Invalid input, keep previous value
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate 
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(Duration(days: 7)));
        
    final firstDate = isStartDate 
        ? DateTime.now()
        : (_startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, adjust it
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveDeal() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    final discountText = _discountController.text;
    final salePriceText = _salePriceController.text;

    if (discountText.isEmpty || salePriceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final discount = double.parse(discountText);
      final salePrice = double.parse(salePriceText);

      final updatedProduct = Product(
        id: widget.product.id,
        name: widget.product.name,
        description: widget.product.description,
        price: salePrice,
        imageUrl: widget.product.imageUrl,
        imageUrls: widget.product.imageUrls,
        category: widget.product.category,
        rating: widget.product.rating,
        reviewCount: widget.product.reviewCount,
        colors: widget.product.colors,
        sizes: widget.product.sizes,
        inStock: widget.product.inStock,
        stockQuantity: widget.product.stockQuantity,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
        isOnSale: true,
        originalPrice: widget.product.originalPrice ?? widget.product.price,
        discountPercentage: discount,
        saleStartDate: _startDate,
        saleEndDate: _endDate,
      );

      Navigator.of(context).pop();
      widget.onSave(updatedProduct);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid input: $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }
}
