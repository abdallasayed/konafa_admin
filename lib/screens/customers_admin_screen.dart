import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomersAdminScreen extends StatelessWidget {
  const CustomersAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عملاء متجري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // نجلب الطلبات الخاصة بهذا المتجر فقط
        stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: storeId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لم يقم أحد بالطلب من متجرك حتى الآن'));

          // تجميع بيانات العملاء من الطلبات
          Map<String, Map<String, dynamic>> customersMap = {};
          
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String phone = data['customerPhone'] ?? 'غير معروف';
            String name = data['customerName'] ?? 'بدون اسم';
            double amount = (data['totalAmount'] ?? 0).toDouble();
            bool isCompleted = data['status'] == 'مكتمل';

            if (customersMap.containsKey(phone)) {
              customersMap[phone]!['orderCount'] += 1;
              if (isCompleted) customersMap[phone]!['totalSpent'] += amount;
            } else {
              customersMap[phone] = {
                'name': name,
                'phone': phone,
                'orderCount': 1,
                'totalSpent': isCompleted ? amount : 0.0,
              };
            }
          }

          var customerList = customersMap.values.toList();
          // ترتيب العملاء حسب الأكثر طلباً
          customerList.sort((a, b) => (b['orderCount'] as int).compareTo(a['orderCount'] as int));

          return ListView.builder(
            itemCount: customerList.length,
            itemBuilder: (context, index) {
              var customer = customerList[index];
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 5), Text(customer['phone'])]),
                      const SizedBox(height: 5),
                      Text('عدد الطلبات: ${customer['orderCount']} | إجمالي المدفوعات: ${customer['totalSpent']} ج', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
