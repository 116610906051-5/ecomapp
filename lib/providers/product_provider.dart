import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String _searchQuery = '';

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get filteredProducts => _filteredProducts;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _filterProducts();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterProducts();
    notifyListeners();
  }

  void setMockProducts(List<Product> mockProducts) {
    _products = mockProducts;
    _featuredProducts = mockProducts.where((p) => p.rating >= 4.5).toList();
    _filterProducts();
    notifyListeners();
  }

  void _filterProducts() {
    _filteredProducts = _products.where((product) {
      bool matchesCategory = _selectedCategory == 'All' || 
                           product.category == _selectedCategory;
      bool matchesSearch = _searchQuery.isEmpty ||
                          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void loadProducts() {
    setLoading(true);
    _productService.getProducts().listen((products) {
      _products = products;
      _filterProducts();
      setLoading(false);
    });
  }

  void loadFeaturedProducts() {
    _productService.getFeaturedProducts().listen((products) {
      _featuredProducts = products;
      notifyListeners();
    });
  }

  Future<Product?> getProductById(String productId) async {
    return await _productService.getProductById(productId);
  }

  Future<void> addSampleProducts() async {
    setLoading(true);
    try {
      await _productService.addSampleProducts();
      loadProducts();
    } catch (e) {
      print('Error adding sample products: $e');
      setLoading(false);
    }
  }

  List<String> get availableCategories {
    Set<String> categories = {'All'};
    for (var product in _products) {
      categories.add(product.category);
    }
    return categories.toList();
  }

  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((product) => product.category == category).toList();
  }

  void sortProducts(String sortBy) {
    switch (sortBy) {
      case 'Price: Low to High':
        _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        _filteredProducts.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Newest':
        _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        // Popular - sort by rating and review count
        _filteredProducts.sort((a, b) {
          final aScore = a.rating * a.reviewCount;
          final bScore = b.rating * b.reviewCount;
          return bScore.compareTo(aScore);
        });
    }
    notifyListeners();
  }
}
