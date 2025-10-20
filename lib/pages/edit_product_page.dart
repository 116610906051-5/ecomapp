import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/product_service.dart';
import '../services/image_picker_service.dart';
import '../services/firebase_image_service.dart';
import '../services/cloudinary_service.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  
  // Controllers สำหรับ form fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _ratingController;
  late TextEditingController _reviewCountController;
  
  late String _selectedCategory;
  late bool _inStock;
  bool _isLoading = false;
  
  // ตัวแปรสำหรับจัดการรูปภาพ
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploadingImages = false;
  
  // ตัวแปรสำหรับเลือกบริการอัพโหลด
  String _uploadService = 'firebase';
  
  late List<String> _colors;
  late List<String> _sizes;
  
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();
  
  final List<String> _categories = [
    'Electronics',
    'Fashion', 
    'Home & Garden',
    'Sports',
    'Books',
    'Beauty',
    'Automotive',
    'Toys'
  ];

  @override
  void initState() {
    super.initState();
    
    // กรอกข้อมูลเดิม
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockQuantityController = TextEditingController(text: widget.product.stockQuantity.toString());
    _ratingController = TextEditingController(text: widget.product.rating.toString());
    _reviewCountController = TextEditingController(text: widget.product.reviewCount.toString());
    
    _selectedCategory = widget.product.category;
    _inStock = widget.product.inStock;
    _colors = List<String>.from(widget.product.colors);
    _sizes = List<String>.from(widget.product.sizes);
    _existingImageUrls = widget.product.imageUrls.isNotEmpty 
        ? List<String>.from(widget.product.imageUrls) 
        : [widget.product.imageUrl];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _ratingController.dispose();
    _reviewCountController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แก้ไขสินค้า',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // ชื่อสินค้า
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อสินค้า',
                prefixIcon: Icon(Icons.shopping_bag),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกชื่อสินค้า';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // คำอธิบาย
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'คำอธิบาย',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกคำอธิบาย';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // ราคา
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'ราคา (฿)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกราคา';
                }
                if (double.tryParse(value) == null) {
                  return 'กรุณากรอกราคาที่ถูกต้อง';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // หมวดหมู่
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'หมวดหมู่',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            
            // จำนวนสต็อก
            TextFormField(
              controller: _stockQuantityController,
              decoration: InputDecoration(
                labelText: 'จำนวนสต็อก',
                prefixIcon: Icon(Icons.inventory),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกจำนวนสต็อก';
                }
                if (int.tryParse(value) == null) {
                  return 'กรุณากรอกจำนวนที่ถูกต้อง';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // สถานะสินค้า
            SwitchListTile(
              title: Text('พร้อมขาย'),
              value: _inStock,
              onChanged: (value) {
                setState(() {
                  _inStock = value;
                });
              },
            ),
            SizedBox(height: 16),
            
            // Rating
            TextFormField(
              controller: _ratingController,
              decoration: InputDecoration(
                labelText: 'คะแนนรีวิว (0-5)',
                prefixIcon: Icon(Icons.star),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            
            // Review Count
            TextFormField(
              controller: _reviewCountController,
              decoration: InputDecoration(
                labelText: 'จำนวนรีวิว',
                prefixIcon: Icon(Icons.rate_review),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 24),
            
            // สี
            _buildListSection(
              'สี',
              _colors,
              _colorController,
              Icons.palette,
              () {
                if (_colorController.text.isNotEmpty) {
                  setState(() {
                    _colors.add(_colorController.text);
                    _colorController.clear();
                  });
                }
              },
              (index) {
                setState(() {
                  _colors.removeAt(index);
                });
              },
            ),
            SizedBox(height: 16),
            
            // ขนาด
            _buildListSection(
              'ขนาด',
              _sizes,
              _sizeController,
              Icons.straighten,
              () {
                if (_sizeController.text.isNotEmpty) {
                  setState(() {
                    _sizes.add(_sizeController.text);
                    _sizeController.clear();
                  });
                }
              },
              (index) {
                setState(() {
                  _sizes.removeAt(index);
                });
              },
            ),
            SizedBox(height: 24),
            
            // รูปภาพที่มีอยู่
            if (_existingImageUrls.isNotEmpty) ...[
              Text(
                'รูปภาพปัจจุบัน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImageUrls.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _existingImageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.broken_image, size: 50);
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _existingImageUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 24),
            ],
            
            // เลือกบริการอัพโหลด
            DropdownButtonFormField<String>(
              value: _uploadService,
              decoration: InputDecoration(
                labelText: 'บริการอัพโหลดรูปภาพ',
                prefixIcon: Icon(Icons.cloud_upload),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(
                  value: 'firebase',
                  child: Row(
                    children: [
                      Icon(Icons.storage, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Firebase Storage'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'cloudinary',
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.purple, size: 20),
                      SizedBox(width: 8),
                      Text('Cloudinary'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _uploadService = value;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            
            // ปุ่มเลือกรูปภาพใหม่
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: Icon(Icons.add_photo_alternate),
              label: Text('เพิ่มรูปภาพใหม่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // แสดงรูปภาพที่เลือกใหม่
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'รูปภาพใหม่ที่เลือก (${_selectedImages.length})',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              
              // ปุ่มอัพโหลดรูปภาพใหม่
              ElevatedButton.icon(
                onPressed: _isUploadingImages ? null : _uploadImages,
                icon: _isUploadingImages 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.cloud_upload),
                label: Text(_isUploadingImages ? 'กำลังอัพโหลด...' : 'อัพโหลดรูปภาพ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            SizedBox(height: 32),
            
            // ปุ่มบันทึก
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProduct,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'บันทึกการแก้ไข',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(
    String title,
    List<String> items,
    TextEditingController controller,
    IconData icon,
    VoidCallback onAdd,
    Function(int) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'เพิ่ม$title',
                  prefixIcon: Icon(icon),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add_circle),
              color: Color(0xFF6366F1),
              iconSize: 32,
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.asMap().entries.map((entry) {
            return Chip(
              label: Text(
                entry.value,
                style: TextStyle(fontSize: 13),
              ),
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () => onRemove(entry.key),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePickerService.showMultipleImageSourceDialog(
        context,
        maxImages: 10,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      List<String> urls = [];
      
      if (_uploadService == 'firebase') {
        urls = await FirebaseImageService.uploadMultipleImages(_selectedImages);
      } else if (_uploadService == 'cloudinary') {
        urls = await CloudinaryService.uploadMultipleImages(_selectedImages);
      }
      
      setState(() {
        _uploadedImageUrls.addAll(urls);
        _selectedImages.clear();
        _isUploadingImages = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพโหลดรูปภาพสำเร็จ ${urls.length} รูป'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการอัพโหลด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // รวมรูปภาพทั้งหมด
    List<String> allImageUrls = List.from(_existingImageUrls);
    allImageUrls.addAll(_uploadedImageUrls);
    
    if (allImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเพิ่มรูปภาพอย่างน้อย 1 รูป'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProduct = Product(
        id: widget.product.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrl: allImageUrls.first,
        imageUrls: allImageUrls,
        category: _selectedCategory,
        colors: _colors.isEmpty ? ['Default'] : _colors,
        sizes: _sizes.isEmpty ? ['Standard'] : _sizes,
        inStock: _inStock,
        stockQuantity: int.parse(_stockQuantityController.text),
        rating: _ratingController.text.isNotEmpty 
            ? double.parse(_ratingController.text) 
            : widget.product.rating,
        reviewCount: _reviewCountController.text.isNotEmpty 
            ? int.parse(_reviewCountController.text) 
            : widget.product.reviewCount,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
      );

      await _productService.updateProduct(updatedProduct);

      // รีเฟรชข้อมูล
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('แก้ไขสินค้าสำเร็จ!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
