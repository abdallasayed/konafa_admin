import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreSupportScreen extends StatefulWidget {
  const StoreSupportScreen({super.key});

  @override
  State<StoreSupportScreen> createState() => _StoreSupportScreenState();
}

class _StoreSupportScreenState extends State<StoreSupportScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String storeId = FirebaseAuth.instance.currentUser!.uid;
  String storeName = 'متجري';

  @override
  void initState() {
    super.initState();
    _getStoreName();
    _markMessagesAsRead();
  }

  // تحويل رسائل المدير إلى "مقروءة" بمجرد فتح الشاشة
  void _markMessagesAsRead() async {
    var unreadMsgs = await FirebaseFirestore.instance.collection('support_messages')
        .where('storeId', isEqualTo: storeId)
        .where('sender', isEqualTo: 'super_admin')
        .where('isRead', isEqualTo: false).get();
        
    for (var doc in unreadMsgs.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  void _getStoreName() async {
    var doc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
    if (doc.exists && mounted) setState(() => storeName = doc['storeName'] ?? 'متجري');
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    
    await FirebaseFirestore.instance.collection('support_messages').add({
      'storeId': storeId,
      'storeName': storeName,
      'text': _msgController.text.trim(),
      'sender': 'store',
      'isRead': false, // إرسالها كرسالة غير مقروءة للمدير
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.blueGrey.shade800, iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('support_messages').where('storeId', isEqualTo: storeId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                    bool isMe = msg['sender'] == 'store';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueGrey.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isMe ? 'أنا' : 'الإدارة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isMe ? Colors.blueGrey : Colors.red)),
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
                Expanded(child: TextField(controller: _msgController, decoration: InputDecoration(hintText: 'اكتب رسالتك...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(25))))),
                IconButton(icon: const Icon(Icons.send, color: Colors.blueGrey), onPressed: _sendMessage)
              ],
            ),
          )
        ],
      ),
    );
  }
}
