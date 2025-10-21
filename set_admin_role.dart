import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

/// สคริปต์สำหรับตั้งค่า role เป็น admin ให้กับผู้ใช้
/// รัน: flutter run -t set_admin_role.dart
void main() async {
  print('🚀 กำลังเริ่มต้นระบบ...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('✅ Firebase เริ่มต้นสำเร็จ');
  print('');
  
  // รายชื่อ admin emails ที่ต้องการตั้งค่า
  final adminEmails = [
    'pang@gmail.com',
    'p@p.com',
    'test1@gmail.com',
    'admin@appecom.com',
    'owner@appecom.com',
  ];
  
  final firestore = FirebaseFirestore.instance;
  
  print('📝 กำลังตรวจสอบและอัปเดต role สำหรับผู้ใช้...');
  print('');
  
  for (String email in adminEmails) {
    try {
      // ค้นหาผู้ใช้จาก email
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('⚠️  ไม่พบผู้ใช้: $email');
        continue;
      }
      
      for (var doc in querySnapshot.docs) {
        final currentData = doc.data();
        final currentRole = currentData['role'];
        
        if (currentRole == 'admin') {
          print('✅ $email - มี role เป็น admin อยู่แล้ว');
        } else {
          // อัปเดต role เป็น admin
          await doc.reference.update({'role': 'admin'});
          print('🔄 $email - อัปเดต role เป็น admin สำเร็จ');
        }
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดกับ $email: $e');
    }
  }
  
  print('');
  print('✅ เสร็จสิ้น! กรุณาออกจากระบบและเข้าสู่ระบบใหม่');
  print('');
  
  // แสดงรายชื่อผู้ใช้ทั้งหมดและ role
  print('📋 รายชื่อผู้ใช้ทั้งหมดและ role:');
  final allUsers = await firestore.collection('users').get();
  for (var doc in allUsers.docs) {
    final data = doc.data();
    final email = data['email'] ?? 'ไม่มีอีเมล';
    final role = data['role'] ?? 'customer';
    final name = data['name'] ?? 'ไม่มีชื่อ';
    print('  • $name ($email) - role: $role');
  }
}
