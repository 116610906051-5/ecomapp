import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// ตรวจสอบและขอ permissions
  static Future<bool> _requestPermissions() async {
    try {
      // สำหรับ Android
      if (Platform.isAndroid) {
        // ลองขอทั้งหมดเพื่อให้ได้สิทธิ์
        final List<Permission> permissions = [
          Permission.storage,
          Permission.photos,
          Permission.camera,
        ];
        
        Map<Permission, PermissionStatus> statuses = await permissions.request();
        
        // ตรวจสอบว่าได้รับอย่างน้อยหนึ่งสิทธิ์
        bool hasPermission = statuses.values.any((status) => status.isGranted);
        
        if (hasPermission) {
          print('✅ ได้รับ permission แล้ว');
          return true;
        }
        
        // ถึงไม่ได้ permission ก็ลองให้ทำงานต่อ (บางครั้ง picker ทำงานได้โดยไม่ต้องขอ permission)
        print('⚠️ ไม่ได้รับ permission แต่จะลองทำงานต่อ');
        return true;
      }
      
      // สำหรับ iOS
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      
      return true; // สำหรับ platform อื่นๆ
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการขอ permission: $e');
      // ถึงเกิด error ก็ให้ลองทำงานต่อ
      return true;
    }
  }



  /// เลือกรูปภาพจากแกลเลอรี่ (รูปเดียว)
  static Future<File?> pickImageFromGallery() async {
    try {
      print('📷 กำลังตรวจสอบ permissions สำหรับแกลเลอรี่...');
      
      // ตรวจสอบ permissions ก่อน
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        print('❌ ไม่ได้รับอนุญาตเข้าถึงรูปภาพ');
        return null;
      }
      
      print('✅ ได้รับ permission แล้ว, กำลังเลือกรูป...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('✅ เลือกรูปจากแกลเลอรี่สำเร็จ: ${image.path}');
        return File(image.path);
      } else {
        print('❌ ไม่ได้เลือกรูป');
        return null;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการเลือกรูป: $e');
      return null;
    }
  }

  /// เลือกรูปภาพจากกล้อง
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการถ่ายรูป: $e');
      return null;
    }
  }

  /// เลือกรูปภาพหลายรูปจากแกลเลอรี่
  static Future<List<File>> pickMultipleImages({int? maxImages}) async {
    try {
      print('📱 กำลังตรวจสอบ permissions...');
      
      // ตรวจสอบ permissions ก่อน
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        print('❌ ไม่ได้รับอนุญาตเข้าถึงรูปภาพ');
        return [];
      }
      
      print('✅ ได้รับ permission แล้ว, กำลังเลือกหลายรูป...');
      
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      print('🖼️ เลือกได้ ${images.length} รูป');
      
      // จำกัดจำนวนรูปถ้าระบุ
      final limitedImages = maxImages != null && images.length > maxImages
          ? images.take(maxImages).toList()
          : images;
      
      final files = limitedImages.map((xfile) => File(xfile.path)).toList();
      print('✅ แปลง XFile เป็น File เสร็จแล้ว: ${files.length} ไฟล์');
      
      return files;
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการเลือกหลายรูป: $e');
      return [];
    }
  }

  /// เลือกไฟล์รูปภาพด้วย File Picker (รองรับหลายรูป)
  static Future<List<File>> pickImageFiles({int? maxFiles}) async {
    try {
      print('📂 กำลังเลือกไฟล์รูปภาพ...');
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        print('📁 FilePicker ส่งคืน ${result.files.length} ไฟล์');
        
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
        
        print('🗂️ กรองไฟล์ที่มี path ได้ ${files.length} ไฟล์');
        
        // จำกัดจำนวนไฟล์ถ้าระบุ
        final finalFiles = maxFiles != null && files.length > maxFiles
            ? files.take(maxFiles).toList()
            : files;
            
        print('✅ ไฟล์สุดท้าย: ${finalFiles.length} ไฟล์');
        return finalFiles;
      } else {
        print('❌ ไม่ได้เลือกไฟล์');
        return [];
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการเลือกไฟล์: $e');
      return [];
    }
  }

  /// แสดง Dialog ให้เลือกที่มาของรูปภาพ
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เลือกรูปภาพ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF6366F1)),
                title: Text('เลือกจากแกลเลอรี่'),
                onTap: () async {
                  final file = await pickImageFromGallery();
                  Navigator.of(context).pop(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Color(0xFF6366F1)),
                title: Text('ถ่ายรูปใหม่'),
                onTap: () async {
                  final file = await pickImageFromCamera();
                  Navigator.of(context).pop(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.folder, color: Color(0xFF6366F1)),
                title: Text('เลือกไฟล์'),
                onTap: () async {
                  final files = await pickImageFiles(maxFiles: 1);
                  Navigator.of(context).pop(files.isNotEmpty ? files.first : null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
  }

  /// แสดง Dialog ให้เลือกหลายรูปภาพ
  static Future<List<File>> showMultipleImageSourceDialog(
    BuildContext context, {
    int maxImages = 10,
  }) async {
    final result = await showDialog<List<File>?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เลือกรูปภาพ (สูงสุด $maxImages รูป)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF6366F1)),
                title: Text('เลือกหลายรูปจากแกลเลอรี่'),
                onTap: () async {
                  final files = await pickMultipleImages(maxImages: maxImages);
                  Navigator.of(context).pop(files);
                },
              ),
              ListTile(
                leading: Icon(Icons.folder, color: Color(0xFF6366F1)),
                title: Text('เลือกไฟล์หลายรูป'),
                onTap: () async {
                  final files = await pickImageFiles(maxFiles: maxImages);
                  Navigator.of(context).pop(files);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: Color(0xFF6366F1)),
                title: Text('ถ่ายรูปใหม่'),
                onTap: () async {
                  final file = await pickImageFromCamera();
                  Navigator.of(context).pop(file != null ? [file] : <File>[]);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(<File>[]),
              child: Text('ยกเลิก'),
            ),
          ],
        );
      },
    );
    return result ?? [];
  }

  /// ตรวจสอบว่าไฟล์เป็นรูปภาพหรือไม่
  static bool isImageFile(String filePath) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = filePath.toLowerCase().substring(filePath.lastIndexOf('.'));
    return allowedExtensions.contains(extension);
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
