import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? authProvider.user?.uid ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'ประวัติการสั่งซื้อ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFF6366F1),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text('กรุณาเข้าสู่ระบบเพื่อดูประวัติการสั่งซื้อ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ประวัติการสั่งซื้อ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: Icon(Icons.shopping_bag),
              text: 'สินค้าที่เคยซื้อ',
            ),
            Tab(
              icon: Icon(Icons.receipt_long),
              text: 'ประวัติคำสั่งซื้อ',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductHistoryTab(userId),
          _buildOrderHistoryTab(userId),
        ],
      ),
    );
  }

  // Tab 1: แสดงสินค้าที่เคยซื้อ
  Widget _buildProductHistoryTab(String userId) {
    return StreamBuilder<List<Order>>(
      stream: OrderService.getUserOrdersStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];
        
        // รวมสินค้าทั้งหมดจากทุกคำสั่งซื้อ
        Map<String, ProductPurchaseInfo> productMap = {};
        
        for (var order in orders) {
          if (order.status == OrderStatus.delivered || 
              order.status == OrderStatus.paid ||
              order.status == OrderStatus.processing ||
              order.status == OrderStatus.shipped) {
            for (var item in order.items) {
              if (productMap.containsKey(item.productId)) {
                productMap[item.productId]!.totalQuantity += item.quantity;
                productMap[item.productId]!.purchaseCount += 1;
                if (order.createdAt.isAfter(productMap[item.productId]!.lastPurchaseDate)) {
                  productMap[item.productId]!.lastPurchaseDate = order.createdAt;
                }
              } else {
                productMap[item.productId] = ProductPurchaseInfo(
                  productId: item.productId,
                  productName: item.productName,
                  productImage: item.productImage,
                  price: item.price,
                  totalQuantity: item.quantity,
                  purchaseCount: 1,
                  lastPurchaseDate: order.createdAt,
                );
              }
            }
          }
        }

        final products = productMap.values.toList()
          ..sort((a, b) => b.lastPurchaseDate.compareTo(a.lastPurchaseDate));

        if (products.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'ยังไม่มีสินค้าที่เคยซื้อ',
            subtitle: 'เริ่มช้อปปิ้งเพื่อสร้างประวัติการซื้อของคุณ',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(products[index]);
          },
        );
      },
    );
  }

  // Tab 2: แสดงประวัติคำสั่งซื้อทั้งหมด
  Widget _buildOrderHistoryTab(String userId) {
    return StreamBuilder<List<Order>>(
      stream: OrderService.getUserOrdersStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'ยังไม่มีประวัติการสั่งซื้อ',
            subtitle: 'ประวัติการสั่งซื้อของคุณจะแสดงที่นี่',
          );
        }

        // จัดกลุ่มตามเดือน
        Map<String, List<Order>> groupedOrders = {};
        for (var order in orders) {
          final monthYear = DateFormat('MM/yyyy').format(order.createdAt);
          if (!groupedOrders.containsKey(monthYear)) {
            groupedOrders[monthYear] = [];
          }
          groupedOrders[monthYear]!.add(order);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: groupedOrders.length,
          itemBuilder: (context, index) {
            final monthYear = groupedOrders.keys.elementAt(index);
            final monthOrders = groupedOrders[monthYear]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    monthYear,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                ...monthOrders.map((order) => _buildOrderSummaryCard(order)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductPurchaseInfo product) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // รูปสินค้า
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.productImage,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            
            // ข้อมูลสินค้า
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    '฿${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'ซื้อแล้ว ${product.purchaseCount} ครั้ง',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '(รวม ${product.totalQuantity} ชิ้น)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'ซื้อล่าสุด ${dateFormat.format(product.lastPurchaseDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ปุ่มซื้ออีกครั้ง
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to product detail
                    Navigator.pushNamed(
                      context,
                      '/product-detail',
                      arguments: product.productId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'ซื้ออีกครั้ง',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    Color statusColor = _getStatusColor(order.status);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 16, color: Color(0xFF6366F1)),
                    SizedBox(width: 4),
                    Text(
                      order.formattedOrderNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              dateFormat.format(order.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${order.items.length} รายการ • ฿${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.shipped:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'รอดำเนินการ';
      case OrderStatus.paid:
        return 'ชำระเงินแล้ว';
      case OrderStatus.processing:
        return 'กำลังจัดเตรียม';
      case OrderStatus.shipped:
        return 'กำลังจัดส่ง';
      case OrderStatus.delivered:
        return 'จัดส่งสำเร็จ';
      case OrderStatus.cancelled:
        return 'ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/products');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366F1),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text('เริ่มช้อปปิ้ง'),
          ),
        ],
      ),
    );
  }
}

// คลาสเก็บข้อมูลสินค้าที่เคยซื้อ
class ProductPurchaseInfo {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  int totalQuantity;
  int purchaseCount;
  DateTime lastPurchaseDate;

  ProductPurchaseInfo({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.totalQuantity,
    required this.purchaseCount,
    required this.lastPurchaseDate,
  });
}
