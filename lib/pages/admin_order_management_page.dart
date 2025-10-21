import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as OrderModel;
import '../services/order_service.dart';

/// Admin Order Management Page
/// 
/// Note: Currently using client-side filtering for status while Firebase 
/// composite indexes are being built. Once indexes are ready (usually takes 
/// a few minutes), the query will be more efficient.
class AdminOrderManagementPage extends StatefulWidget {
  @override
  _AdminOrderManagementPageState createState() => _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'จัดการคำสั่งซื้อ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ทั้งหมด', 'all'),
                  SizedBox(width: 8),
                  _buildFilterChip('รอชำระเงิน', 'pending'),
                  SizedBox(width: 8),
                  _buildFilterChip('กำลังแพคสินค้า', 'packing'),
                  SizedBox(width: 8),
                  _buildFilterChip('กำลังเตรียมสินค้า', 'processing'),
                  SizedBox(width: 8),
                  _buildFilterChip('กำลังจัดส่ง', 'shipped'),
                  SizedBox(width: 8),
                  _buildFilterChip('จัดส่งแล้ว', 'delivered'),
                ],
              ),
            ),
          ),
          
          // Orders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var orders = snapshot.data?.docs ?? [];

                // Client-side filtering until indexes are built
                if (_selectedStatusFilter != 'all') {
                  orders = orders.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == _selectedStatusFilter;
                  }).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _selectedStatusFilter == 'all' 
                            ? 'ไม่มีคำสั่งซื้อ'
                            : 'ไม่มีคำสั่งซื้อในสถานะนี้',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderData = orders[index].data() as Map<String, dynamic>;
                    orderData['id'] = orders[index].id;
                    final order = OrderModel.Order.fromMap(orderData);
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    // For now, fetch all orders and filter client-side until indexes are built
    // Once indexes are ready, this will work without issues
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);

    // Remove the where clause temporarily - we'll filter client-side instead
    // if (_selectedStatusFilter != 'all') {
    //   query = query.where('status', isEqualTo: _selectedStatusFilter);
    // }

    return query.snapshots();
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = value;
        });
      },
      selectedColor: Color(0xFF6366F1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Color(0xFF64748B),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? Color(0xFF6366F1) : Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel.Order order) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetailDialog(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
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
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(order.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              
              // Customer Info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Text(
                    order.customerPhone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Order Items Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} รายการ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
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
              
              SizedBox(height: 12),
              
              // Update Status Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusDialog(order),
                  icon: Icon(Icons.update, size: 18),
                  label: Text('อัพเดทสถานะ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderModel.OrderStatus status) {
    switch (status) {
      case OrderModel.OrderStatus.pending:
        return Colors.orange;
      case OrderModel.OrderStatus.paid:
        return Colors.blue;
      case OrderModel.OrderStatus.packing:
        return Colors.purple;
      case OrderModel.OrderStatus.processing:
        return Colors.amber;
      case OrderModel.OrderStatus.shipped:
        return Colors.indigo;
      case OrderModel.OrderStatus.delivered:
        return Colors.green;
      case OrderModel.OrderStatus.cancelled:
        return Colors.red;
      case OrderModel.OrderStatus.refunded:
        return Colors.grey;
    }
  }

  void _showOrderDetailDialog(OrderModel.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text('รายละเอียดคำสั่งซื้อ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'เลขที่: ${order.formattedOrderNumber}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('ลูกค้า: ${order.customerName}'),
              Text('เบอร์โทร: ${order.customerPhone}'),
              Text('อีเมล: ${order.customerEmail}'),
              SizedBox(height: 12),
              Text(
                'ที่อยู่จัดส่ง:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(order.shippingAddress.fullAddress),
              SizedBox(height: 12),
              Text(
                'รายการสินค้า:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('${item.productName} x${item.quantity} - ฿${(item.price * item.quantity).toStringAsFixed(2)}'),
              )),
              Divider(),
              Text(
                'ยอดรวม: ฿${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(OrderModel.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('อัพเดทสถานะคำสั่งซื้อ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'เลือกสถานะใหม่สำหรับ ${order.formattedOrderNumber}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            _buildStatusOption(order, OrderModel.OrderStatus.packing, 'กำลังแพคสินค้า'),
            _buildStatusOption(order, OrderModel.OrderStatus.processing, 'กำลังเตรียมสินค้า'),
            _buildStatusOption(order, OrderModel.OrderStatus.shipped, 'กำลังจัดส่งสินค้า'),
            _buildStatusOption(order, OrderModel.OrderStatus.delivered, 'สินค้าจัดส่งเรียบร้อย'),
            _buildStatusOption(order, OrderModel.OrderStatus.cancelled, 'ยกเลิกคำสั่งซื้อ'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(OrderModel.Order order, OrderModel.OrderStatus newStatus, String label) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          await _updateOrderStatus(order, newStatus);
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(newStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(newStatus),
                  color: _getStatusColor(newStatus),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(OrderModel.OrderStatus status) {
    switch (status) {
      case OrderModel.OrderStatus.packing:
        return Icons.inventory_2;
      case OrderModel.OrderStatus.processing:
        return Icons.settings;
      case OrderModel.OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderModel.OrderStatus.delivered:
        return Icons.check_circle;
      case OrderModel.OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _updateOrderStatus(OrderModel.Order order, OrderModel.OrderStatus newStatus) async {
    try {
      await OrderService.updateOrderStatus(
        orderId: order.id,
        status: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัพเดทสถานะเรียบร้อยแล้ว'),
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
}
