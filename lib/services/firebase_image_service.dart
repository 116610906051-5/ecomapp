import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// อัพโหลดรูปภาพเดียวไปยัง Firebase Storage
  static Future<String?> uploadImage(File imageFile) async {
    try {
      print('🔄 กำลังอัพโหลดรูปภาพไปยัง Firebase Storage...');
      
      // สร้างชื่อไฟล์ที่ไม่ซ้ำ
      String fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      // อ้างอิงไฟล์ใน Firebase Storage
      Reference ref = _storage.ref().child('product_images').child(fileName);
      
      // อัพโหลดไฟล์
      UploadTask uploadTask = ref.putFile(imageFile);
      
      // รอให้อัพโหลดเสร็จ
      TaskSnapshot snapshot = await uploadTask;
      
      // รับ URL สำหรับดาวน์โหลด
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ อัพโหลดสำเร็จ: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ อัพโหลดล้มเหลว: $e');
      return null;
    }
  }

  /// อัพโหลดรูปภาพหลายรูปไปยัง Firebase Storage
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> downloadUrls = [];
    
    try {
      print('🔄 กำลังอัพโหลด ${imageFiles.length} รูป...');
      
      for (int i = 0; i < imageFiles.length; i++) {
        File imageFile = imageFiles[i];
        print('🔄 กำลังอัพโหลดรูป ${i + 1}/${imageFiles.length}: ${imageFile.path.split('/').last}');
        
        String? downloadUrl = await uploadImage(imageFile);
        if (downloadUrl != null) {
          downloadUrls.add(downloadUrl);
          print('✅ อัพโหลดรูปที่ ${i + 1} สำเร็จ');
        } else {
          print('❌ อัพโหลดรูปที่ ${i + 1} ล้มเหลว');
        }
      }
      
      print('✅ อัพโหลดเสร็จ ${downloadUrls.length}/${imageFiles.length} รูป');
      return downloadUrls;
      
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการอัพโหลด: $e');
      return downloadUrls;
    }
  }

  /// ลบรูปภาพจาก Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      print('🗑️ กำลังลบรูปภาพ: $imageUrl');
      
      // สร้าง Reference จาก URL
      Reference ref = _storage.refFromURL(imageUrl);
      
      // ลบไฟล์
      await ref.delete();
      
      print('✅ ลบรูปภาพสำเร็จ');
      return true;
      
    } catch (e) {
      print('❌ ลบรูปภาพล้มเหลว: $e');
      return false;
    }
  }

  /// ลบรูปภาพหลายรูปจาก Firebase Storage
  static Future<List<bool>> deleteMultipleImages(List<String> imageUrls) async {
    List<bool> results = [];
    
    try {
      print('🗑️ กำลังลบ ${imageUrls.length} รูป...');
      
      for (int i = 0; i < imageUrls.length; i++) {
        String imageUrl = imageUrls[i];
        print('🗑️ กำลังลบรูปที่ ${i + 1}/${imageUrls.length}');
        
        bool success = await deleteImage(imageUrl);
        results.add(success);
      }
      
      int successCount = results.where((result) => result).length;
      print('✅ ลบเสร็จ ${successCount}/${imageUrls.length} รูป');
      
      return results;
      
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการลบ: $e');
      return results;
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
}
