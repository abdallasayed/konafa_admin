import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OffersAdminScreen extends StatefulWidget {
  const OffersAdminScreen({super.key});

  @override
  State<OffersAdminScreen> createState() => _OffersAdminScreenState();
}

class _OffersAdminScreenState extends State<OffersAdminScreen> {
  
  void _showAddOfferSheet() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    
    // جلب بيانات المتجر لحفظ اسمه مع العرض
    final storeId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot storeDoc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
    String storeName = storeDoc['storeName'] ?? 'متجر';

    if(!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إضافة عرض لمتجرك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 15),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان العرض (مثال: خصم 20%)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'تفاصيل العرض', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  if (titleController.text.isEmpty || descController.text.isEmpty) return;
                  FirebaseFirestore.instance.collection('offers').add({
                    'title': titleController.text,
                    'description': descController.text,
                    'storeId': storeId, // ربط العرض بالمتجر
                    'storeName': storeName, // حفظ اسم المتجر للعرض للعملاء
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('نشر العرض', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('عروض متجري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOfferSheet,
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('عرض جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // عزل العروض: جلب عروض هذا المتجر فقط
        stream: FirebaseFirestore.instance.collection('offers').where('storeId', isEqualTo: storeId).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد عروض لمتجرك حالياً'));

          final offers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              var offer = offers[index].data() as Map<String, dynamic>;
              String offerId = offers[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: Colors.purpleAccent, child: Icon(Icons.local_offer, color: Colors.white)),
                  title: Text(offer['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(offer['description'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('offers').doc(offerId).delete(),
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
