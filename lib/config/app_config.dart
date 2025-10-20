import 'dart:io';

// Stripe Configuration Class
// ใช้ค่าจาก Environment Variables เท่านั้น
class StripeConfig {
  // อ่านค่าจาก Environment Variables
  static String get publishableKey {
    final key = Platform.environment['STRIPE_PUBLISHABLE_KEY'] ?? 
        'your_stripe_publishable_key_here';
    if (key == 'your_stripe_publishable_key_here') {
      print('⚠️  Warning: Using placeholder Stripe Publishable Key');
    }
    return key;
  }
  
  // Secret Key สำหรับ Development เท่านั้น
  // Production ควรใช้ Backend Server
  static String get secretKey {
    final key = Platform.environment['STRIPE_SECRET_KEY'] ?? 
        'your_stripe_secret_key_here';
    if (key == 'your_stripe_secret_key_here') {
      print('⚠️  Warning: Using placeholder Stripe Secret Key');
    }
    return key;
  }
}

// Cloudinary Configuration
class CloudinaryConfig {
  static String get cloudName {
    final name = Platform.environment['CLOUDINARY_CLOUD_NAME'] ?? 
        'your_cloudinary_cloud_name';
    if (name == 'your_cloudinary_cloud_name') {
      print('⚠️  Warning: Using placeholder Cloudinary Cloud Name');
    }
    return name;
  }
    
  static String get apiKey {
    final key = Platform.environment['CLOUDINARY_API_KEY'] ?? 
        'your_cloudinary_api_key';
    if (key == 'your_cloudinary_api_key') {
      print('⚠️  Warning: Using placeholder Cloudinary API Key');
    }
    return key;
  }
    
  // API Secret สำหรับ Development เท่านั้น
  static String get apiSecret {
    final secret = Platform.environment['CLOUDINARY_API_SECRET'] ?? 
        'your_cloudinary_api_secret';
    if (secret == 'your_cloudinary_api_secret') {
      print('⚠️  Warning: Using placeholder Cloudinary API Secret');
    }
    return secret;
  }
}

// Firebase Configuration
class FirebaseConfig {
  static String get apiKey => 
    Platform.environment['FIREBASE_API_KEY'] ?? 
    'your_firebase_api_key';
    
  static String get projectId => 
    Platform.environment['FIREBASE_PROJECT_ID'] ?? 
    'your_firebase_project_id';
    
  static String get storageBucket => 
    Platform.environment['FIREBASE_STORAGE_BUCKET'] ?? 
    'your_firebase_storage_bucket';
    
  static String get appId => 
    Platform.environment['FIREBASE_APP_ID'] ?? 
    'your_firebase_app_id';
}
