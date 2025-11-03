class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl; // รูปหลัก (backward compatibility)
  final List<String> imageUrls; // รูปทั้งหมด (รองรับหลายรูป)
  final String category;
  final double rating;
  final int reviewCount;
  final List<String> colors;
  final List<String> sizes;
  final bool inStock;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Fields for Special Offers
  final bool isOnSale;
  final double? originalPrice;
  final double? discountPercentage;
  final DateTime? saleStartDate;
  final DateTime? saleEndDate;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.imageUrls = const [], // รูปทั้งหมด
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.colors = const [],
    this.sizes = const [],
    this.inStock = true,
    this.stockQuantity = 0,
    required this.createdAt,
    required this.updatedAt,
    
    // Special Offers fields
    this.isOnSale = false,
    this.originalPrice,
    this.discountPercentage,
    this.saleStartDate,
    this.saleEndDate,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? [map['imageUrl'] ?? '']), // รองรับข้อมูลเดิม
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      colors: List<String>.from(map['colors'] ?? []),
      sizes: List<String>.from(map['sizes'] ?? []),
      inStock: map['inStock'] ?? true,
      stockQuantity: map['stockQuantity'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      
      // Special Offers fields
      isOnSale: map['isOnSale'] ?? false,
      originalPrice: map['originalPrice']?.toDouble(),
      discountPercentage: map['discountPercentage']?.toDouble(),
      saleStartDate: map['saleStartDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(map['saleStartDate'])
        : null,
      saleEndDate: map['saleEndDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['saleEndDate'])
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'colors': colors,
      'sizes': sizes,
      'inStock': inStock,
      'stockQuantity': stockQuantity,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      
      // Special Offers fields
      'isOnSale': isOnSale,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'saleStartDate': saleStartDate?.millisecondsSinceEpoch,
      'saleEndDate': saleEndDate?.millisecondsSinceEpoch,
    };
  }
  
  // Helper methods for Special Offers
  bool get isCurrentlyOnSale {
    if (!isOnSale) return false;
    
    final now = DateTime.now();
    
    // Check if sale period is active
    if (saleStartDate != null && now.isBefore(saleStartDate!)) {
      return false;
    }
    
    if (saleEndDate != null && now.isAfter(saleEndDate!)) {
      return false;
    }
    
    return true;
  }
  
  double get currentPrice {
    return isCurrentlyOnSale ? price : (originalPrice ?? price);
  }
  
  double get displayPrice {
    return price;
  }
  
  double get displayOriginalPrice {
    return originalPrice ?? price;
  }
  
  String get discountText {
    if (!isCurrentlyOnSale || discountPercentage == null) {
      return '';
    }
    return '-${discountPercentage!.toInt()}%';
  }
}
