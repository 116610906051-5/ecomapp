enum CouponType {
  percentage, // ลดเปอร์เซ็นต์
  fixedAmount, // ลดเป็นจำนวนเงิน
}

enum CouponStatus {
  active,
  inactive,
  expired,
}

class Coupon {
  final String id;
  final String code; // รหัสส่วนลด (เช่น SALE50)
  final String description; // คำอธิบาย
  final CouponType type; // ประเภทส่วนลด
  final double discountValue; // มูลค่าส่วนลด (% หรือ บาท)
  final double? minPurchaseAmount; // ยอดซื้อขั้นต่ำ
  final double? maxDiscountAmount; // ส่วนลดสูงสุด (สำหรับ percentage)
  final DateTime startDate; // วันเริ่มใช้งาน
  final DateTime expiryDate; // วันหมดอายุ
  final int? usageLimit; // จำนวนครั้งที่ใช้ได้ทั้งหมด
  final int usageCount; // จำนวนครั้งที่ถูกใช้ไปแล้ว
  final bool isActive; // สถานะเปิด/ปิดใช้งาน
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy; // Admin ที่สร้าง

  Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.discountValue,
    this.minPurchaseAmount,
    this.maxDiscountAmount,
    required this.startDate,
    required this.expiryDate,
    this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  // แปลงเป็น Map สำหรับ Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code.toUpperCase(),
      'description': description,
      'type': type.name,
      'discountValue': discountValue,
      'minPurchaseAmount': minPurchaseAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // แปลงจาก Map/Firestore
  factory Coupon.fromMap(Map<String, dynamic> map) {
    return Coupon(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      type: CouponType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CouponType.percentage,
      ),
      discountValue: (map['discountValue'] ?? 0).toDouble(),
      minPurchaseAmount: map['minPurchaseAmount']?.toDouble(),
      maxDiscountAmount: map['maxDiscountAmount']?.toDouble(),
      startDate: DateTime.parse(map['startDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      usageLimit: map['usageLimit'],
      usageCount: map['usageCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // คำนวณส่วนลด
  double calculateDiscount(double orderAmount) {
    if (type == CouponType.percentage) {
      double discount = orderAmount * (discountValue / 100);
      // ถ้ามีส่วนลดสูงสุด
      if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
        return maxDiscountAmount!;
      }
      return discount;
    } else {
      // Fixed amount
      return discountValue;
    }
  }

  // ตรวจสอบว่าใช้ได้หรือไม่
  bool isValid(double orderAmount) {
    final now = DateTime.now();
    
    // ตรวจสอบสถานะ
    if (!isActive) return false;
    
    // ตรวจสอบวันหมดอายุ
    if (now.isBefore(startDate) || now.isAfter(expiryDate)) return false;
    
    // ตรวจสอบยอดซื้อขั้นต่ำ
    if (minPurchaseAmount != null && orderAmount < minPurchaseAmount!) {
      return false;
    }
    
    // ตรวจสอบจำนวนการใช้งาน
    if (usageLimit != null && usageCount >= usageLimit!) {
      return false;
    }
    
    return true;
  }

  // ข้อความอธิบายส่วนลด
  String get discountText {
    if (type == CouponType.percentage) {
      return 'ลด ${discountValue.toStringAsFixed(0)}%';
    } else {
      return 'ลด ฿${discountValue.toStringAsFixed(0)}';
    }
  }

  // สถานะปัจจุบัน
  CouponStatus get status {
    final now = DateTime.now();
    
    if (!isActive) return CouponStatus.inactive;
    if (now.isAfter(expiryDate)) return CouponStatus.expired;
    if (usageLimit != null && usageCount >= usageLimit!) return CouponStatus.expired;
    
    return CouponStatus.active;
  }

  // Copy with
  Coupon copyWith({
    String? id,
    String? code,
    String? description,
    CouponType? type,
    double? discountValue,
    double? minPurchaseAmount,
    double? maxDiscountAmount,
    DateTime? startDate,
    DateTime? expiryDate,
    int? usageLimit,
    int? usageCount,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      type: type ?? this.type,
      discountValue: discountValue ?? this.discountValue,
      minPurchaseAmount: minPurchaseAmount ?? this.minPurchaseAmount,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: this.createdBy,
    );
  }
}
