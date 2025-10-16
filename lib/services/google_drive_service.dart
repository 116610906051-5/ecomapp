import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart' as parser;

class GoogleDriveService {
  // Google Drive API สำหรับอัพโหลดไฟล์
  static const String _apiKey = 'AIzaSyBqjpapQ7wfraY2tLj09R6f7ych3riVPmc'; // API Key จริง
  static const String _uploadUrl = 'https://www.googleapis.com/upload/drive/v3/files';
  
  // ID ของโฟลเดอร์ใน Google Drive ที่ต้องการเก็บรูป
  static const String _productImagesFolderId = '1utmu9bohmbfeX5dn-utC7UA5ldZG_zi-'; // Folder ID จริง

  /// อัพโหลดไฟล์รูปภาพไปยัง Google Drive
  static Future<String?> uploadImage(File imageFile, {String? fileName}) async {
    try {
      // สร้างชื่อไฟล์ถ้าไม่ได้ระบุ
      fileName ??= '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      
      print('🔄 กำลังอัพโหลดรูป: $fileName');

      // อ่านข้อมูลไฟล์
      final bytes = await imageFile.readAsBytes();

      // เตรียม metadata สำหรับไฟล์
      final metadata = {
        'name': fileName,
        'parents': [_productImagesFolderId], // ใส่ไฟล์ในโฟลเดอร์ที่กำหนด
      };

      // สร้าง multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_uploadUrl?uploadType=multipart&key=$_apiKey'),
      );

      // เพิ่ม metadata
      request.files.add(
        http.MultipartFile.fromString(
          'metadata',
          jsonEncode(metadata),
          contentType: parser.MediaType.parse('application/json; charset=UTF-8'),
        ),
      );

      // เพิ่มไฟล์รูป
      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          bytes,
          filename: fileName,
          contentType: parser.MediaType.parse(_getContentType(imageFile.path)),
        ),
      );

      // ส่ง request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(responseBody);
        final fileId = responseJson['id'];
        
        // ตั้งค่าให้ไฟล์เป็น public เพื่อให้เข้าถึงได้
        await _makeFilePublic(fileId);
        
        // สร้าง public URL
        final publicUrl = 'https://drive.google.com/uc?id=$fileId';
        
        print('✅ อัพโหลดสำเร็จ: $publicUrl');
        return publicUrl;
      } else {
        print('❌ อัพโหลดล้มเหลว: ${response.statusCode}');
        print('Error: $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัพโหลด: $e');
      return null;
    }
  }

  /// อัพโหลดหลายรูปพร้อมกัน
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String> uploadedUrls = [];
    
    print('🔄 กำลังอัพโหลด ${imageFiles.length} รูป...');
    
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${i + 1}${path.extension(file.path)}';
      
      final url = await uploadImage(file, fileName: fileName);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    print('✅ อัพโหลดเสร็จ ${uploadedUrls.length}/${imageFiles.length} รูป');
    return uploadedUrls;
  }

  /// ตั้งค่าให้ไฟล์เป็น public
  static Future<bool> _makeFilePublic(String fileId) async {
    try {
      final url = 'https://www.googleapis.com/drive/v3/files/$fileId/permissions?key=$_apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'role': 'reader',
          'type': 'anyone',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ ไม่สามารถตั้งค่าไฟล์เป็น public: $e');
      return false;
    }
  }

  /// กำหนด Content-Type ตามนามสกุลไฟล์
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// ลบไฟล์จาก Google Drive
  static Future<bool> deleteFile(String fileId) async {
    try {
      final url = 'https://www.googleapis.com/drive/v3/files/$fileId?key=$_apiKey';
      
      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ ไม่สามารถลบไฟล์: $e');
      return false;
    }
  }

  /// แปลง Google Drive URL เป็น File ID
  static String? extractFileIdFromUrl(String url) {
    final regex = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }
}
