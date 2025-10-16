import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirebaseInitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeSampleData() async {
    try {
      // Delete existing data first to refresh images
      print('Refreshing product data...');
      final productsSnapshot = await _firestore.collection('products').get();
      if (productsSnapshot.docs.isNotEmpty) {
        print('Deleting existing products...');
        final batch = _firestore.batch();
        for (var doc in productsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('Existing products deleted');
      }

      // Sample products data
      final now = DateTime.now();
      final sampleProducts = [
        Product(
          id: 'prod_1',
          name: 'iPhone 15 Pro',
          description: 'Latest iPhone with A17 Pro chip, titanium design, and advanced camera system.',
          price: 35900.0,
          imageUrl: 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400&h=400&fit=crop&crop=center',
          category: 'Electronics',
          colors: ['Natural Titanium', 'Blue Titanium', 'White Titanium', 'Black Titanium'],
          sizes: ['128GB', '256GB', '512GB', '1TB'],
          inStock: true,
          stockQuantity: 50,
          rating: 4.8,
          reviewCount: 2543,
          createdAt: now,
          updatedAt: now,
        ),
        Product(
          id: 'prod_3',
          name: 'Nike Air Max 270',
          description: 'Comfortable running shoes with Max Air cushioning and breathable mesh upper.',
          price: 4500.0,
          imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop&crop=center',
          category: 'Fashion',
          colors: ['Black/White', 'Navy/Blue', 'Red/White', 'All Black'],
          sizes: ['US 7', 'US 8', 'US 9', 'US 10', 'US 11'],
          inStock: true,
          stockQuantity: 100,
          rating: 4.6,
          reviewCount: 892,
          createdAt: now,
          updatedAt: now,
        ),
        Product(
          id: 'prod_5',
          name: 'Adidas Ultraboost 22',
          description: 'Premium running shoes with Boost midsole and Primeknit+ upper.',
          price: 6500.0,
          imageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400&h=400&fit=crop&crop=center',
          category: 'Fashion',
          colors: ['Core Black', 'White/Black', 'Grey/Blue', 'Navy/Orange'],
          sizes: ['US 7', 'US 8', 'US 9', 'US 10', 'US 11', 'US 12'],
          inStock: true,
          stockQuantity: 80,
          rating: 4.7,
          reviewCount: 1205,
          createdAt: now,
          updatedAt: now,
        ),
        Product(
          id: 'prod_6',
          name: 'Sony WH-1000XM5',
          description: 'Industry-leading noise canceling headphones with premium sound quality.',
          price: 13900.0,
          imageUrl: 'https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400&h=400&fit=crop&crop=center',
          category: 'Electronics',
          colors: ['Black', 'Silver'],
          sizes: ['Standard'],
          inStock: true,
          stockQuantity: 30,
          rating: 4.8,
          reviewCount: 3421,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Add products to Firestore
      print('Adding sample products to Firestore...');
      final batch = _firestore.batch();
      
      for (var product in sampleProducts) {
        final docRef = _firestore.collection('products').doc(product.id);
        batch.set(docRef, product.toMap());
      }

      await batch.commit();
      print('Sample data initialized successfully!');
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
}
