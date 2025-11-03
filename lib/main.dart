import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/product_list_page.dart';
import 'pages/product_detail_page.dart';
import 'pages/cart_page.dart';
import 'pages/profile_page.dart';
import 'services/firebase_config.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/notification_settings_provider.dart';
import 'widgets/data_initializer.dart';
import 'widgets/auth_wrapper.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'debug_login.dart'; // เพิ่มการ import debug page
// import 'services/firebase_init_service.dart'; // ไม่ใช้แล้ว ให้ดึงข้อมูลจาก Firebase
import 'pages/admin_dashboard_page.dart';
import 'pages/contact_us_page.dart';
import 'pages/my_contacts_page.dart';
import 'pages/live_chat_page.dart';
import 'pages/admin_chat_management_page.dart';
import 'pages/personal_information_page.dart';
import 'pages/address_list_page.dart';
import 'pages/my_orders_page.dart';
import 'pages/wishlist_page.dart';
import 'pages/order_history_page.dart';
import 'pages/admin_notification_management_page.dart';
import 'pages/special_offers_page.dart';
import 'pages/admin_special_offers_page.dart';
import 'services/notification_service.dart';
import 'services/advanced_notification_service.dart';
import 'services/navigation_service.dart';
import 'services/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  
  // Initialize Stripe
  try {
    await StripeService.init();
    print('✅ Stripe initialized successfully');
  } catch (e) {
    print('❌ Error initializing Stripe: $e');
  }
  
  // Initialize advanced notification service
  await AdvancedNotificationService.initialize();
  AdvancedNotificationService.onChatNotificationTap = (chatRoomId, fromUserName) {
    print('📱 Navigate to chat: $chatRoomId from $fromUserName');
    NavigationService.navigateToChat(chatRoomId);
  };
  AdvancedNotificationService.onOrderNotificationTap = (orderId, status) {
    print('📱 Navigate to order: $orderId with status $status');
    // TODO: Navigate to order details
  };
  
  // Initialize legacy notification service (for compatibility)
  await NotificationService.initialize();
  NotificationService.onNotificationTap = NavigationService.navigateToChat;
  
  // ลบการเรียก sample data - ให้ใช้ข้อมูลจาก Firebase แทน
  // await FirebaseInitService.initializeSampleData();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
      ],
      child: MaterialApp(
        title: 'E-Commerce App',
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigationService.navigatorKey,
        theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: Color(0xFF6366F1),
        scaffoldBackgroundColor: Color(0xFFF8FAFC),
        fontFamily: 'Inter',
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF475569),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
        home: DataInitializer(child: AuthWrapper()),
        routes: {
          '/home': (context) => HomePage(),
          '/products': (context) => ProductListPage(),
          '/product-detail': (context) => ProductDetailPage(),
          '/cart': (context) => CartPage(),
          '/profile': (context) => ProfilePage(),
          '/login': (context) => LoginPage(),
          '/register': (context) => RegisterPage(),
          '/debug': (context) => DebugLoginPage(), // เพิ่ม debug route
          '/admin': (context) => AdminDashboardPage(), // เพิ่ม admin dashboard route
          '/contact-us': (context) => ContactUsPage(),
          '/my-contacts': (context) => MyContactsPage(),
          '/live-chat': (context) => LiveChatPage(),
          '/admin-chat': (context) => AdminChatManagementPage(),
          '/personal-information': (context) => PersonalInformationPage(),
          '/addresses': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return AddressListPage(
              isSelectionMode: args?['selectionMode'] ?? false,
            );
          },
          '/my-orders': (context) => MyOrdersPage(),
          '/wishlist': (context) => WishlistPage(),
          '/order-history': (context) => OrderHistoryPage(),
          '/admin-notifications': (context) => AdminNotificationManagementPage(), // เพิ่ม route สำหรับจัดการการแจ้งเตือน
          '/special-offers': (context) => SpecialOffersPage(),
          '/admin-special-offers': (context) => AdminSpecialOffersPage(),
        },
      ),
    );
  }
}