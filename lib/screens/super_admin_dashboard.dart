import 'admin_support_screens.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_stores_screen.dart';
import 'manage_users_screen.dart';
import 'admin_support_screens.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المالك العام للمنصة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => FirebaseAuth.instance.signOut())
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15)),
              child: const Column(
                children: [
                  Icon(Icons.admin_panel_settings, size: 60, color: Colors.red),
                  SizedBox(height: 10),
                  Text('مركز السيطرة والتحكم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(context, 'إدارة التجار', Icons.storefront, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageStoresScreen()))),
                  _buildCard(context, 'إدارة العملاء', Icons.people, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen()))),
                  _buildCard(context, 'صندوق الدعم', Icons.support_agent, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSupportListScreen()))),
                  _buildCard(context, 'إعدادات المنصة', Icons.settings, Colors.grey.shade700, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 35, backgroundColor: color.withOpacity(0.2), child: Icon(icon, size: 35, color: color)),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
