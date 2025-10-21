import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart' as auth;
import '../services/order_service.dart';
import '../services/address_service.dart';
import '../services/coupon_service.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../models/coupon.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _couponController = TextEditingController();

  final AddressService _addressService = AddressService();
  final CouponService _couponService = CouponService();
  
  Address? _selectedAddress;
  Coupon? _appliedCoupon;
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  bool _isApplyingCoupon = false;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        final defaultAddress = await _addressService.getDefaultAddress(authProvider.user!.uid);
        if (defaultAddress != null) {
          setState(() {
            _selectedAddress = defaultAddress;
            _fillAddressFields(defaultAddress);
          });
        }
      } catch (e) {
        print('Error loading default address: $e');
      }
    }
  }

  void _fillAddressFields(Address address) {
    _nameController.text = address.fullName;
    _phoneController.text = address.phoneNumber;
    _addressController.text = '${address.addressLine1} ${address.addressLine2}'.trim();
    _cityController.text = address.province;
    _postalController.text = address.postalCode;
  }

  Future<void> _selectAddress() async {
    final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      '/addresses',
      arguments: {'selectionMode': true},
    );

    if (result != null && result is Address) {
      setState(() {
        _selectedAddress = result;
        _fillAddressFields(result);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _couponController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ชำระเงิน'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ตะกร้าสินค้าว่างเปล่า', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สรุปคำสั่งซื้อ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          ...cartProvider.cart!.items.map((item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('${item.productName} x${item.quantity}'),
                                ),
                                Text('₿${(item.price * item.quantity).toStringAsFixed(2)}'),
                              ],
                            ),
                          )),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'รวมทั้งหมด',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₿${cartProvider.cart!.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Customer Information
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ข้อมูลผู้สั่งซื้อ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อ-นามสกุล',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อ-นามสกุล';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'เบอร์โทรศัพท์',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกเบอร์โทรศัพท์';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Shipping Address
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ที่อยู่จัดส่ง',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _selectAddress,
                                icon: Icon(Icons.location_on, size: 18),
                                label: Text('เลือกที่อยู่ที่บันทึกไว้'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedAddress != null) ...[
                            Container(
                              margin: EdgeInsets.only(top: 8, bottom: 16),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.orange, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'ใช้ที่อยู่นี้',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(_selectedAddress!.fullAddress),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อ-นามสกุล',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อ-นามสกุล';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'เบอร์โทรศัพท์',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกเบอร์โทรศัพท์';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'ที่อยู่',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกที่อยู่';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityController,
                                  decoration: InputDecoration(
                                    labelText: 'จังหวัด',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.location_city),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกจังหวัด';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _postalController,
                                  decoration: InputDecoration(
                                    labelText: 'รหัสไปรษณีย์',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.local_post_office),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'กรุณากรอกรหัสไปรษณีย์';
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
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Coupon Code Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'โค้ดส่วนลด',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    labelText: 'กรอกโค้ดส่วนลด',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.discount, color: Colors.orange),
                                    hintText: 'เช่น SAVE10',
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                  enabled: _discountAmount == 0,
                                ),
                              ),
                              SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: (_discountAmount > 0 || _isApplyingCoupon) 
                                  ? null 
                                  : () => _applyCoupon(cartProvider),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                                child: _isApplyingCoupon
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(_discountAmount > 0 ? 'ใช้แล้ว' : 'ใช้'),
                              ),
                            ],
                          ),
                          if (_discountAmount > 0) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ส่วนลด ฿${_discountAmount.toStringAsFixed(2)} ถูกใช้แล้ว',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, size: 18),
                                    color: Colors.green.shade700,
                                    onPressed: _removeCoupon,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Payment Method
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'วิธีการชำระเงิน',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                Icon(Icons.credit_card, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('บัตรเครดิต/เดบิต'),
                              ],
                            ),
                            value: 'card',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: Row(
                              children: [
                                Icon(Icons.money, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('เก็บเงินปลายทาง'),
                              ],
                            ),
                            value: 'cod',
                            groupValue: _selectedPaymentMethod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _processCheckout(context, cartProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'ยืนยันการสั่งซื้อ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _applyCoupon(CartProvider cartProvider) async {
    final couponCode = _couponController.text.trim().toUpperCase();
    
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกโค้ดส่วนลด'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isApplyingCoupon = true;
    });

    try {
      final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อน');
      }

      final result = await _couponService.validateAndUseCoupon(
        code: couponCode,
        orderAmount: cartProvider.cart!.totalAmount,
      );

      if (result['success'] == true) {
        setState(() {
          _appliedCoupon = result['coupon'];
          _discountAmount = result['discountAmount'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ใช้โค้ดส่วนลดสำเร็จ! ลด ฿${_discountAmount.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          _isApplyingCoupon = false;
        });
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0.0;
      _couponController.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ยกเลิกโค้ดส่วนลดแล้ว'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _processCheckout(BuildContext context, CartProvider cartProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is logged in
    final authProvider = Provider.of<auth.AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนทำการสั่งซื้อ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show payment confirmation dialog
    final double finalAmount = cartProvider.cart!.totalAmount - _discountAmount;
    final confirmed = await _showPaymentConfirmationDialog(context, finalAmount);
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create shipping address
      final shippingAddress = ShippingAddress(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        district: _cityController.text, // Using city as district for demo
        province: _cityController.text,
        postalCode: _postalController.text,
      );

      // Map payment method
      PaymentMethod paymentMethod = PaymentMethod.creditCard;
      switch (_selectedPaymentMethod) {
        case 'card':
          paymentMethod = PaymentMethod.creditCard;
          break;
        case 'cod':
          paymentMethod = PaymentMethod.cod;
          break;
      }

      // Create order
      final order = await OrderService.createOrderFromCart(
        userId: authProvider.user!.uid,
        customerName: _nameController.text,
        customerEmail: authProvider.user!.email ?? '',
        customerPhone: _phoneController.text,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        couponId: _appliedCoupon?.id,
        discountAmount: _discountAmount,
      );

      // Process payment based on method
      if (_selectedPaymentMethod == 'card') {
        // Card payment - Use Stripe
        try {
          print('💳 Processing Stripe payment...');
          
          // Create payment intent
          final paymentIntent = await OrderService.createPaymentIntentForOrder(
            orderId: order.id,
            amount: finalAmount,
          );
          
          // Present Stripe Payment Sheet
          final paymentResult = await _presentStripePaymentSheet(
            paymentIntentClientSecret: paymentIntent['client_secret'],
          );
          
          if (paymentResult) {
            // Payment successful - set to packing status
            await OrderService.updatePaymentStatus(
              orderId: order.id,
              status: OrderStatus.packing,
              paymentIntentId: paymentIntent['id'],
            );
            print('✅ Stripe payment completed successfully');
          } else {
            // Payment cancelled or failed
            throw Exception('การชำระเงินถูกยกเลิกหรือไม่สำเร็จ');
          }
        } catch (e) {
          print('❌ Stripe payment error: $e');
          // Cancel order if payment fails
          await OrderService.updateOrderStatus(
            orderId: order.id,
            status: OrderStatus.cancelled,
          );
          rethrow;
        }
      } else if (_selectedPaymentMethod == 'cod') {
        // COD - set to packing status
        await OrderService.updateOrderStatus(
          orderId: order.id,
          status: OrderStatus.packing,
        );
      }

      // Increment coupon usage count if coupon was used
      if (_appliedCoupon != null) {
        await _couponService.incrementUsageCount(_appliedCoupon!.id);
      }

      // Clear cart after successful order
      await cartProvider.clearCart();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สั่งซื้อสำเร็จ! หมายเลขคำสั่งซื้อ: ${order.formattedOrderNumber}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
      
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
          _isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _showPaymentConfirmationDialog(BuildContext context, double finalAmount) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ชำระเงิน',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
            
            Divider(height: 1),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getPaymentMethodColor(_selectedPaymentMethod).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getPaymentMethodIcon(_selectedPaymentMethod),
                              color: _getPaymentMethodColor(_selectedPaymentMethod),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPaymentMethodName(_selectedPaymentMethod),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _getPaymentMethodDescription(_selectedPaymentMethod),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Order Summary
                    Text(
                      'รายละเอียดคำสั่งซื้อ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'จำนวนสินค้า',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${cartProvider.cart!.items.fold(0, (sum, item) => sum + item.quantity)} ชิ้น',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ยอดรวม',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '฿${cartProvider.cart!.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          if (_discountAmount > 0) ...[
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.discount, size: 16, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text(
                                      'ส่วนลด',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-฿${_discountAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          SizedBox(height: 12),
                          Divider(height: 1),
                          SizedBox(height: 12),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ยอดชำระ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                '฿${finalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Shipping Address
                    if (_selectedAddress != null) ...[
                      Text(
                        'ที่อยู่จัดส่ง',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: Color(0xFF6366F1)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedAddress!.fullName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _selectedAddress!.phoneNumber,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _selectedAddress!.fullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                    
                    // Security Notice
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, size: 16, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'การชำระเงินของคุณปลอดภัย',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with Buttons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'ยืนยันการชำระเงิน ฿${finalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.account_balance;
      case 'cod':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }
  
  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'card':
        return Color(0xFF6366F1);
      case 'transfer':
        return Color(0xFF0EA5E9);
      case 'cod':
        return Color(0xFF10B981);
      default:
        return Color(0xFF64748B);
    }
  }
  
  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'card':
        return 'บัตรเครดิต/เดบิต';
      case 'transfer':
        return 'โอนเงินผ่านธนาคาร';
      case 'cod':
        return 'เก็บเงินปลายทาง';
      default:
        return 'ไม่ทราบ';
    }
  }
  
  String _getPaymentMethodDescription(String method) {
    switch (method) {
      case 'card':
        return 'ชำระเงินด้วยบัตรเครดิตหรือเดบิต';
      case 'transfer':
        return 'โอนเงินผ่านบัญชีธนาคาร';
      case 'cod':
        return 'ชำระเงินเมื่อได้รับสินค้า';
      default:
        return '';
    }
  }

  Future<bool> _presentStripePaymentSheet({
    required String paymentIntentClientSecret,
  }) async {
    try {
      print('🔄 Initializing Stripe Payment Sheet...');
      
      // Initialize payment sheet
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: 'E-Commerce App',
          style: ThemeMode.system,
          appearance: stripe.PaymentSheetAppearance(
            colors: stripe.PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1),
            ),
          ),
        ),
      );

      print('✅ Payment sheet initialized');
      
      // Present payment sheet
      await stripe.Stripe.instance.presentPaymentSheet();
      
      print('✅ Payment completed successfully');
      return true;
    } on stripe.StripeException catch (e) {
      print('❌ Stripe Exception: ${e.error.localizedMessage}');
      if (e.error.code == stripe.FailureCode.Canceled) {
        print('⚠️ Payment cancelled by user');
      }
      return false;
    } catch (e) {
      print('❌ Error presenting payment sheet: $e');
      return false;
    }
  }
}
