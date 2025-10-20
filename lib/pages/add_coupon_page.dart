import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coupon.dart';
import '../services/coupon_service.dart';

class AddCouponPage extends StatefulWidget {
  final Coupon? coupon;

  AddCouponPage({this.coupon});

  @override
  _AddCouponPageState createState() => _AddCouponPageState();
}

class _AddCouponPageState extends State<AddCouponPage> {
  final _formKey = GlobalKey<FormState>();
  final CouponService _couponService = CouponService();

  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _minPurchaseController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _usageLimitController;

  CouponType _selectedType = CouponType.percentage;
  DateTime? _startDate;
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.coupon?.code ?? '');
    _descriptionController = TextEditingController(text: widget.coupon?.description ?? '');
    _discountValueController = TextEditingController(
      text: widget.coupon?.discountValue.toString() ?? '',
    );
    _minPurchaseController = TextEditingController(
      text: widget.coupon?.minPurchaseAmount?.toString() ?? '',
    );
    _maxDiscountController = TextEditingController(
      text: widget.coupon?.maxDiscountAmount?.toString() ?? '',
    );
    _usageLimitController = TextEditingController(
      text: widget.coupon?.usageLimit?.toString() ?? '',
    );

    if (widget.coupon != null) {
      _selectedType = widget.coupon!.type;
      _startDate = widget.coupon!.startDate;
      _expiryDate = widget.coupon!.expiryDate;
      _isActive = widget.coupon!.isActive;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.coupon != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'แก้ไขโค้ดส่วนลด' : 'สร้างโค้ดส่วนลด',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Code
            _buildSectionTitle('รหัสโค้ด'),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'ตัวอย่าง: WELCOME2024',
                prefixIcon: Icon(Icons.confirmation_number),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              enabled: !isEdit, // ไม่ให้แก้ไขโค้ดถ้าเป็นการแก้ไข
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกรหัสโค้ด';
                }
                if (value.length < 4) {
                  return 'รหัสโค้ดต้องมีอย่างน้อย 4 ตัวอักษร';
                }
                return null;
              },
            ),
            if (isEdit) ...[
              SizedBox(height: 8),
              Text(
                '* ไม่สามารถแก้ไขรหัสโค้ดได้',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            SizedBox(height: 20),

            // Description
            _buildSectionTitle('คำอธิบาย'),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'อธิบายรายละเอียดของโค้ดส่วนลด',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกคำอธิบาย';
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            // Discount Type
            _buildSectionTitle('ประเภทส่วนลด'),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<CouponType>(
                    title: Text('ลดเปอร์เซ็นต์ (%)'),
                    subtitle: Text('ลดตามเปอร์เซ็นต์ของยอดรวม'),
                    value: CouponType.percentage,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  Divider(height: 1),
                  RadioListTile<CouponType>(
                    title: Text('ลดจำนวนเงิน (฿)'),
                    subtitle: Text('ลดเป็นจำนวนเงินคงที่'),
                    value: CouponType.fixedAmount,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Discount Value
            _buildSectionTitle(
              _selectedType == CouponType.percentage
                  ? 'ส่วนลด (เปอร์เซ็นต์)'
                  : 'ส่วนลด (บาท)',
            ),
            TextFormField(
              controller: _discountValueController,
              decoration: InputDecoration(
                hintText: _selectedType == CouponType.percentage ? '10' : '100',
                prefixIcon: Icon(Icons.local_offer),
                suffixText: _selectedType == CouponType.percentage ? '%' : '฿',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกจำนวนส่วนลด';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'จำนวนต้องมากกว่า 0';
                }
                if (_selectedType == CouponType.percentage && amount > 100) {
                  return 'เปอร์เซ็นต์ต้องไม่เกิน 100';
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            // Min Purchase Amount
            _buildSectionTitle('ยอดซื้อขั้นต่ำ (ไม่บังคับ)'),
            TextFormField(
              controller: _minPurchaseController,
              decoration: InputDecoration(
                hintText: 'ไม่จำกัด',
                prefixIcon: Icon(Icons.shopping_cart),
                suffixText: '฿',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            SizedBox(height: 20),

            // Max Discount (for percentage only)
            if (_selectedType == CouponType.percentage) ...[
              _buildSectionTitle('ส่วนลดสูงสุด (บาท) (ไม่บังคับ)'),
              TextFormField(
                controller: _maxDiscountController,
                decoration: InputDecoration(
                  hintText: 'ไม่จำกัด',
                  prefixIcon: Icon(Icons.money_off),
                  suffixText: '฿',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              SizedBox(height: 20),
            ],

            // Usage Limit
            _buildSectionTitle('จำนวนการใช้งานสูงสุด (ไม่บังคับ)'),
            TextFormField(
              controller: _usageLimitController,
              decoration: InputDecoration(
                hintText: 'ไม่จำกัด',
                prefixIcon: Icon(Icons.people),
                suffixText: 'ครั้ง',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            SizedBox(height: 20),

            // Start Date
            _buildSectionTitle('วันที่เริ่มใช้งาน (ไม่บังคับ)'),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    SizedBox(width: 16),
                    Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'เริ่มใช้งานทันที',
                      style: TextStyle(
                        fontSize: 16,
                        color: _startDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    if (_startDate != null)
                      IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Expiry Date
            _buildSectionTitle('วันหมดอายุ'),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: Colors.grey[600]),
                    SizedBox(width: 16),
                    Text(
                      _expiryDate != null
                          ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                          : 'เลือกวันหมดอายุ',
                      style: TextStyle(
                        fontSize: 16,
                        color: _expiryDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_expiryDate == null) ...[
              SizedBox(height: 8),
              Text(
                'กรุณาเลือกวันหมดอายุ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],
            SizedBox(height: 20),

            // Active Status
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: Text('เปิดใช้งานทันที'),
                subtitle: Text('โค้ดจะพร้อมใช้งานทันทีหลังจากบันทึก'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ),
            SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEdit ? 'บันทึกการแก้ไข' : 'สร้างโค้ดส่วนลด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? now)
          : (_expiryDate ?? now.add(Duration(days: 30))),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกวันหมดอายุ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อน');
      }

      final coupon = Coupon(
        id: widget.coupon?.id ?? '',
        code: _codeController.text.toUpperCase().trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        discountValue: double.parse(_discountValueController.text),
        minPurchaseAmount: _minPurchaseController.text.isNotEmpty
            ? double.parse(_minPurchaseController.text)
            : null,
        maxDiscountAmount: _maxDiscountController.text.isNotEmpty
            ? double.parse(_maxDiscountController.text)
            : null,
        startDate: _startDate ?? DateTime.now(),
        expiryDate: _expiryDate!,
        usageLimit: _usageLimitController.text.isNotEmpty
            ? int.parse(_usageLimitController.text)
            : null,
        usageCount: widget.coupon?.usageCount ?? 0,
        isActive: _isActive,
        createdAt: widget.coupon?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
      );

      if (widget.coupon == null) {
        // Create new
        await _couponService.createCoupon(coupon);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สร้างโค้ดส่วนลดสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update existing
        await _couponService.updateCoupon(coupon);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('แก้ไขโค้ดส่วนลดสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }

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
