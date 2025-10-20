import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/coupon.dart';
import '../services/coupon_service.dart';
import 'add_coupon_page.dart';

class AdminCouponManagementPage extends StatefulWidget {
  @override
  _AdminCouponManagementPageState createState() => _AdminCouponManagementPageState();
}

class _AdminCouponManagementPageState extends State<AdminCouponManagementPage> {
  final CouponService _couponService = CouponService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'จัดการโค้ดส่วนลด',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF6366F1),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Coupon>>(
        stream: _couponService.getAllCoupons(),
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

          final coupons = snapshot.data ?? [];

          if (coupons.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              return _buildCouponCard(coupons[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCouponPage()),
          );
        },
        icon: Icon(Icons.add),
        label: Text('สร้างโค้ดใหม่'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.discount_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'ยังไม่มีโค้ดส่วนลด',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'สร้างโค้ดส่วนลดแรกของคุณ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(coupon.status);
    final statusText = _getStatusText(coupon.status);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: coupon.status == CouponStatus.active
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF6366F1)),
                        ),
                        child: Text(
                          coupon.code,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle Switch
                Switch(
                  value: coupon.isActive,
                  onChanged: (value) async {
                    try {
                      await _couponService.toggleCouponStatus(coupon.id, value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? 'เปิดใช้งานแล้ว' : 'ปิดใช้งานแล้ว'),
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
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 12),

            // Description
            Text(
              coupon.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),

            // Discount Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    coupon.discountText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  if (coupon.type == CouponType.percentage && coupon.maxDiscountAmount != null) ...[
                    SizedBox(width: 8),
                    Text(
                      '(สูงสุด ฿${coupon.maxDiscountAmount!.toStringAsFixed(0)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),

            // Details
            _buildDetailRow(
              Icons.shopping_cart,
              'ยอดซื้อขั้นต่ำ',
              coupon.minPurchaseAmount != null
                  ? '฿${coupon.minPurchaseAmount!.toStringAsFixed(0)}'
                  : 'ไม่จำกัด',
            ),
            SizedBox(height: 8),
            _buildDetailRow(
              Icons.calendar_today,
              'วันหมดอายุ',
              dateFormat.format(coupon.expiryDate),
            ),
            SizedBox(height: 8),
            _buildDetailRow(
              Icons.people,
              'การใช้งาน',
              coupon.usageLimit != null
                  ? '${coupon.usageCount}/${coupon.usageLimit}'
                  : '${coupon.usageCount} ครั้ง',
            ),
            SizedBox(height: 16),
            Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCouponPage(coupon: coupon),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('แก้ไข'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _showDeleteDialog(coupon);
                  },
                  icon: Icon(Icons.delete, size: 18),
                  label: Text('ลบ'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(CouponStatus status) {
    switch (status) {
      case CouponStatus.active:
        return Colors.green;
      case CouponStatus.inactive:
        return Colors.grey;
      case CouponStatus.expired:
        return Colors.red;
    }
  }

  String _getStatusText(CouponStatus status) {
    switch (status) {
      case CouponStatus.active:
        return 'ใช้งานได้';
      case CouponStatus.inactive:
        return 'ปิดใช้งาน';
      case CouponStatus.expired:
        return 'หมดอายุ';
    }
  }

  void _showDeleteDialog(Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบโค้ด "${coupon.code}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _couponService.deleteCoupon(coupon.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบโค้ดส่วนลดสำเร็จ'),
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
            },
            child: Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
