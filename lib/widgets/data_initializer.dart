import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
//import '../models/product.dart';
// import '../services/firebase_init_service.dart'; // ไม่ใช้แล้ว
import 'firestore_instructions_dialog.dart';

class DataInitializer extends StatefulWidget {
  final Widget child;

  const DataInitializer({Key? key, required this.child}) : super(key: key);

  @override
  _DataInitializerState createState() => _DataInitializerState();
}

class _DataInitializerState extends State<DataInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Load only from Firebase database - no mock data
      // _loadMockData(productProvider); // Commented out to show only database products
      
      // Try to load from Firebase
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // ไม่ต้อง initialize sample data - ให้ใช้ข้อมูลที่มีอยู่ใน Firebase แทน
          // await FirebaseInitService.initializeSampleData();
          
          // Load products from Firebase only
          productProvider.loadProducts();
          productProvider.loadFeaturedProducts();
        } catch (e) {
          print('Firebase error (using mock data): $e');
          
          // Show Firestore setup instructions if there's a permission error
          if (e.toString().contains('PERMISSION_DENIED') || 
              e.toString().contains('56')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                FirestoreInstructionsDialog.show(context);
              }
            });
          }
        }
      });

    } catch (e) {
      print('Error initializing data: $e');
    }

    setState(() {
      _isInitialized = true;
    });
  }



  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Color(0xFF6366F1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_bag,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'E-Commerce App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Setting up your shopping experience...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
