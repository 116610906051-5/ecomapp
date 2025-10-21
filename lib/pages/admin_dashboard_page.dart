import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../models/contact.dart';
import '../models/order.dart';
import '../services/contact_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import 'add_product_page.dart';
import 'edit_product_page.dart';
import 'admin_coupon_management_page.dart';
import 'admin_order_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลสินค้าเมื่อเริ่มต้น
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final firebaseUser = authProvider.user;

    print('🔍 Admin Dashboard - currentUser: ${user?.email}');
    print('🔍 Admin Dashboard - firebaseUser: ${firebaseUser?.email}');

    // ตรวจสอบว่าผู้ใช้เป็น admin หรือไม่ (ตรวจสอบทั้งสองแหล่ง)
    bool isAdmin = false;
    if (user != null && _isAdmin(user.email)) {
      isAdmin = true;
    } else if (firebaseUser != null && _isAdmin(firebaseUser.email ?? '')) {
      isAdmin = true;
    }

    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'คุณไม่มีสิทธิ์เข้าถึงหน้านี้',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366F1),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'กลับหน้าหลัก',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildProductManagement();
      case 2:
        return _buildOrderManagement();
      case 3:
        return _buildAnalytics();
      case 4:
        return _buildAdminManagement();
      case 5:
        return _buildContactManagement();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products;
        final totalProducts = products.length;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สรุปภาพรวม',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 20),
              
              // Stats Cards with Orders
              FutureBuilder<Map<String, dynamic>>(
                future: OrderService.getOrderStatistics(),
                builder: (context, orderStatsSnapshot) {
                  final orderStats = orderStatsSnapshot.data ?? {
                    'totalOrders': 0,
                    'monthOrders': 0,
                    'totalRevenue': 0.0,
                    'monthRevenue': 0.0,
                  };

                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatsCard(
                        'สินค้าทั้งหมด',
                        totalProducts.toString(),
                        Icons.inventory_2_outlined,
                        Color(0xFF3B82F6),
                      ),
                      _buildStatsCard(
                        'คำสั่งซื้อ',
                        orderStats['totalOrders'].toString(),
                        Icons.shopping_cart_outlined,
                        Color(0xFF10B981),
                      ),
                      _buildStatsCard(
                        'ยอดขายรวม',
                        '₿${orderStats['totalRevenue'].toStringAsFixed(0)}',
                        Icons.monetization_on_outlined,
                        Color(0xFF8B5CF6),
                      ),
                      _buildStatsCard(
                        'ออเดอร์เดือนนี้',
                        orderStats['monthOrders'].toString(),
                        Icons.trending_up,
                        Color(0xFFEF4444),
                      ),
                    ],
                  );
                },
              ),
              
              SizedBox(height: 30),
              
              // Recent Orders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'คำสั่งซื้อล่าสุด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    child: Text('ดูทั้งหมด'),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              
              StreamBuilder<List<Order>>(
                stream: OrderService.getAllOrdersStream(limit: 5),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final order = snapshot.data![index];
                        return _buildOrderCard(order);
                      },
                    );
                  } else if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return Container(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'ยังไม่มีคำสั่งซื้อ',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                },
              ),
              
              SizedBox(height: 30),
              
              // Recent Products
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'สินค้าล่าสุด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedIndex = 1),
                    child: Text('ดูทั้งหมด'),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: products.take(3).length, // ลดจาก 5 เป็น 3 เพื่อประหยัดพื้นที่
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductTile(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductManagement() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products;
        
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'จัดการสินค้า',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(
                    width: 140, // จำกัดความกว้างเพื่อป้องกันลายน้ำ
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddProductDialog(),
                      icon: Icon(Icons.add, color: Colors.white, size: 20),
                      label: Flexible(
                        child: Text(
                          'เพิ่มสินค้า', 
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6366F1),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductManagementTile(product);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderManagement() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, color: Color(0xFF6366F1)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'การจัดการคำสั่งซื้อ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminOrderManagementPage(),
                      ),
                    );
                  },
                  icon: Icon(Icons.manage_accounts, size: 18),
                  label: Text('จัดการคำสั่งซื้อทั้งหมด'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Order>>(
            stream: OrderService.getAllOrdersStream(limit: 100),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'เกิดข้อผิดพลาด: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final orders = snapshot.data ?? [];

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'ยังไม่มีคำสั่งซื้อ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'คำสั่งซื้อจะแสดงที่นี่',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(order);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor = _getStatusColor(order.status);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.formattedOrderNumber,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          order.customerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    _formatDateTime(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Spacer(),
                  Text(
                    '₿${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '${order.items.length} รายการ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.blue;
      case OrderStatus.packing:
        return Colors.purple;
      case OrderStatus.processing:
        return Colors.amber;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายละเอียดคำสั่งซื้อ ${order.formattedOrderNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ลูกค้า:', order.customerName),
              _buildDetailRow('อีเมล:', order.customerEmail),
              _buildDetailRow('เบอร์โทร:', order.customerPhone),
              _buildDetailRow('สถานะ:', order.statusText),
              _buildDetailRow('วันที่สั่งซื้อ:', _formatDateTime(order.createdAt)),
              _buildDetailRow('ยอดรวม:', '₿${order.totalAmount.toStringAsFixed(2)}'),
              SizedBox(height: 16),
              Text(
                'ที่อยู่จัดส่ง:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(order.shippingAddress.fullAddress),
              SizedBox(height: 16),
              Text(
                'รายการสินค้า:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ...order.items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${item.productName} x${item.quantity}'),
                    ),
                    Text('₿${(item.price * item.quantity).toStringAsFixed(2)}'),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          if (order.status == OrderStatus.pending) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order, OrderStatus.processing);
              },
              child: Text('ยืนยันคำสั่งซื้อ'),
            ),
          ],
          if (order.status == OrderStatus.processing) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order, OrderStatus.shipped);
              },
              child: Text('จัดส่งแล้ว'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      await OrderService.updateOrderStatus(
        orderId: order.id,
        status: newStatus,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพเดทสถานะคำสั่งซื้อสำเร็จ'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAnalytics() {
    return FutureBuilder<Map<String, dynamic>>(
      future: OrderService.getOrderStatistics(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final orderStats = orderSnapshot.data ?? {
          'totalOrders': 0,
          'monthOrders': 0,
          'totalRevenue': 0.0,
          'monthRevenue': 0.0,
        };

        return Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            final totalProducts = productProvider.products.length;
            final inStockProducts = productProvider.products.where((p) => p.inStock).length;

            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'การวิเคราะห์ข้อมูล',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ข้อมูลสถิติและการวิเคราะห์ธุรกิจ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Sales Analytics
                  _buildAnalyticSection(
                    'สถิติการขาย',
                    Icons.attach_money,
                    Color(0xFF8B5CF6),
                    [
                      _buildAnalyticCard(
                        'ยอดขายทั้งหมด',
                        '₿${orderStats['totalRevenue'].toStringAsFixed(2)}',
                        Icons.monetization_on,
                        Color(0xFF8B5CF6),
                      ),
                      _buildAnalyticCard(
                        'ยอดขายเดือนนี้',
                        '₿${orderStats['monthRevenue'].toStringAsFixed(2)}',
                        Icons.trending_up,
                        Color(0xFF10B981),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Order Analytics
                  _buildAnalyticSection(
                    'สถิติคำสั่งซื้อ',
                    Icons.shopping_cart,
                    Color(0xFF3B82F6),
                    [
                      _buildAnalyticCard(
                        'คำสั่งซื้อทั้งหมด',
                        '${orderStats['totalOrders']}',
                        Icons.receipt_long,
                        Color(0xFF3B82F6),
                      ),
                      _buildAnalyticCard(
                        'คำสั่งซื้อเดือนนี้',
                        '${orderStats['monthOrders']}',
                        Icons.calendar_month,
                        Color(0xFFEF4444),
                      ),
                      _buildAnalyticCard(
                        'ค่าเฉลี่ยต่อออเดอร์',
                        orderStats['totalOrders'] > 0
                            ? '₿${(orderStats['totalRevenue'] / orderStats['totalOrders']).toStringAsFixed(2)}'
                            : '₿0.00',
                        Icons.calculate,
                        Color(0xFFF59E0B),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Product Analytics
                  _buildAnalyticSection(
                    'สถิติสินค้า',
                    Icons.inventory,
                    Color(0xFF10B981),
                    [
                      _buildAnalyticCard(
                        'สินค้าทั้งหมด',
                        '$totalProducts',
                        Icons.inventory_2,
                        Color(0xFF10B981),
                      ),
                      _buildAnalyticCard(
                        'สินค้าพร้อมขาย',
                        '$inStockProducts',
                        Icons.check_circle,
                        Color(0xFF3B82F6),
                      ),
                      _buildAnalyticCard(
                        'สินค้าหมด',
                        '${totalProducts - inStockProducts}',
                        Icons.remove_circle,
                        Color(0xFFEF4444),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Performance Metrics
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'ประสิทธิภาพธุรกิจ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPerformanceMetric(
                                'อัตราการแปลง',
                                '${((inStockProducts / (totalProducts > 0 ? totalProducts : 1)) * 100).toStringAsFixed(1)}%',
                                Icons.timeline,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildPerformanceMetric(
                                'Growth Rate',
                                orderStats['monthOrders'] > 0 ? '+${((orderStats['monthOrders'] / 30) * 100).toStringAsFixed(0)}%' : '0%',
                                Icons.trending_up,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticSection(String title, IconData icon, Color color, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildAnalyticCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ไอคอน
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          // ตัวเลข
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          // ป้ายกำกับ
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image, color: Colors.grey);
                      },
                    )
                  : Icon(Icons.image, color: Colors.grey),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '฿${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.inStock ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.inStock ? 'มีสินค้า' : 'หมด',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductManagementTile(Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image, color: Colors.grey);
                      },
                    )
                  : Icon(Icons.image, color: Colors.grey),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '฿${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                Text(
                  'สต็อก: ${product.stockQuantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showEditProductDialog(product),
                icon: Icon(Icons.edit, color: Color(0xFF6366F1)),
              ),
              IconButton(
                onPressed: () => _confirmDeleteProduct(product),
                icon: Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> getAdminEmails() {
    return [
      'admin@appecom.com',
      'owner@appecom.com', 
      'pang@gmail.com',
    ];
  }

  bool _isAdmin(String email) {
    return getAdminEmails().contains(email.toLowerCase());  
  }

  Widget _buildAdminManagement() {
    final adminEmails = getAdminEmails();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จัดการ Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'รายชื่อผู้ดูแลระบบ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Admin List
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'รายชื่อ Admin ทั้งหมด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${adminEmails.length} คน',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: adminEmails.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final email = adminEmails[index];
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final currentUserEmail = authProvider.currentUser?.email;
                    final firebaseUserEmail = authProvider.user?.email;
                    final isCurrentUser = (currentUserEmail != null && currentUserEmail.toLowerCase() == email.toLowerCase()) || 
                                         (firebaseUserEmail != null && firebaseUserEmail.toLowerCase() == email.toLowerCase());
                    
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
                        child: Text(
                          email[0].toUpperCase(),
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        email,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: Text(
                        _getAdminRole(email),
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrentUser) 
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'คุณ',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.verified_user,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Management Actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'เครื่องมือจัดการ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.discount, color: Colors.orange),
                  ),
                  title: Text(
                    'จัดการโค้ดส่วนลด',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('สร้างและจัดการโค้ดส่วนลดสำหรับลูกค้า'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminCouponManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Admin Permissions Info
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'สิทธิ์ของ Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildPermissionItem('จัดการสินค้า - เพิ่ม แก้ไข ลบสินค้า'),
                _buildPermissionItem('ดูข้อมูล Dashboard และ Analytics'),
                _buildPermissionItem('จัดการคำสั่งซื้อ'),
                _buildPermissionItem('จัดการโค้ดส่วนลด'),
                _buildPermissionItem('เข้าถึงหน้า Admin Dashboard'),
                SizedBox(height: 12),
                Text(
                  '💡 หากต้องการเพิ่ม Admin ใหม่ ให้แจ้งนักพัฒนาเพื่อเพิ่มอีเมลในระบบ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String permission) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Color(0xFF10B981),
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              permission,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAdminRole(String email) {
    switch (email) {
      case 'admin@appecom.com':
        return 'Super Admin';
      case 'owner@appecom.com':
        return 'Owner';
      case 'pang@gmail.com':
        return 'Administrator';
      default:
        return 'Admin';
    }
  }

  void _showAddProductDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(),
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบสินค้า "${product.name}" หรือไม่?\n\nการกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // แสดง loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('กำลังลบสินค้า...'),
                    ],
                  ),
                  duration: Duration(seconds: 5),
                ),
              );

              try {
                // ลบสินค้าจาก Firebase
                await ProductService().deleteProduct(product.id);
                
                // รีเฟรชข้อมูล
                if (mounted) {
                  Provider.of<ProductProvider>(context, listen: false).loadProducts();
                }

                // แสดงข้อความสำเร็จ
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 16),
                        Text('ลบสินค้า "${product.name}" สำเร็จ'),
                      ],
                    ),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Contact Management Section
  Widget _buildContactManagement() {
    return StreamBuilder<List<Contact>>(
      stream: ContactService.getAllContacts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                SizedBox(height: 16),
                Text(
                  'เกิดข้อผิดพลาด',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ไม่สามารถโหลดข้อมูลติดต่อได้',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final contacts = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'การติดต่อจากลูกค้า',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: contacts.where((c) => c.status == ContactStatus.pending).length > 0
                          ? Color(0xFFF59E0B)
                          : Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${contacts.where((c) => c.status == ContactStatus.pending).length} รอดำเนินการ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildContactStatCard(
                      'ทั้งหมด',
                      contacts.length.toString(),
                      Icons.chat_bubble_outline,
                      Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildContactStatCard(
                      'รอดำเนินการ',
                      contacts.where((c) => c.status == ContactStatus.pending).length.toString(),
                      Icons.pending_outlined,
                      Color(0xFFF59E0B),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildContactStatCard(
                      'เสร็จสิ้น',
                      contacts.where((c) => c.status == ContactStatus.resolved).length.toString(),
                      Icons.check_circle_outline,
                      Color(0xFF10B981),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Contact List
              if (contacts.isEmpty)
                Center(
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Icon(
                        Icons.support_agent_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'ยังไม่มีการติดต่อจากลูกค้า',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'เมื่อลูกค้าติดต่อเข้ามา จะแสดงที่นี่',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...contacts.map((contact) => _buildContactCard(contact)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showContactDetail(contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Type Icon
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getContactStatusColor(contact.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      contact.type.icon,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Subject and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.subject,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${contact.name} • ${contact.type.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getContactStatusColor(contact.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      contact.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Message Preview
              Text(
                contact.message,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${contact.email} • ${contact.timeAgo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  if (contact.status == ContactStatus.pending)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _markAsInProgress(contact),
                          child: Text(
                            'รับเรื่อง',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showReplyDialog(contact),
                          child: Text(
                            'ตอบกลับ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getContactStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.pending:
        return Color(0xFFF59E0B);
      case ContactStatus.inProgress:
        return Color(0xFF6366F1);
      case ContactStatus.resolved:
        return Color(0xFF10B981);
      case ContactStatus.closed:
        return Color(0xFF64748B);
    }
  }

  void _showContactDetail(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getContactStatusColor(contact.status).withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getContactStatusColor(contact.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            contact.type.icon,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.subject,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${contact.name} • ${contact.email}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getContactStatusColor(contact.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            contact.statusDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          contact.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ข้อความจากลูกค้า',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              contact.message,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Admin Response
                      if (contact.adminResponse != null) ...[
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.support_agent,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'คำตอบจากทีมงาน',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                contact.adminResponse!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1E293B),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              if (contact.status != ContactStatus.resolved && contact.status != ContactStatus.closed)
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (contact.status == ContactStatus.pending)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _markAsInProgress(contact);
                            },
                            child: Text('รับเรื่อง'),
                          ),
                        ),
                      if (contact.status == ContactStatus.pending)
                        SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showReplyDialog(contact);
                          },
                          child: Text('ตอบกลับ'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsInProgress(Contact contact) async {
    try {
      await ContactService.updateContactStatus(contact.id, ContactStatus.inProgress);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('รับเรื่องเรียบร้อยแล้ว'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReplyDialog(Contact contact) {
    final _replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ตอบกลับลูกค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เรื่อง: ${contact.subject}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('จาก: ${contact.name} (${contact.email})'),
            SizedBox(height: 16),
            TextField(
              controller: _replyController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'คำตอบ',
                border: OutlineInputBorder(),
                hintText: 'พิมพ์คำตอบที่ต้องการส่งให้ลูกค้า...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.trim().isNotEmpty) {
                try {
                  await ContactService.replyToContact(
                    contact.id,
                    _replyController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ส่งคำตอบเรียบร้อยแล้ว'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('ส่งคำตอบ'),
          ),
        ],
      ),
    );
  }

}
