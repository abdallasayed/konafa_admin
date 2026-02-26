import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المنصة (المدير العام)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.red.shade800, // لون مميز للمدير العام
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: Colors.red.shade50,
            child: const Column(
              children: [
                Icon(Icons.admin_panel_settings, size: 60, color: Colors.red),
                SizedBox(height: 10),
                Text('أهلاً بك يا مالك المنصة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                Text('من هنا يمكنك إدارة جميع المتاجر المسجلة', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(alignment: Alignment.centerRight, child: Text('المتاجر المسجلة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stores').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.red));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد متاجر مسجلة حتى الآن'));

                final stores = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    var store = stores[index].data() as Map<String, dynamic>;
                    String storeId = stores[index].id;
                    bool isActive = store['isActive'] ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.red.shade100, child: const Icon(Icons.store, color: Colors.red)),
                        title: Text(store['storeName'] ?? 'متجر غير معروف', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(store['ownerEmail'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () {
                            // دالة حذف المتجر (كمثال مبدئي للتحكم)
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('حذف المتجر؟', style: TextStyle(color: Colors.red)),
                                content: Text('هل أنت متأكد من حذف متجر "${store['storeName']}" نهائياً؟'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                  TextButton(
                                    onPressed: () {
                                      FirebaseFirestore.instance.collection('stores').doc(storeId).delete();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
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
