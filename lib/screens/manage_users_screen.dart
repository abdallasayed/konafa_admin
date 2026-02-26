import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  void _showUserOrderHistory(BuildContext context, String userPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('سجل طلبات العميل: $userPhone', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('orders').where('customerPhone', isEqualTo: userPhone).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد طلبات مسجلة'));

                    var orders = snapshot.data!.docs.toList();
                    orders.sort((a, b) {
                      Timestamp? tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      Timestamp? tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                      if (tA == null || tB == null) return 0;
                      return tB.compareTo(tA);
                    });

                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (ctx, index) {
                        var order = orders[index].data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            title: Text('الحالة: ${order['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('الإجمالي: ${order['totalAmount']} ج\nالمتجر ID: ${order['storeId']}'),
                            trailing: const Icon(Icons.receipt),
                          ),
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة العملاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.blueGrey.shade800, iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        // جلب العملاء من الطلبات لضمان رؤية كل من تفاعل مع المنصة
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا يوجد عملاء'));

          Map<String, Map<String, dynamic>> allUsers = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String phone = data['customerPhone'] ?? 'غير معروف';
            String name = data['customerName'] ?? 'بدون اسم';
            
            if (!allUsers.containsKey(phone)) {
              allUsers[phone] = {'name': name, 'phone': phone, 'orderCount': 1};
            } else {
              allUsers[phone]!['orderCount']++;
            }
          }

          var usersList = allUsers.values.toList();
          usersList.sort((a, b) => (b['orderCount'] as int).compareTo(a['orderCount'] as int));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              var user = usersList[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blueGrey, child: Icon(Icons.person, color: Colors.white)),
                  title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${user['phone']} \nإجمالي الطلبات بالمنصة: ${user['orderCount']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.history, color: Colors.blue),
                    onPressed: () => _showUserOrderHistory(context, user['phone']),
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
