import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ----------------- الشاشة الأولى: قائمة المتاجر -----------------
class AdminSupportListScreen extends StatelessWidget {
  const AdminSupportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('صندوق الدعم الفني', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.purple.shade700, iconTheme: const IconThemeData(color: Colors.white)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stores').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد متاجر للتواصل معها'));

          final stores = snapshot.data!.docs;

          return ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              var store = stores[index].data() as Map<String, dynamic>;
              String storeId = stores[index].id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.support_agent, color: Colors.white)),
                  title: Text(store['storeName'] ?? 'متجر', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('اضغط لفتح المحادثة'),
                  trailing: const Icon(Icons.chat, color: Colors.purple),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(storeId: storeId, storeName: store['storeName'] ?? 'متجر')));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- الشاشة الثانية: المحادثة مع التاجر -----------------
class AdminChatScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  const AdminChatScreen({super.key, required this.storeId, required this.storeName});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    
    await FirebaseFirestore.instance.collection('support_messages').add({
      'storeId': widget.storeId,
      'storeName': widget.storeName,
      'text': _msgController.text.trim(),
      'sender': 'super_admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('محادثة: ${widget.storeName}', style: const TextStyle(color: Colors.white, fontSize: 16)), backgroundColor: Colors.purple.shade700, iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // إزالة orderBy
              stream: FirebaseFirestore.instance.collection('support_messages').where('storeId', isEqualTo: widget.storeId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد رسائل بينك وبين هذا المتجر'));

                // الترتيب المحلي
                var messages = snapshot.data!.docs.toList();
                messages.sort((a, b) {
                  Timestamp? tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  Timestamp? tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index].data() as Map<String, dynamic>;
                    bool isAdmin = msg['sender'] == 'super_admin';

                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.red.shade100 : Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isAdmin ? const Radius.circular(15) : Radius.zero,
                            bottomRight: isAdmin ? Radius.zero : const Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAdmin ? 'أنا (الإدارة)' : widget.storeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isAdmin ? Colors.red : Colors.blueGrey)),
                            const SizedBox(height: 5),
                            Text(msg['text'] ?? '', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(hintText: 'اكتب ردك للتاجر...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(25))),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.purple.shade700,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
