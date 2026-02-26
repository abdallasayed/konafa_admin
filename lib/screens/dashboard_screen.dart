import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'orders_admin_screen.dart';
import 'menu_admin_screen.dart';
import 'customers_admin_screen.dart';
import 'offers_admin_screen.dart';
import 'categories_admin_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storeId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المتجر', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade800,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // جلب اسم المتجر للترحيب بالتاجر
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('stores').doc(storeId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('مرحباً بك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                String storeName = snapshot.data!['storeName'] ?? 'متجرك';
                return Text('مرحباً بك في إدارة $storeName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey));
              }
            ),
            const SizedBox(height: 15),

            // لوحة الإحصائيات الخاصة بالمتجر
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: storeId).snapshots(),
              builder: (context, snapshot) {
                int totalOrders = 0;
                double totalSales = 0;
                
                if (snapshot.hasData) {
                  totalOrders = snapshot.data!.docs.length;
                  for (var doc in snapshot.data!.docs) {
                    // حساب المبيعات للطلبات المكتملة فقط
                    if (doc['status'] == 'مكتمل') {
                       totalSales += (doc['totalAmount'] ?? 0).toDouble();
                    }
                  }
                }

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.green, size: 30),
                            const Text('إجمالي المبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('$totalSales ج', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          children: [
                            const Icon(Icons.shopping_bag, color: Colors.orange, size: 30),
                            const Text('إجمالي الطلبات', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('$totalOrders', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(context, 'الطلبات', Icons.receipt_long, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersAdminScreen()))),
                  _buildDashboardCard(context, 'الأقسام', Icons.category, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesAdminScreen()))),
                  _buildDashboardCard(context, 'المنتجات', Icons.restaurant_menu, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuAdminScreen()))),
                  _buildDashboardCard(context, 'العروض', Icons.campaign, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OffersAdminScreen()))),
                  _buildDashboardCard(context, 'العملاء', Icons.people, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersAdminScreen()))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(icon, size: 30, color: color)),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
