import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class MyOrdersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.id ?? authProvider.user?.uid ?? '';

    if (userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'คำสั่งซื้อของฉัน',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFF6366F1),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Text('กรุณาเข้าสู่ระบบเพื่อดูคำสั่งซื้อ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'คำสั่งซื้อของฉัน',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: StreamBuilder<List<Order>>(
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
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    // กำหนดสีและไอคอนตามสถานะ
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case OrderStatus.paid:
        statusColor = Colors.blue;
        statusIcon = Icons.payment;
        break;
      case OrderStatus.packing:
        statusColor = Colors.purple;
        statusIcon = Icons.inventory_2;
        break;
      case OrderStatus.processing:
        statusColor = Colors.amber;
        statusIcon = Icons.settings;
        break;
      case OrderStatus.shipped:
        statusColor = Colors.indigo;
        statusIcon = Icons.local_shipping;
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case OrderStatus.refunded:
        statusColor = Colors.grey;
        statusIcon = Icons.money_off;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showOrderDetail(context, order);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อคำสั่งซื้อ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Color(0xFF6366F1), size: 20),
                      SizedBox(width: 8),
                      Text(
                        order.formattedOrderNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          order.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // วันที่สั่งซื้อ
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    dateFormat.format(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // รายการสินค้า (แสดงสินค้าแรก + จำนวนรวม)
              Row(
                children: [
                  if (order.items.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.items.first.productImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.first.productName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (order.items.length > 1)
                          Text(
                            'และอีก ${order.items.length - 1} รายการ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              
              // ราคารวม
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ยอดรวมทั้งหมด',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '฿${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.all(20),
                children: [
                  // Header
                  Text(
                    'รายละเอียดคำสั่งซื้อ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    order.formattedOrderNumber,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Status Progress Timeline
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สถานะคำสั่งซื้อ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildOrderStatusTimeline(order),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // วันที่สั่งซื้อ
                  _buildDetailSection(
                    'วันที่สั่งซื้อ',
                    dateFormat.format(order.createdAt),
                    Icons.calendar_today,
                  ),
                  
                  // ที่อยู่จัดส่ง
                  _buildDetailSection(
                    'ที่อยู่จัดส่ง',
                    '${order.shippingAddress.name}\n'
                    '${order.shippingAddress.phone}\n'
                    '${order.shippingAddress.address}\n'
                    '${order.shippingAddress.district} ${order.shippingAddress.province} ${order.shippingAddress.postalCode}',
                    Icons.location_on,
                  ),
                  
                  // รายการสินค้า
                  SizedBox(height: 20),
                  Text(
                    'รายการสินค้า',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...order.items.map((item) => _buildOrderItem(item)),
                  
                  // สรุปราคา
                  SizedBox(height: 20),
                  Divider(),
                  _buildPriceRow('ราคาสินค้า', order.subtotal),
                  _buildPriceRow('ค่าจัดส่ง', order.shippingFee),
                  Divider(),
                  _buildPriceRow(
                    'ยอดรวมทั้งหมด',
                    order.totalAmount,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Color(0xFF6366F1)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.productImage,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if ((item.selectedColor?.isNotEmpty ?? false) || (item.selectedSize?.isNotEmpty ?? false))
                  Text(
                    '${(item.selectedColor?.isNotEmpty ?? false) ? "สี: ${item.selectedColor}" : ""} '
                    '${(item.selectedSize?.isNotEmpty ?? false) ? "ขนาด: ${item.selectedSize}" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  'x${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '฿${(item.price * item.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            '฿${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Color(0xFF6366F1) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusTimeline(Order order) {
    // Define order status progression
    final statuses = [
      {'status': OrderStatus.pending, 'label': 'รอชำระเงิน', 'icon': Icons.pending},
      {'status': OrderStatus.packing, 'label': 'กำลังแพคสินค้า', 'icon': Icons.inventory_2},
      {'status': OrderStatus.processing, 'label': 'กำลังเตรียมสินค้า', 'icon': Icons.settings},
      {'status': OrderStatus.shipped, 'label': 'กำลังจัดส่งสินค้า', 'icon': Icons.local_shipping},
      {'status': OrderStatus.delivered, 'label': 'สินค้าจัดส่งเรียบร้อย', 'icon': Icons.check_circle},
    ];

    // Find current status index
    int currentStatusIndex = statuses.indexWhere((s) => s['status'] == order.status);
    
    // Handle cancelled and refunded separately
    if (order.status == OrderStatus.cancelled || order.status == OrderStatus.refunded) {
      return Row(
        children: [
          Icon(
            order.status == OrderStatus.cancelled ? Icons.cancel : Icons.money_off,
            color: Colors.red,
            size: 32,
          ),
          SizedBox(width: 12),
          Text(
            order.statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      );
    }

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted ? Color(0xFF6366F1) : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status['icon'] as IconData,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? Color(0xFF6366F1) : Colors.grey[300],
                  ),
              ],
            ),
            SizedBox(width: 16),
            // Status text
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  status['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Color(0xFF1E293B) : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  String _getStatusText(OrderStatus status) {
    // Keep this method for compatibility
    return status.toString().split('.').last;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีคำสั่งซื้อ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เริ่มช้อปปิ้งเพื่อสร้างคำสั่งซื้อแรกของคุณ',
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
