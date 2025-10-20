import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart' as auth;
import '../services/order_service.dart';
import '../services/address_service.dart';
import '../models/order.dart';
import '../models/address.dart';
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

  final AddressService _addressService = AddressService();
  Address? _selectedAddress;
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

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
                                Icon(Icons.account_balance, color: Colors.green),
                                SizedBox(width: 8),
                                Text('โอนเงินผ่านธนาคาร'),
                              ],
                            ),
                            value: 'transfer',
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
        case 'transfer':
          paymentMethod = PaymentMethod.bankTransfer;
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
      );

      // Process payment for credit card
      if (_selectedPaymentMethod == 'card') {
        try {
          print('💳 Processing credit card payment...');
          
          // Create payment intent
          final paymentIntent = await OrderService.createPaymentIntentForOrder(
            orderId: order.id,
            amount: order.totalAmount,
          );
          
          // Present Stripe Payment Sheet
          final paymentResult = await _presentStripePaymentSheet(
            paymentIntentClientSecret: paymentIntent['client_secret'],
          );
          
          if (paymentResult) {
            // Payment successful
            await OrderService.updatePaymentStatus(
              orderId: order.id,
              status: OrderStatus.paid,
              paymentIntentId: paymentIntent['id'],
            );
            
            print('✅ Payment completed successfully');
          } else {
            // Payment cancelled or failed
            throw Exception('การชำระเงินถูกยกเลิกหรือไม่สำเร็จ');
          }
        } catch (e) {
          print('❌ Payment error: $e');
          // Cancel order if payment fails
          await OrderService.updateOrderStatus(
            orderId: order.id,
            status: OrderStatus.cancelled,
          );
          rethrow; // Re-throw to show error to user
        }
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
              primary: Colors.orange,
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
