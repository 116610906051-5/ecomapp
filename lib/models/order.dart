class Order {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final ShippingAddress shippingAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? paymentIntentId; // Stripe Payment Intent ID
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.items,
    required this.subtotal,
    this.shippingFee = 0.0,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.paymentMethod = PaymentMethod.creditCard,
    this.paymentIntentId,
    this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  String get formattedOrderNumber => 'ORD${id.substring(0, 8).toUpperCase()}';
  
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'รอการชำระเงิน';
      case OrderStatus.paid:
        return 'ชำระเงินแล้ว';
      case OrderStatus.processing:
        return 'กำลังจัดเตรียม';
      case OrderStatus.shipped:
        return 'จัดส่งแล้ว';
      case OrderStatus.delivered:
        return 'ส่งแล้ว';
      case OrderStatus.cancelled:
        return 'ยกเลิกแล้ว';
      case OrderStatus.refunded:
        return 'คืนเงินแล้ว';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress.toMap(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'paymentIntentId': paymentIntentId,
      'trackingNumber': trackingNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      shippingAddress: ShippingAddress.fromMap(map['shippingAddress'] ?? {}),
      items: (map['items'] as List<dynamic>?)
          ?.map((itemMap) => OrderItem.fromMap(itemMap as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      shippingFee: (map['shippingFee'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.creditCard,
      ),
      paymentIntentId: map['paymentIntentId'],
      trackingNumber: map['trackingNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      shippedAt: map['shippedAt'] != null ? DateTime.parse(map['shippedAt']) : null,
      deliveredAt: map['deliveredAt'] != null ? DateTime.parse(map['deliveredAt']) : null,
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    ShippingAddress? shippingAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingFee,
    double? totalAmount,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    String? paymentIntentId,
    String? trackingNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      selectedColor: map['selectedColor'],
      selectedSize: map['selectedSize'],
    );
  }
}

class ShippingAddress {
  final String name;
  final String phone;
  final String address;
  final String district;
  final String province;
  final String postalCode;
  final String? notes;

  ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.district,
    required this.province,
    required this.postalCode,
    this.notes,
  });

  String get fullAddress => '$address $district $province $postalCode';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'district': district,
      'province': province,
      'postalCode': postalCode,
      'notes': notes,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      district: map['district'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postalCode'] ?? '',
      notes: map['notes'],
    );
  }
}

enum OrderStatus {
  pending,
  paid,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

enum PaymentMethod {
  creditCard,
  bankTransfer,
  cod, // Cash on Delivery
}
