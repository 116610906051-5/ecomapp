import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  // Test Cloudinary signature generation
  print('🔐 Cloudinary Signature Generator Test');
  print('=' * 50);
  
  // Test parameters (similar to what the app uses)
  final timestamp = '1760533815'; // ใช้ seconds ไม่ใช่ milliseconds
  final publicId = 'product_test_123';
  final folder = 'products';
  
  // Parameters for signature (ไม่รวม api_key และ file)
  final params = {
    'folder': folder,
    'public_id': publicId,
    'timestamp': timestamp,
  };
  
  // Test with example values
  final testApiSecret = 'your_test_api_secret_here';
  
  // Generate signature
  final signature = generateSignature(params, testApiSecret);
  
  print('📝 Parameters:');
  print('   folder = $folder');
  print('   public_id = $publicId');
  print('   timestamp = $timestamp');
  print('');
  print('🔑 API Secret: $testApiSecret');
  print('');
  print('📋 String to sign: ${createStringToSign(params, testApiSecret)}');
  print('');
  print('🔐 Generated signature: $signature');
  print('');
  print('💡 Instructions:');
  print('1. Replace "your_test_api_secret_here" with your real API secret');
  print('2. The signature should match what Cloudinary expects');
  print('3. If signatures don\'t match, check your Cloud Name and API Secret');
}

String generateSignature(Map<String, dynamic> params, String apiSecret) {
  // เรียงลำดับ keys
  final sortedKeys = params.keys.toList()..sort();
  
  // สร้าง parameter string
  final paramPairs = sortedKeys.map((key) => '$key=${params[key]}').toList();
  final paramString = paramPairs.join('&');
  
  // String to sign
  final stringToSign = paramString + apiSecret;
  
  // สร้าง SHA1 hash
  final bytes = utf8.encode(stringToSign);
  final digest = sha1.convert(bytes);
  
  return digest.toString();
}

String createStringToSign(Map<String, dynamic> params, String apiSecret) {
  final sortedKeys = params.keys.toList()..sort();
  final paramPairs = sortedKeys.map((key) => '$key=${params[key]}').toList();
  final paramString = paramPairs.join('&');
  return paramString + apiSecret;
}
