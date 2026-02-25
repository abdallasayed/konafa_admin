import 'package:flutter/material.dart';
import 'orders_admin_screen.dart';
import 'menu_admin_screen.dart';
import 'customers_admin_screen.dart'; // استدعاء شاشة العملاء
import 'offers_admin_screen.dart';   // استدعاء شاشة العروض

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المدير', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade800,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مرحباً بك في نظام الإدارة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(context, 'الطلبات الجديدة', Icons.receipt_long, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersAdminScreen()));
                  }),
                  _buildDashboardCard(context, 'إدارة المنيو', Icons.restaurant_menu, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuAdminScreen()));
                  }),
                  _buildDashboardCard(context, 'العملاء', Icons.people, Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomersAdminScreen()));
                  }),
                  _buildDashboardCard(context, 'العروض', Icons.campaign, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OffersAdminScreen()));
                  }),
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
