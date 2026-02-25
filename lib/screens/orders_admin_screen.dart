import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersAdminScreen extends StatefulWidget {
  const OrdersAdminScreen({super.key});

  @override
  State<OrdersAdminScreen> createState() => _OrdersAdminScreenState();
}

class _OrdersAdminScreenState extends State<OrdersAdminScreen> {
  String searchQuery = ''; // متغير لحفظ نص البحث

  void _updateOrderStatus(String orderId, String newStatus) {
    FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  // دالة لتحديد اللون بناءً على حالة الطلب
  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد المراجعة': return Colors.orange;
      case 'جاري التحضير': return Colors.blue;
      case 'في الطريق': return Colors.purple;
      case 'مكتمل': return Colors.green;
      case 'ملغي': return Colors.red;
      default: return Colors.grey;
    }
  }

  // دالة لضبط شكل التاريخ والوقت
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'غير معروف';
    DateTime date = timestamp.toDate();
    String amPm = date.hour >= 12 ? 'م' : 'ص';
    int hour12 = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    String minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} | $hour12:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // شريط البحث الذكي
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'البحث برقم الهاتف أو كود الطلب...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              keyboardType: TextInputType.text,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase(); // تحديث البحث فورياً
                });
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد طلبات حالياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
                }

                // فلترة الطلبات بناءً على نص البحث (رقم الهاتف أو كود الطلب)
                final orders = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String phone = (data['customerPhone'] ?? '').toString();
                  String orderId = doc.id.toLowerCase();
                  return phone.contains(searchQuery) || orderId.contains(searchQuery);
                }).toList();

                if (orders.isEmpty) {
                  return const Center(child: Text('لم يتم العثور على طلبات مطابقة'));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var order = orders[index].data() as Map<String, dynamic>;
                    String orderId = orders[index].id;
                    String shortOrderId = orderId.substring(0, 6).toUpperCase(); // أخذ أول 6 حروف من الكود
                    String currentStatus = order['status'] ?? 'قيد المراجعة';
                    Color statusColor = _getStatusColor(currentStatus); // جلب اللون المناسب للحالة

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      color: statusColor.withOpacity(0.05), // تلوين خلفية الكارت بلون خفيف
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: statusColor, width: 1.5), // حواف الكارت بلون الحالة
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // رأس الكارت: الكود والتاريخ
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blueGrey.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Text('كود: $shortOrderId', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                ),
                                Text(_formatDate(order['createdAt'] as Timestamp?), style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            // بيانات العميل والسعر
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('العميل: ${order['customerName'] ?? 'غير معروف'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                                Text('${order['totalAmount']} ج', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.grey),
                                const SizedBox(width: 5),
                                Text('${order['customerPhone']}'),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 5),
                                Expanded(child: Text('${order['customerAddress']}')),
                              ],
                            ),
                            const Divider(height: 20, thickness: 1),
                            const Text('التفاصيل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 5),
                            ...((order['items'] as List<dynamic>? ?? []).map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text('- ${item['title']}  (الكمية: ${item['quantity']})'),
                              );
                            })),
                            const Divider(height: 20, thickness: 1),
                            
                            // قائمة تغيير الحالة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الحالة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentStatus,
                                      icon: Icon(Icons.arrow_drop_down, color: statusColor),
                                      dropdownColor: Colors.white,
                                      items: ['قيد المراجعة', 'جاري التحضير', 'في الطريق', 'مكتمل', 'ملغي']
                                          .map((status) => DropdownMenuItem(value: status, child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(status)))))
                                          .toList(),
                                      onChanged: (newStatus) {
                                        if (newStatus != null && newStatus != currentStatus) {
                                          _updateOrderStatus(orderId, newStatus);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
