import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

class ProductDetailPage extends StatefulWidget {
  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  String? selectedColor;
  String? selectedSize;
  int selectedImageIndex = 0; // สำหรับควบคุมรูปที่เลือก
  PageController _pageController = PageController(); // สำหรับควบคุม PageView

  @override
  void initState() {
    super.initState();
    // ตั้งค่า Cart Provider
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Product? product = ModalRoute.of(context)?.settings.arguments as Product?;
    if (product != null) {
      // ตั้งค่าเริ่มต้นของสีและขนาด
      if (selectedColor == null && product.colors.isNotEmpty && product.colors.first != 'Default') {
        selectedColor = product.colors.first;
      }
      if (selectedSize == null && product.sizes.isNotEmpty && product.sizes.first != 'Standard') {
        selectedSize = product.sizes.first;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // รับข้อมูลสินค้าจาก arguments
    final Product? product = ModalRoute.of(context)?.settings.arguments as Product?;
    
    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
        ),
        title: Text(
          product.name,
          style: TextStyle(color: Color(0xFF1E293B)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Gallery
            _buildImageGallery(product),

            // Product Details
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '฿${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Rating
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < product.rating.floor() ? Icons.star : Icons.star_border,
                            color: Color(0xFFFBBF24),
                            size: 20,
                          );
                        }),
                      ),
                      SizedBox(width: 8),
                      Text('${product.rating} (${product.reviewCount} reviews)'),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Color Selection
                  if (product.colors.isNotEmpty && product.colors.first != 'Default')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สี',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: product.colors.map((color) {
                            final isSelected = selectedColor == color;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedColor = color;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(0xFF6366F1) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? Color(0xFF6366F1) : Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  color,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),

                  // Size Selection
                  if (product.sizes.isNotEmpty && product.sizes.first != 'Standard')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ขนาด',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: product.sizes.map((size) {
                            final isSelected = selectedSize == size;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedSize = size;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Color(0xFF6366F1) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? Color(0xFF6366F1) : Color(0xFFE2E8F0),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),

                  // Quantity
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 1 ? () {
                          setState(() { quantity--; });
                        } : null,
                        icon: Icon(Icons.remove),
                      ),
                      Text(
                        quantity.toString(),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() { quantity++; });
                        },
                        icon: Icon(Icons.add),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),

                  // Add to Cart Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        // ตรวจสอบว่าเลือกสีและขนาดครบหรือไม่
                        bool hasColors = product.colors.isNotEmpty && product.colors.first != 'Default';
                        bool hasSizes = product.sizes.isNotEmpty && product.sizes.first != 'Standard';
                        
                        if (hasColors && selectedColor == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('กรุณาเลือกสี'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (hasSizes && selectedSize == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('กรุณาเลือกขนาด'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // ตรวจสอบการเข้าสู่ระบบ
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        if (!authProvider.isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('กรุณาเข้าสู่ระบบก่อนเพิ่มสินค้าลงตะกร้า'),
                              backgroundColor: Colors.orange,
                              action: SnackBarAction(
                                label: 'เข้าสู่ระบบ',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          // เพิ่มสินค้าลงตะกร้า
                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          await cartProvider.addToCart(
                            product: product,
                            quantity: quantity,
                            selectedColor: selectedColor,
                            selectedSize: selectedSize,
                          );

                          // สร้างข้อความแสดงสีและขนาดที่เลือก
                          String cartMessage = 'เพิ่ม ${product.name} ลงตะกร้าแล้ว';
                          if (selectedColor != null) {
                            cartMessage += ' (สี: $selectedColor';
                          }
                          if (selectedSize != null) {
                            if (selectedColor != null) {
                              cartMessage += ', ขนาด: $selectedSize)';
                            } else {
                              cartMessage += ' (ขนาด: $selectedSize)';
                            }
                          } else if (selectedColor != null) {
                            cartMessage += ')';
                          }
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(cartMessage),
                              backgroundColor: Color(0xFF10B981),
                              action: SnackBarAction(
                                label: 'ดูตะกร้า',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/cart');
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Add to Cart - ฿${(product.price * quantity).toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // สร้าง Image Gallery แบบ Lazada
  Widget _buildImageGallery(Product product) {
    // เตรียมรายการรูปภาพ (ใช้ imageUrls ถ้ามี ไม่เช่นนั้นใช้ imageUrl เดียว)
    List<String> images = [];
    
    if (product.imageUrls.isNotEmpty) {
      // ใช้รูปทั้งหมดจาก imageUrls
      images = product.imageUrls.where((url) => url.isNotEmpty).toList();
    } else if (product.imageUrl.isNotEmpty) {
      // ใช้รูปเดียวจาก imageUrl (backward compatibility)
      images = [product.imageUrl];
    }
    
    // ถ้าไม่มีรูปเลย ให้ใช้รูป placeholder
    if (images.isEmpty) {
      images = [''];
    }

    return Column(
      children: [
        // รูปใหญ่หลัก
        Container(
          width: double.infinity,
          height: 300,
          margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // PageView สำหรับเลื่อนรูป
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      selectedImageIndex = index;
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return images[index].isNotEmpty
                        ? Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                        : _buildPlaceholderImage();
                  },
                ),
              ),
              
              // Indicator จำนวนรูป (ถ้ามีมากกว่า 1 รูป)
              if (images.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selectedImageIndex + 1}/${images.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              
              // Navigation arrows (ถ้ามีมากกว่า 1 รูป)
              if (images.length > 1) ...[
                // Previous arrow
                if (selectedImageIndex > 0)
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Next arrow
                if (selectedImageIndex < images.length - 1)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        
        // รูปเล็กด้านล่าง (thumbnails) - แสดงเมื่อมีมากกว่า 1 รูป
        if (images.length > 1)
          Container(
            height: 80,
            margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                bool isSelected = index == selectedImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImageIndex = index;
                    });
                    _pageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Color(0xFF6366F1) 
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(0xFF6366F1).withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: images[index].isNotEmpty
                          ? Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage(size: 35);
                              },
                            )
                          : _buildPlaceholderImage(size: 35),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // สร้างรูป placeholder
  Widget _buildPlaceholderImage({double size = 80}) {
    return Container(
      color: Color(0xFFF8FAFC),
      child: Center(
        child: Icon(
          Icons.image,
          size: size,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
