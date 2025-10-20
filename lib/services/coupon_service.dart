import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';

class CouponService {
  final CollectionReference _couponsRef = FirebaseFirestore.instance.collection('coupons');

  // สร้าง Coupon ใหม่
  Future<String> createCoupon(Coupon coupon) async {
    try {
      // ตรวจสอบว่า code ซ้ำหรือไม่
      final existingCoupon = await getCouponByCode(coupon.code);
      if (existingCoupon != null) {
        throw Exception('รหัสส่วนลดนี้มีอยู่แล้ว');
      }

      // สร้าง document reference ใหม่เพื่อให้ได้ ID
      final docRef = _couponsRef.doc();
      final newCoupon = coupon.copyWith(id: docRef.id);
      
      await docRef.set(newCoupon.toMap());
      print('✅ Coupon created: ${newCoupon.code} (ID: ${docRef.id})');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating coupon: $e');
      rethrow;
    }
  }

  // อัปเดต Coupon
  Future<void> updateCoupon(Coupon coupon) async {
    try {
      await _couponsRef.doc(coupon.id).update(
        coupon.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      print('✅ Coupon updated: ${coupon.code}');
    } catch (e) {
      print('❌ Error updating coupon: $e');
      rethrow;
    }
  }

  // ลบ Coupon
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _couponsRef.doc(couponId).delete();
      print('✅ Coupon deleted: $couponId');
    } catch (e) {
      print('❌ Error deleting coupon: $e');
      rethrow;
    }
  }

  // ดึง Coupon ตาม ID
  Future<Coupon?> getCouponById(String couponId) async {
    try {
      final doc = await _couponsRef.doc(couponId).get();
      if (doc.exists) {
        return Coupon.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting coupon: $e');
      return null;
    }
  }

  // ดึง Coupon ตาม Code
  Future<Coupon?> getCouponByCode(String code) async {
    try {
      final querySnapshot = await _couponsRef
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Coupon.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error getting coupon by code: $e');
      return null;
    }
  }

  // ตรวจสอบและใช้ Coupon
  Future<Map<String, dynamic>> validateAndUseCoupon({
    required String code,
    required double orderAmount,
  }) async {
    try {
      final coupon = await getCouponByCode(code);

      if (coupon == null) {
        return {
          'success': false,
          'message': 'ไม่พบรหัสส่วนลดนี้',
        };
      }

      // ตรวจสอบความถูกต้อง
      if (!coupon.isValid(orderAmount)) {
        String message = 'รหัสส่วนลดนี้ไม่สามารถใช้งานได้';
        
        if (!coupon.isActive) {
          message = 'รหัสส่วนลดนี้ถูกปิดใช้งานแล้ว';
        } else if (DateTime.now().isBefore(coupon.startDate)) {
          message = 'รหัสส่วนลดนี้ยังไม่เริ่มใช้งาน';
        } else if (DateTime.now().isAfter(coupon.expiryDate)) {
          message = 'รหัสส่วนลดนี้หมดอายุแล้ว';
        } else if (coupon.minPurchaseAmount != null && 
                   orderAmount < coupon.minPurchaseAmount!) {
          message = 'ยอดซื้อขั้นต่ำ ฿${coupon.minPurchaseAmount!.toStringAsFixed(0)}';
        } else if (coupon.usageLimit != null && 
                   coupon.usageCount >= coupon.usageLimit!) {
          message = 'รหัสส่วนลดนี้ถูกใช้งานครบแล้ว';
        }

        return {
          'success': false,
          'message': message,
        };
      }

      // คำนวณส่วนลด
      final discountAmount = coupon.calculateDiscount(orderAmount);

      return {
        'success': true,
        'message': 'ใช้รหัสส่วนลดสำเร็จ',
        'coupon': coupon,
        'discountAmount': discountAmount,
      };
    } catch (e) {
      print('❌ Error validating coupon: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาด: $e',
      };
    }
  }

  // เพิ่มจำนวนการใช้งาน
  Future<void> incrementUsageCount(String couponId) async {
    try {
      await _couponsRef.doc(couponId).update({
        'usageCount': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Coupon usage count incremented: $couponId');
    } catch (e) {
      print('❌ Error incrementing usage count: $e');
      rethrow;
    }
  }

  // ดึง Coupons ทั้งหมด (สำหรับ Admin)
  Stream<List<Coupon>> getAllCoupons() {
    return _couponsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final coupons = snapshot.docs
              .map((doc) => Coupon.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          // Sort in memory by status and date
          coupons.sort((a, b) {
            // Active coupons first
            if (a.status == CouponStatus.active && b.status != CouponStatus.active) return -1;
            if (a.status != CouponStatus.active && b.status == CouponStatus.active) return 1;
            
            // Then by expiry date
            return b.expiryDate.compareTo(a.expiryDate);
          });
          
          return coupons;
        });
  }

  // ดึง Active Coupons (สำหรับผู้ใช้)
  Stream<List<Coupon>> getActiveCoupons() {
    final now = DateTime.now();
    
    return _couponsRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final coupons = snapshot.docs
              .map((doc) => Coupon.fromMap(doc.data() as Map<String, dynamic>))
              .where((coupon) => 
                now.isAfter(coupon.startDate) && 
                now.isBefore(coupon.expiryDate))
              .toList();
          
          // Sort by expiry date
          coupons.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          
          return coupons;
        });
  }

  // Toggle Active Status
  Future<void> toggleCouponStatus(String couponId, bool isActive) async {
    try {
      await _couponsRef.doc(couponId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Coupon status toggled: $couponId -> $isActive');
    } catch (e) {
      print('❌ Error toggling coupon status: $e');
      rethrow;
    }
  }
}
