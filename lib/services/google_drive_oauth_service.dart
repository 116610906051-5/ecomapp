import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart' as parser;

class GoogleDriveOAuthService {
  // ✅ OAuth2 Client ID ที่ตั้งค่าแล้ว
  static const String _clientId = '9476930773-mq0jh63bu4739gdg33jm8mhr7on9ksj1.apps.googleusercontent.com';
  
  // ✅ Folder ID ที่ตั้งค่าแล้ว (จาก Google Drive link)  
  static const String _productImagesFolderId = '1utmu9bohmbfeX5dn-utC7UA5ldZG_zi-';
  
  // OAuth2 Configuration
  static const String _redirectUri = 'urn:ietf:wg:oauth:2.0:oob';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file'
  ];
  
  // URLs
  static const String _authUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const String _tokenUrl = 'https://oauth2.googleapis.com/token';
  static const String _uploadUrl = 'https://www.googleapis.com/upload/drive/v3/files';
  
  // ตัวแปรเก็บ Access Token
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenExpiry;

  /// สร้าง Authorization URL สำหรับผู้ใช้
  static String getAuthorizationUrl() {
    final params = {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': _scopes.join(' '),
      'response_type': 'code',
      'access_type': 'offline',
      'prompt': 'consent',
    };
    
    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$_authUrl?$query';
  }

  /// แลก Authorization Code เป็น Access Token
  static Future<bool> exchangeCodeForToken(String authCode) async {
    try {
      print('🔄 กำลังแลก Authorization Code เป็น Access Token...');
      
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'code': authCode,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        
        // คำนวณเวลาหมดอายุ
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60)); // ลบ 60 วิเพื่อความปลอดภัย
        
        print('✅ ได้ Access Token แล้ว');
        return true;
      } else {
        print('❌ ไม่สามารถได้ Access Token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการแลก token: $e');
      return false;
    }
  }

  /// ต่ออายุ Access Token ด้วย Refresh Token
  static Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      print('❌ ไม่มี Refresh Token');
      return false;
    }

    try {
      print('🔄 กำลังต่ออายุ Access Token...');
      
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'refresh_token': _refreshToken!,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        
        // คำนวณเวลาหมดอายุใหม่
        final expiresIn = data['expires_in'] as int;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        
        print('✅ ต่ออายุ Access Token เสร็จแล้ว');
        return true;
      } else {
        print('❌ ไม่สามารถต่ออายุ token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการต่ออายุ token: $e');
      return false;
    }
  }

  /// ตรวจสอบและต่ออายุ token ถ้าจำเป็น
  static Future<bool> ensureValidToken() async {
    if (_accessToken == null) {
      print('❌ ไม่มี Access Token - ต้อง authorize ก่อน');
      return false;
    }

    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      print('⚠️ Access Token หมดอายุแล้ว - กำลังต่ออายุ...');
      return await refreshAccessToken();
    }

    return true;
  }

  /// อัพโหลดไฟล์รูปภาพไปยัง Google Drive
  static Future<String?> uploadImage(File imageFile, {String? fileName}) async {
    try {
      // ตรวจสอบ token
      if (!await ensureValidToken()) {
        return null;
      }

      // สร้างชื่อไฟล์ถ้าไม่ได้ระบุ
      fileName ??= 'product_${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      
      print('🔄 กำลังอัพโหลดรูป: $fileName');

      // อ่านข้อมูลไฟล์
      final bytes = await imageFile.readAsBytes();

      // เตรียม metadata สำหรับไฟล์
      final metadata = {
        'name': fileName,
        'parents': [_productImagesFolderId],
      };

      // สร้าง multipart request
      final request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?uploadType=multipart'));
      
      // เพิ่ม Authorization header
      request.headers['Authorization'] = 'Bearer $_accessToken';
      
      // เพิ่ม metadata
      request.files.add(http.MultipartFile.fromString(
        'metadata',
        json.encode(metadata),
        contentType: parser.MediaType('application', 'json'),
      ));
      
      // เพิ่มไฟล์รูปภาพ
      request.files.add(http.MultipartFile.fromBytes(
        'media',
        bytes,
        filename: fileName,
        contentType: parser.MediaType('image', path.extension(imageFile.path).substring(1)),
      ));

      // ส่ง request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final fileId = responseData['id'];
        
        // ตั้งค่าให้ไฟล์เป็น public
        await makeFilePublic(fileId);
        
        final publicUrl = 'https://drive.google.com/uc?id=$fileId';
        print('✅ อัพโหลดสำเร็จ: $publicUrl');
        return publicUrl;
      } else {
        print('❌ อัพโหลดล้มเหลว: ${response.statusCode}');
        print('Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัพโหลด: $e');
      return null;
    }
  }

  /// ตั้งค่าให้ไฟล์เป็น public
  static Future<bool> makeFilePublic(String fileId) async {
    try {
      if (!await ensureValidToken()) {
        return false;
      }

      final response = await http.post(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId/permissions'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'role': 'reader',
          'type': 'anyone',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการตั้งค่า public: $e');
      return false;
    }
  }

  /// อัพโหลดรูปภาพหลายรูป
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];
    
    print('🔄 กำลังอัพโหลด ${imageFiles.length} รูป...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${i + 1}.${path.extension(file.path).substring(1)}';
      
      final url = await uploadImage(file, fileName: fileName);
      if (url != null) {
        uploadedUrls.add(url);
        print('✅ อัพโหลดรูปที่ ${i + 1} สำเร็จ');
      } else {
        print('❌ อัพโหลดรูปที่ ${i + 1} ล้มเหลว');
      }
    }
    
    print('✅ อัพโหลดเสร็จ ${uploadedUrls.length}/${imageFiles.length} รูป');
    return uploadedUrls;
  }

  /// ตรวจสอบสถานะการ authorize
  static bool get isAuthorized => _accessToken != null;

  /// ล้าง token (logout)
  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    print('🔄 ล้าง tokens แล้ว');
  }
}
