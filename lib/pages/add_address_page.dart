import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/address.dart';
import '../services/address_service.dart';
import '../providers/auth_provider.dart';

class AddAddressPage extends StatefulWidget {
  final Address? address; // For edit mode

  const AddAddressPage({Key? key, this.address}) : super(key: key);

  @override
  _AddAddressPageState createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _postalCodeController;

  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _fullNameController = TextEditingController(
      text: widget.address?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.address?.phoneNumber ?? '',
    );
    _addressLine1Controller = TextEditingController(
      text: widget.address?.addressLine1 ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: widget.address?.addressLine2 ?? '',
    );
    _districtController = TextEditingController(
      text: widget.address?.district ?? '',
    );
    _cityController = TextEditingController(
      text: widget.address?.city ?? '',
    );
    _provinceController = TextEditingController(
      text: widget.address?.province ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.address?.postalCode ?? '',
    );
    
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'แก้ไขที่อยู่' : 'เพิ่มที่อยู่ใหม่',
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
          padding: EdgeInsets.all(20),
          children: [
            // ชื่อ-นามสกุล
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ-นามสกุล',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกชื่อ-นามสกุล';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // เบอร์โทรศัพท์
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'เบอร์โทรศัพท์',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกเบอร์โทรศัพท์';
                }
                if (value.length < 10) {
                  return 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // ที่อยู่บรรทัดที่ 1
            TextFormField(
              controller: _addressLine1Controller,
              decoration: InputDecoration(
                labelText: 'บ้านเลขที่ / ชื่ออาคาร',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกที่อยู่';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // ที่อยู่บรรทัดที่ 2
            TextFormField(
              controller: _addressLine2Controller,
              decoration: InputDecoration(
                labelText: 'ถนน / ซอย (ถ้ามี)',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),

            // ตำบล/แขวง
            TextFormField(
              controller: _districtController,
              decoration: InputDecoration(
                labelText: 'ตำบล/แขวง',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกตำบล/แขวง';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // อำเภอ/เขต
            TextFormField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'อำเภอ/เขต',
                prefixIcon: Icon(Icons.apartment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกอำเภอ/เขต';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // จังหวัด
            TextFormField(
              controller: _provinceController,
              decoration: InputDecoration(
                labelText: 'จังหวัด',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกจังหวัด';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // รหัสไปรษณีย์
            TextFormField(
              controller: _postalCodeController,
              decoration: InputDecoration(
                labelText: 'รหัสไปรษณีย์',
                prefixIcon: Icon(Icons.markunread_mailbox),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกรหัสไปรษณีย์';
                }
                if (value.length != 5) {
                  return 'กรุณากรอกรหัสไปรษณีย์ 5 หลัก';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // ตั้งเป็นที่อยู่เริ่มต้น
            SwitchListTile(
              title: Text('ตั้งเป็นที่อยู่เริ่มต้น'),
              subtitle: Text('ใช้เป็นที่อยู่หลักในการจัดส่ง'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value;
                });
              },
              activeColor: Color(0xFF6366F1),
            ),
            SizedBox(height: 32),

            // ปุ่มบันทึก
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                      isEditMode ? 'บันทึกการแก้ไข' : 'เพิ่มที่อยู่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? authProvider.user?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception('ไม่พบข้อมูลผู้ใช้');
      }

      final now = DateTime.now();
      final addressId = widget.address?.id ?? 
          '${userId}_${now.millisecondsSinceEpoch}';

      final address = Address(
        id: addressId,
        userId: userId,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        district: _districtController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.address != null) {
        await _addressService.updateAddress(address);
      } else {
        await _addressService.addAddress(address);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address != null
                  ? 'แก้ไขที่อยู่สำเร็จ'
                  : 'เพิ่มที่อยู่สำเร็จ',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
