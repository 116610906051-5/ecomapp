import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class StripeService {
  // ใช้ Configuration Class เพื่อแยก API keys
  static String get publishableKey => StripeConfig.publishableKey;
  static String get secretKey => StripeConfig.secretKey;
  
  static const String baseUrl = 'https://api.stripe.com/v1';
  
  /// Initialize Stripe
  static Future<void> init() async {
    try {
      Stripe.publishableKey = publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.ecom.app';
      await Stripe.instance.applySettings();
      print('✅ Stripe initialized successfully');
    } catch (e) {
      print('❌ Error initializing Stripe: $e');
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// สร้าง Payment Intent
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔄 Creating payment intent for amount: $amount $currency');
      
      final response = await http.post(
        Uri.parse('$baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).round().toString(), // Convert to cents
          'currency': currency.toLowerCase(),
          if (customerId != null) 'customer': customerId,
          if (metadata != null) 
            ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Payment intent created: ${data['id']}');
        return data;
      } else {
        print('❌ Error creating payment intent: ${response.body}');
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in createPaymentIntent: $e');
      throw Exception('Error creating payment intent: $e');
    }
  }

  /// ยืนยันการชำระเงิน
  static Future<PaymentIntent> confirmPayment({
    required String paymentIntentClientSecret,
    PaymentMethodParams? paymentMethodParams,
  }) async {
    try {
      print('🔄 Confirming payment...');
      
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: paymentMethodParams,
      );

      print('✅ Payment confirmed: ${result.id}');
      return result;
    } catch (e) {
      print('❌ Error confirming payment: $e');
      throw Exception('Payment failed: $e');
    }
  }

  /// สร้าง Setup Intent สำหรับบันทึกบัตร
  static Future<Map<String, dynamic>> createSetupIntent({
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔄 Creating setup intent...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/setup_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          if (customerId != null) 'customer': customerId,
          'usage': 'off_session',
          if (metadata != null) 
            ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Setup intent created: ${data['id']}');
        return data;
      } else {
        print('❌ Error creating setup intent: ${response.body}');
        throw Exception('Failed to create setup intent: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in createSetupIntent: $e');
      throw Exception('Error creating setup intent: $e');
    }
  }

  /// สร้าง Customer
  static Future<Map<String, dynamic>> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔄 Creating Stripe customer for: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (metadata != null) 
            ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Customer created: ${data['id']}');
        return data;
      } else {
        print('❌ Error creating customer: ${response.body}');
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in createCustomer: $e');
      throw Exception('Error creating customer: $e');
    }
  }

  /// รับ Payment Intent
  static Future<Map<String, dynamic>> getPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment_intents/$paymentIntentId'),
        headers: {
          'Authorization': 'Bearer $secretKey',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting payment intent: $e');
    }
  }

  /// ยกเลิก Payment Intent
  static Future<Map<String, dynamic>> cancelPaymentIntent(String paymentIntentId) async {
    try {
      print('🔄 Cancelling payment intent: $paymentIntentId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/payment_intents/$paymentIntentId/cancel'),
        headers: {
          'Authorization': 'Bearer $secretKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Payment intent cancelled: ${data['id']}');
        return data;
      } else {
        print('❌ Error cancelling payment intent: ${response.body}');
        throw Exception('Failed to cancel payment intent: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in cancelPaymentIntent: $e');
      throw Exception('Error cancelling payment intent: $e');
    }
  }

  /// สร้าง Refund
  static Future<Map<String, dynamic>> createRefund({
    required String paymentIntentId,
    double? amount,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🔄 Creating refund for payment intent: $paymentIntentId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/refunds'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'payment_intent': paymentIntentId,
          if (amount != null) 'amount': (amount * 100).round().toString(),
          if (reason != null) 'reason': reason,
          if (metadata != null) 
            ...metadata.map((key, value) => MapEntry('metadata[$key]', value.toString())),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Refund created: ${data['id']}');
        return data;
      } else {
        print('❌ Error creating refund: ${response.body}');
        throw Exception('Failed to create refund: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in createRefund: $e');
      throw Exception('Error creating refund: $e');
    }
  }

  /// แปลงสกุลเงินเป็นข้อความ
  static String formatAmount(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'THB':
        return '฿${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return '${amount.toStringAsFixed(2)} ${currency.toUpperCase()}';
    }
  }

  /// เปิด Payment Sheet และประมวลผลการชำระเงิน
  static Future<bool> presentPaymentSheet({
    required String paymentIntentClientSecret,
    required String merchantDisplayName,
  }) async {
    try {
      print('🔄 Presenting payment sheet...');
      
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFFF6B35),
            ),
          ),
        ),
      );

      print('✅ Payment sheet initialized');
      
      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      print('✅ Payment completed successfully');
      return true;
    } on StripeException catch (e) {
      print('❌ Stripe Exception: ${e.error.localizedMessage}');
      if (e.error.code == FailureCode.Canceled) {
        print('⚠️ Payment cancelled by user');
      }
      return false;
    } catch (e) {
      print('❌ Error presenting payment sheet: $e');
      return false;
    }
  }

  /// สร้าง Payment Intent และเปิด Payment Sheet
  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String merchantDisplayName,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: customerId,
        metadata: metadata,
      );

      // Present payment sheet
      final success = await presentPaymentSheet(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        merchantDisplayName: merchantDisplayName,
      );

      return {
        'success': success,
        'paymentIntent': paymentIntent,
      };
    } catch (e) {
      print('❌ Error in processPayment: $e');
      rethrow;
    }
  }
}
