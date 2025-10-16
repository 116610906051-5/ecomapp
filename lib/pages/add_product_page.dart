import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/product_service.dart';
import '../services/image_picker_service.dart';
import '../services/firebase_image_service.dart';
import '../services/google_drive_oauth_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/google_drive_auth_dialog.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  
  // Controllers สำหรับ form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _ratingController = TextEditingController();
  final _reviewCountController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  bool _inStock = true;
  bool _isLoading = false;
  
  // ตัวแปรสำหรับจัดการรูปภาพ
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploadingImages = false;
  
  // ตัวแปรสำหรับเลือกบริการอัพโหลด
  String _uploadService = 'firebase'; // 'firebase', 'googledrive', หรือ 'cloudinary'
  
  // ตัวแปรสำหรับจัดการ URL รูปภาพ
  List<String> _manualImageUrls = [];
  final _urlController = TextEditingController();
  
  List<String> _colors = [];
  List<String> _sizes = [];
  
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _ratingController.dispose();
    _reviewCountController.dispose();
    _urlController.dispose(); // เพิ่ม URL controller
    _colorController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เพิ่มสินค้าใหม่',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: 24),
              _buildImageSection(),
              SizedBox(height: 24),
              _buildCategorySection(),
              SizedBox(height: 24),
              _buildVariationsSection(),
              SizedBox(height: 24),
              _buildStockSection(),
              SizedBox(height: 24),
              _buildRatingSection(),
              SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ข้อมูลพื้นฐาน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อสินค้า *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกชื่อสินค้า';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'คำอธิบายสินค้า *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอคำอธิบายสินค้า';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'ราคา (บาท) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกราคา';
                }
                if (double.tryParse(value) == null) {
                  return 'กรุณากรอกราคาเป็นตัวเลข';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รูปภาพสินค้า',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (_isUploadingImages)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            // เลือกบริการอัพโหลด
            Row(
              children: [
                Text(
                  'บริการอัพโหลด:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _uploadService,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        value: 'googledrive',
                        child: Row(
                          children: [
                            Icon(Icons.cloud, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Google Drive'),
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
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // ปุ่มเลือกรูปภาพ
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingImages ? null : _pickImages,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('เลือกรูปภาพ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _selectedImages.isNotEmpty && !_isUploadingImages 
                      ? _uploadImages 
                      : null,
                  icon: Icon(_uploadService == 'firebase' ? Icons.storage : _uploadService == 'cloudinary' ? Icons.cloud_upload : Icons.cloud),
                  label: Text('อัพโหลด'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // แสดงรูปที่เลือก
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'รูปภาพที่เลือก (${_selectedImages.length} รูป)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return _buildSelectedImageCard(_selectedImages[index], index);
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // แสดงรูปที่อัพโหลดแล้ว
            if (_uploadedImageUrls.isNotEmpty) ...[
              Text(
                'รูปภาพที่อัพโหลดแล้ว (${_uploadedImageUrls.length} รูป)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _uploadedImageUrls.length,
                  itemBuilder: (context, index) {
                    return _buildUploadedImageCard(_uploadedImageUrls[index], index);
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // เพิ่ม URL รูปภาพแบบ manual
            Text(
              'เพิ่ม URL รูปภาพ (ไม่บังคับ)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL รูปภาพ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      hintText: 'https://example.com/image.jpg',
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!Uri.tryParse(value)!.isAbsolute) {
                          return 'กรุณากรอก URL ที่ถูกต้อง';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addImageUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text('เพิ่ม'),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // แสดง URL รูปภาพที่เพิ่มแล้ว
            if (_manualImageUrls.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _manualImageUrls.map((url) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 16, color: Color(0xFF6366F1)),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            url.length > 30 ? '${url.substring(0, 30)}...' : url,
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeImageUrl(url),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12),
              
              // แสดง preview รูปจาก URL
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _manualImageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 100,
                      margin: EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.network(
                                _manualImageUrls[index],
                                fit: BoxFit.cover,
                                width: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.error, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'URL ${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'หมวดหมู่',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'เลือกหมวดหมู่ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รูปแบบสินค้า',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            
            // Colors section
            Text('สี', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: InputDecoration(
                      labelText: 'เพิ่มสี',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.palette),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addColor,
                  child: Text('เพิ่ม'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colors.map((color) {
                return Chip(
                  label: Text(color),
                  onDeleted: () => _removeColor(color),
                );
              }).toList(),
            ),
            
            SizedBox(height: 16),
            
            // Sizes section
            Text('ขนาด', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sizeController,
                    decoration: InputDecoration(
                      labelText: 'เพิ่มขนาด',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addSize,
                  child: Text('เพิ่ม'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _sizes.map((size) {
                return Chip(
                  label: Text(size),
                  onDeleted: () => _removeSize(size),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สต็อกสินค้า',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _stockQuantityController,
              decoration: InputDecoration(
                labelText: 'จำนวนสต็อก *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกจำนวนสต็อก';
                }
                if (int.tryParse(value) == null) {
                  return 'กรุณากรอกจำนวนเป็นตัวเลข';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('มีสินค้าในสต็อก'),
              value: _inStock,
              onChanged: (value) {
                setState(() {
                  _inStock = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คะแนนและรีวิว',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ratingController,
                    decoration: InputDecoration(
                      labelText: 'คะแนน (1-5)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final rating = double.tryParse(value);
                        if (rating == null || rating < 1 || rating > 5) {
                          return 'กรุณากรอกคะแนน 1-5';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _reviewCountController,
                    decoration: InputDecoration(
                      labelText: 'จำนวนรีวิว',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.rate_review),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (int.tryParse(value) == null) {
                          return 'กรุณากรอกตัวเลข';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('ยกเลิก'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366F1),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'บันทึกสินค้า',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  void _addColor() {
    if (_colorController.text.isNotEmpty) {
      setState(() {
        _colors.add(_colorController.text);
        _colorController.clear();
      });
    }
  }

  void _removeColor(String color) {
    setState(() {
      _colors.remove(color);
    });
  }

  void _addSize() {
    if (_sizeController.text.isNotEmpty) {
      setState(() {
        _sizes.add(_sizeController.text);
        _sizeController.clear();
      });
    }
  }

  void _removeSize(String size) {
    setState(() {
      _sizes.remove(size);
    });
  }

  // Methods สำหรับจัดการ URL รูปภาพ
  void _addImageUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.isAbsolute == true) {
      if (!_manualImageUrls.contains(url)) {
        setState(() {
          _manualImageUrls.add(url);
          _urlController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เพิ่ม URL รูปภาพแล้ว'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL นี้มีอยู่แล้ว'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอก URL ที่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImageUrl(String url) {
    setState(() {
      _manualImageUrls.remove(url);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบ URL รูปภาพแล้ว'),
        backgroundColor: Color(0xFF6B7280),
      ),
    );
  }

  // Methods สำหรับจัดการรูปภาพ
  Future<void> _pickImages() async {
    print('🔍 กำลังเลือกรูปภาพ...');
    
    try {
      final images = await ImagePickerService.showMultipleImageSourceDialog(
        context,
        maxImages: 10,
      );
      
      print('📷 ได้รูปภาพ ${images.length} รูป');
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
        
        print('✅ เพิ่มรูปภาพลงใน _selectedImages แล้ว: ${_selectedImages.length} รูป');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เลือกรูปภาพแล้ว ${images.length} รูป'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        print('❌ ไม่มีรูปภาพที่เลือก');
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการเลือกรูป: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ'),
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
        // ใช้ Firebase Storage
        urls = await FirebaseImageService.uploadMultipleImages(_selectedImages);
      } else if (_uploadService == 'cloudinary') {
        // ใช้ Cloudinary
        urls = await CloudinaryService.uploadMultipleImages(_selectedImages);
      } else {
        // ใช้ Google Drive
        // ตรวจสอบการ authorize
        if (!GoogleDriveOAuthService.isAuthorized) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => GoogleDriveAuthDialog(),
          );
          
          if (result != true) {
            setState(() {
              _isUploadingImages = false;
            });
            return;
          }
        }
        
        urls = await GoogleDriveOAuthService.uploadMultipleImages(_selectedImages);
      }
      
      setState(() {
        _uploadedImageUrls.addAll(urls);
        _selectedImages.clear(); // ลบรูปที่เลือกออกหลังอัพโหลดเสร็จ
        _isUploadingImages = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพโหลดรูปภาพเสร็จแล้ว ${urls.length} รูป (${_uploadService == 'firebase' ? 'Firebase' : _uploadService == 'cloudinary' ? 'Cloudinary' : 'Google Drive'})'),
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
  }  Widget _buildSelectedImageCard(File imageFile, int index) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(imageFile),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
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
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ImagePickerService.getFileSize(imageFile),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedImageCard(String imageUrl, int index) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.error, color: Colors.grey),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _uploadedImageUrls.removeAt(index);
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
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'อัพโหลดแล้ว',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      // เตรียมรูปภาพ - รวมทุกประเภท
      List<String> allImageUrls = List.from(_uploadedImageUrls); // รูปจากการอัพโหลด
      allImageUrls.addAll(_manualImageUrls); // รูปจาก URL ที่เพิ่มด้วยตนเอง
      
      // ลบ URL ที่ซ้ำกัน
      allImageUrls = allImageUrls.toSet().toList();
      
      // ตรวจสอบว่ามีรูปภาพอย่างน้อย 1 รูป
      if (allImageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กรุณาเพิ่มรูปภาพอย่างน้อย 1 รูป'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final product = Product(
        id: '', // จะถูกสร้าง auto ใน Firestore
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        imageUrl: allImageUrls.first, // รูปหลัก (รูปแรก)
        imageUrls: allImageUrls, // รูปทั้งหมด
        category: _selectedCategory,
        colors: _colors.isEmpty ? ['Default'] : _colors,
        sizes: _sizes.isEmpty ? ['Standard'] : _sizes,
        inStock: _inStock,
        stockQuantity: int.parse(_stockQuantityController.text),
        rating: _ratingController.text.isNotEmpty 
            ? double.parse(_ratingController.text) 
            : 0.0,
        reviewCount: _reviewCountController.text.isNotEmpty 
            ? int.parse(_reviewCountController.text) 
            : 0,
        createdAt: now,
        updatedAt: now,
      );

      await _productService.addProduct(product);

      // รีเฟรชข้อมูลใน ProductProvider
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
      }

      // แสดงข้อความสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เพิ่มสินค้าสำเร็จ!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      // กลับไปหน้าก่อนหน้า
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
