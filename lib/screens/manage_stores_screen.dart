import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageStoresScreen extends StatelessWidget {
  const ManageStoresScreen({super.key});

  // نافذة منبثقة لعرض إحصائيات التاجر المفصلة
  void _showStoreStats(BuildContext context, String storeId, String storeName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إحصائيات: $storeName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: storeId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                
                int totalOrders = snapshot.hasData ? snapshot.data!.docs.length : 0;
                double totalSales = 0;
                int pendingOrders = 0;
                Set<String> uniqueCustomers = {};

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data['status'] == 'مكتمل') totalSales += (data['totalAmount'] ?? 0).toDouble();
                    if (data['status'] == 'قيد المراجعة' || data['status'] == 'جاري التحضير') pendingOrders++;
                    if (data['customerPhone'] != null) uniqueCustomers.add(data['customerPhone']);
                  }
                }

                return Column(
                  children: [
                    ListTile(leading: const Icon(Icons.monetization_on, color: Colors.green), title: const Text('إجمالي المبيعات'), trailing: Text('$totalSales ج', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ListTile(leading: const Icon(Icons.shopping_bag, color: Colors.orange), title: const Text('إجمالي الطلبات'), trailing: Text('$totalOrders', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ListTile(leading: const Icon(Icons.pending_actions, color: Colors.redAccent), title: const Text('طلبات معلقة/جاري تحضيرها'), trailing: Text('$pendingOrders', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    ListTile(leading: const Icon(Icons.people, color: Colors.blue), title: const Text('عدد العملاء المختلفين'), trailing: Text('${uniqueCustomers.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة التجار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.red.shade800, iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stores').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد متاجر'));

          final stores = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              var store = stores[index].data() as Map<String, dynamic>;
              String storeId = stores[index].id;
              bool isActive = store['isActive'] ?? true;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: isActive ? Colors.transparent : Colors.red, width: 2)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: isActive ? Colors.red.shade50 : Colors.grey.shade300, child: Icon(Icons.store, color: isActive ? Colors.red : Colors.grey)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(store['storeName'] ?? 'متجر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, decoration: isActive ? null : TextDecoration.lineThrough)),
                                Text(store['ownerEmail'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isActive ? Colors.green.shade100 : Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text(isActive ? 'نشط' : 'محظور', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.analytics, color: Colors.blue),
                            label: const Text('الإحصائيات'),
                            onPressed: () => _showStoreStats(context, storeId, store['storeName']),
                          ),
                          TextButton.icon(
                            icon: Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.orange : Colors.green),
                            label: Text(isActive ? 'حظر مؤقت' : 'فك الحظر', style: TextStyle(color: isActive ? Colors.orange : Colors.green)),
                            onPressed: () => FirebaseFirestore.instance.collection('stores').doc(storeId).update({'isActive': !isActive}),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            onPressed: () => FirebaseFirestore.instance.collection('stores').doc(storeId).delete(),
                          )
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
    );
  }
}
