import 'dart:io';
import 'app_secrets.dart';

// Stripe Configuration Class
// ใช้ค่าจาก app_secrets.dart หรือ Environment Variables
class StripeConfig {
  // อ่านค่าจาก Environment Variables หรือใช้ค่าจาก AppSecrets
  static String get publishableKey {
    final key = Platform.environment['STRIPE_PUBLISHABLE_KEY'] ?? 
        AppSecrets.stripePublishableKey;
    return key;
  }
  
  // Secret Key สำหรับ Development เท่านั้น
  // Production ควรใช้ Backend Server
  static String get secretKey {
    final key = Platform.environment['STRIPE_SECRET_KEY'] ?? 
        AppSecrets.stripeSecretKey;
    return key;
  }
}

// Cloudinary Configuration
class CloudinaryConfig {
  static String get cloudName {
    return Platform.environment['CLOUDINARY_CLOUD_NAME'] ?? 
        AppSecrets.cloudinaryCloudName;
  }
    
  static String get apiKey {
    return Platform.environment['CLOUDINARY_API_KEY'] ?? 
        AppSecrets.cloudinaryApiKey;
  }
    
  // API Secret สำหรับ Development เท่านั้น
  static String get apiSecret {
    return Platform.environment['CLOUDINARY_API_SECRET'] ?? 
        AppSecrets.cloudinaryApiSecret;
  }
}

// Firebase Configuration
class FirebaseConfig {
  static String get apiKey => 
    Platform.environment['FIREBASE_API_KEY'] ?? 
    AppSecrets.firebaseApiKey;
    
  static String get projectId => 
    Platform.environment['FIREBASE_PROJECT_ID'] ?? 
    AppSecrets.firebaseProjectId;
    
  static String get storageBucket => 
    Platform.environment['FIREBASE_STORAGE_BUCKET'] ?? 
    AppSecrets.firebaseStorageBucket;
    
  static String get appId => 
    Platform.environment['FIREBASE_APP_ID'] ?? 
    AppSecrets.firebaseAppId;
}
