import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Get all products
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get featured products
  Stream<List<Product>> getFeaturedProducts() {
    return _firestore
        .collection(_collection)
        .where('rating', isGreaterThanOrEqualTo: 4.5)
        .orderBy('rating', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(productId).get();
      if (doc.exists) {
        return Product.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // Add sample products (for initial setup)
  Future<void> addSampleProducts() async {
    final sampleProducts = [
      {
        'name': 'Wireless Bluetooth Headphones',
        'description': 'Premium wireless headphones with active noise cancellation, 30-hour battery life, and crystal-clear sound quality.',
        'price': 99.99,
        'imageUrl': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
        'category': 'Electronics',
        'rating': 4.8,
        'reviewCount': 234,
        'colors': ['Black', 'White', 'Blue'],
        'sizes': ['One Size'],
        'inStock': true,
        'stockQuantity': 50,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Smart Watch Pro',
        'description': 'Advanced smartwatch with health monitoring, GPS tracking, and 7-day battery life.',
        'price': 199.99,
        'imageUrl': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
        'category': 'Electronics',
        'rating': 4.7,
        'reviewCount': 189,
        'colors': ['Black', 'Silver', 'Gold'],
        'sizes': ['38mm', '42mm'],
        'inStock': true,
        'stockQuantity': 30,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Laptop Stand Adjustable',
        'description': 'Ergonomic laptop stand with adjustable height and angle for better posture.',
        'price': 49.99,
        'imageUrl': 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46?w=500',
        'category': 'Home & Garden',
        'rating': 4.9,
        'reviewCount': 156,
        'colors': ['Silver', 'Space Gray'],
        'sizes': ['Standard'],
        'inStock': true,
        'stockQuantity': 75,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Bluetooth Portable Speaker',
        'description': 'Waterproof portable speaker with 360-degree sound and 12-hour battery.',
        'price': 79.99,
        'imageUrl': 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500',
        'category': 'Electronics',
        'rating': 4.6,
        'reviewCount': 98,
        'colors': ['Black', 'Blue', 'Red'],
        'sizes': ['Compact'],
        'inStock': true,
        'stockQuantity': 40,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Premium Phone Case',
        'description': 'Protective phone case with military-grade drop protection and wireless charging support.',
        'price': 19.99,
        'imageUrl': 'https://images.unsplash.com/photo-1556656793-08538906a9f8?w=500',
        'category': 'Electronics',
        'rating': 4.5,
        'reviewCount': 67,
        'colors': ['Clear', 'Black', 'Blue'],
        'sizes': ['iPhone 14', 'iPhone 15', 'Samsung S24'],
        'inStock': true,
        'stockQuantity': 100,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Wireless Charging Pad',
        'description': 'Fast wireless charging pad compatible with all Qi-enabled devices.',
        'price': 39.99,
        'imageUrl': 'https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=500',
        'category': 'Electronics',
        'rating': 4.7,
        'reviewCount': 123,
        'colors': ['White', 'Black'],
        'sizes': ['Standard'],
        'inStock': true,
        'stockQuantity': 60,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (var product in sampleProducts) {
      await _firestore.collection(_collection).add(product);
    }
  }

  // Add single product
  Future<void> addProduct(Product product) async {
    try {
      await _firestore.collection(_collection).add(product.toMap());
      print('Product added successfully: ${product.name}');
    } catch (e) {
      print('Error adding product: $e');
      throw e;
    }
  }

  // Update product
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore.collection(_collection).doc(product.id).update(product.toMap());
      print('Product updated successfully: ${product.name}');
    } catch (e) {
      print('Error updating product: $e');
      throw e;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
      print('Product deleted successfully: $productId');
    } catch (e) {
      print('Error deleting product: $e');
      throw e;
    }
  }
}
