import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';

class CloudinaryService {
  // Cloudinary Configuration - อ่านจาก Environment Variables
  static String get _cloudName => CloudinaryConfig.cloudName;
  static String get _apiKey => CloudinaryConfig.apiKey;
  static String get _apiSecret => CloudinaryConfig.apiSecret;
  
  static const String _baseUrl = 'https://api.cloudinary.com/v1_1';
  
  /// สร้าง signature สำหรับ Cloudinary API
  static String _generateSignature(Map<String, dynamic> params, String apiSecret) {
    // สร้างสำเนาของ params และลบ file ออก
    final Map<String, dynamic> paramsToSign = Map<String, dynamic>.from(params);
    paramsToSign.remove('file');
    paramsToSign.remove('api_key'); // ไม่รวม api_key ใน signature
    
    // เรียงลำดับ keys ตามตัวอักษร
    final sortedKeys = paramsToSign.keys.toList()..sort();
    
    // สร้าง parameter string
    final paramPairs = sortedKeys
        .map((key) => '$key=${paramsToSign[key]}')
        .toList();
    
    final paramString = paramPairs.join('&');
    
    // String to sign ต้องมี API secret ต่อท้าย
    final stringToSign = paramString + apiSecret;
    
    print('🔐 String to sign: $stringToSign');
    
    // สร้าง SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);
    
    return digest.toString();
  }

  /// อัพโหลดไฟล์รูปภาพไปยัง Cloudinary
  static Future<String?> uploadImage(File imageFile, {String? fileName}) async {
    // ตรวจสอบการตั้งค่า credentials
    if (_cloudName == 'YOUR_CLOUD_NAME_HERE' || 
        _apiSecret == 'USE_BACKEND_SERVER_FOR_API_SECRET' ||
        _cloudName.isEmpty || _apiSecret.isEmpty) {
      throw Exception('❌ กรุณาตั้งค่า Cloudinary credentials ใน .env file\n'
          '� ดู .env.example สำหรับตัวอย่างการตั้งค่า');
    }
    
    try {
      // สร้างชื่อไฟล์ถ้าไม่ได้ระบุ
      fileName ??= 'product_${DateTime.now().millisecondsSinceEpoch}';
      
      print('🔄 กำลังอัพโหลดรูป: $fileName');

      // Parameters สำหรับ Cloudinary (timestamp ต้องเป็น seconds ไม่ใช่ milliseconds)
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final params = {
        'timestamp': timestamp,
        'public_id': fileName,
        'folder': 'products', // เก็บในโฟลเดอร์ products
      };

      // สร้าง signature
      final signature = _generateSignature(params, _apiSecret);

      // สร้าง multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$_cloudName/image/upload'),
      );
      
      // เพิ่ม parameters
      request.fields.addAll({
        'timestamp': timestamp,
        'public_id': fileName,
        'folder': 'products',
        'api_key': _apiKey,
        'signature': signature,
      });
      
      // เพิ่มไฟล์รูปภาพ
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: path.basename(imageFile.path),
      ));

      // ส่ง request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final publicUrl = data['secure_url'] as String;
        
        print('✅ อัพโหลดสำเร็จ: $publicUrl');
        return publicUrl;
      } else {
        print('❌ HTTP ${response.statusCode}: อัพโหลดล้มเหลว');
        print('Response: ${response.body}');
        
        // แปลง error response เป็น JSON เพื่อแสดงข้อความที่เข้าใจง่าย
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            final errorMsg = errorData['error']['message'] ?? 'Unknown error';
            print('🔍 Error details: $errorMsg');
            
            // ถ้าเป็น signature error ให้แสดงคำแนะนำ
            if (errorMsg.contains('Invalid Signature')) {
              print('💡 คำแนะนำ: ตรวจสอบ Cloud Name และ API Secret ใน cloudinary_service.dart');
            }
          }
        } catch (parseError) {
          print('🔍 Raw error response: ${response.body}');
        }
        
        return null;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัพโหลด: $e');
      return null;
    }
  }

  /// อัพโหลดรูปภาพหลายรูปไปยัง Cloudinary
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];
    
    print('🔄 กำลังอัพโหลด ${imageFiles.length} รูป...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${i + 1}';
      
      print('🔄 กำลังอัพโหลดรูปที่ ${i + 1}/${imageFiles.length}: $fileName');
      
      final url = await uploadImage(file, fileName: fileName);
      if (url != null) {
        uploadedUrls.add(url);
        print('✅ อัพโหลดรูปที่ ${i + 1} สำเร็จ');
      } else {
        print('❌ อัพโหลดรูปที่ ${i + 1} ล้มเหลว');
      }
      
      // รอสักหน่อยระหว่างการอัพโหลดเพื่อไม่ให้ hit rate limit
      if (i < imageFiles.length - 1) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
    
    print('✅ อัพโหลดเสร็จ ${uploadedUrls.length}/${imageFiles.length} รูป');
    return uploadedUrls;
  }

  /// ลบรูปภาพจาก Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      print('🗑️ กำลังลบรูปภาพ: $publicId');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final params = {
        'timestamp': timestamp,
        'public_id': publicId,
      };

      final signature = _generateSignature(params, _apiSecret);

      final response = await http.post(
        Uri.parse('$_baseUrl/$_cloudName/image/destroy'),
        body: {
          'timestamp': timestamp,
          'public_id': publicId,
          'api_key': _apiKey,
          'signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['result'] == 'ok') {
          print('✅ ลบรูปภาพสำเร็จ');
          return true;
        } else {
          print('❌ ลบรูปภาพล้มเหลว: ${data['result']}');
          return false;
        }
      } else {
        print('❌ ลบรูปภาพล้มเหลว: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการลบรูปภาพ: $e');
      return false;
    }
  }

  /// สร้าง optimized URL สำหรับรูปภาพ
  static String optimizeImageUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    try {
      // แยก public_id จาก URL
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 3) return originalUrl;
      
      final cloudName = pathSegments[1];
      final version = pathSegments[2];
      final publicIdWithExtension = pathSegments.skip(3).join('/');
      final publicId = publicIdWithExtension.split('.').first;
      
      // สร้าง transformation parameters
      final transformations = <String>[];
      
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('q_$quality');
      transformations.add('f_$format');
      transformations.add('c_fill'); // crop to fill the dimensions
      
      final transformString = transformations.join(',');
      
      // สร้าง optimized URL
      return 'https://res.cloudinary.com/$cloudName/image/upload/$transformString/$version/$publicId';
    } catch (e) {
      print('❌ ไม่สามารถ optimize URL ได้: $e');
      return originalUrl;
    }
  }

  /// รับขนาดไฟล์ในรูปแบบที่อ่านง่าย
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// ตรวจสอบการตั้งค่า
  static bool get isConfigured {
    return _cloudName != 'YOUR_CLOUD_NAME_HERE' && 
           _apiSecret != 'USE_BACKEND_SERVER_FOR_API_SECRET' &&
           _cloudName.isNotEmpty && _apiSecret.isNotEmpty;
  }

  /// อัพโหลดรูปภาพแชทไปยัง Cloudinary (เก็บในโฟลเดอร์ chat)
  static Future<String?> uploadChatImage(File imageFile, {String? fileName}) async {
    // ตรวจสอบการตั้งค่า credentials
    if (_cloudName == 'YOUR_CLOUD_NAME_HERE' || 
        _apiSecret == 'USE_BACKEND_SERVER_FOR_API_SECRET' ||
        _cloudName.isEmpty || _apiSecret.isEmpty) {
      throw Exception('❌ กรุณาตั้งค่า Cloudinary credentials ใน .env file\n'
          '� ดู .env.example สำหรับตัวอย่างการตั้งค่า');
    }
    
    try {
      // สร้างชื่อไฟล์ถ้าไม่ได้ระบุ
      fileName ??= 'chat_${DateTime.now().millisecondsSinceEpoch}';
      
      print('🔄 กำลังอัพโหลดรูปแชท: $fileName');

      // Parameters สำหรับ Cloudinary (timestamp ต้องเป็น seconds ไม่ใช่ milliseconds)
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final params = {
        'timestamp': timestamp,
        'public_id': fileName,
        'folder': 'chat', // เก็บในโฟลเดอร์ chat แยกจาก products
      };

      // สร้าง signature
      final signature = _generateSignature(params, _apiSecret);

      // สร้าง multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/$_cloudName/image/upload'),
      );
      
      // เพิ่ม parameters
      request.fields.addAll({
        'timestamp': timestamp,
        'public_id': fileName,
        'folder': 'chat',
        'api_key': _apiKey,
        'signature': signature,
      });
      
      // เพิ่มไฟล์รูปภาพ
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: path.basename(imageFile.path),
      ));

      // ส่ง request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final publicUrl = data['secure_url'] as String;
        
        print('✅ อัพโหลดรูปแชทสำเร็จ: $publicUrl');
        return publicUrl;
      } else {
        print('❌ HTTP ${response.statusCode}: อัพโหลดรูปแชทล้มเหลว');
        print('Response: ${response.body}');
        
        // แปลง error response เป็น JSON เพื่อแสดงข้อความที่เข้าใจง่าย
        try {
          final errorData = json.decode(response.body);
          if (errorData['error'] != null) {
            final errorMsg = errorData['error']['message'] ?? 'Unknown error';
            print('🔍 Error details: $errorMsg');
            
            // ถ้าเป็น signature error ให้แสดงคำแนะนำ
            if (errorMsg.contains('Invalid Signature')) {
              print('💡 คำแนะนำ: ตรวจสอบ Cloud Name และ API Secret ใน cloudinary_service.dart');
            }
          }
        } catch (parseError) {
          print('🔍 Raw error response: ${response.body}');
        }
        
        return null;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัพโหลดรูปแชท: $e');
      return null;
    }
  }
}
