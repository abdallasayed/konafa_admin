import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class MenuAdminScreen extends StatefulWidget {
  const MenuAdminScreen({super.key});

  @override
  State<MenuAdminScreen> createState() => _MenuAdminScreenState();
}

class _MenuAdminScreenState extends State<MenuAdminScreen> {
  
  Future<String?> _uploadToUploadcare(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://upload.uploadcare.com/base/'));
      request.fields['UPLOADCARE_PUB_KEY'] = '740f07d1a15d7ad16ff0';
      request.fields['UPLOADCARE_STORE'] = '1';
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        String uuid = json['file'];
        return 'https://ucarecdn.com/$uuid/';
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

  void _toggleAvailability(String productId, bool currentValue) {
    FirebaseFirestore.instance.collection('products').doc(productId).update({'isAvailable': !currentValue});
  }

  void _deleteProduct(String productId) {
    FirebaseFirestore.instance.collection('products').doc(productId).delete();
  }

  void _showProductFormSheet({String? productId, Map<String, dynamic>? existingProduct}) {
    final isEditing = productId != null && existingProduct != null;
    final nameController = TextEditingController(text: isEditing ? existingProduct['name'] : '');
    final priceController = TextEditingController(text: isEditing ? existingProduct['price'].toString() : '');
    final descController = TextEditingController(text: isEditing ? existingProduct['description'] : '');
    String? selectedCategoryId = isEditing ? existingProduct['categoryId'] : null;
    String existingImageUrl = isEditing ? (existingProduct['imageUrl'] ?? '') : '';
    File? pickedImage;
    bool isUploading = false;
    final storeId = FirebaseAuth.instance.currentUser!.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (pickedFile != null) setModalState(() => pickedImage = File(pickedFile.path));
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green.shade50,
                        backgroundImage: pickedImage != null ? FileImage(pickedImage!) : (existingImageUrl.isNotEmpty ? NetworkImage(existingImageUrl) : null) as ImageProvider?,
                        child: (pickedImage == null && existingImageUrl.isEmpty) ? const Icon(Icons.add_a_photo, size: 40, color: Colors.green) : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'الوصف أو المكونات', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('categories').where('storeId', isEqualTo: storeId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final categories = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
                          value: selectedCategoryId,
                          items: categories.map((cat) => DropdownMenuItem<String>(value: cat.id, child: Text(cat['name']))).toList(),
                          onChanged: (val) => setModalState(() => selectedCategoryId = val),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    isUploading ? const CircularProgressIndicator(color: Colors.green) : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () async {
                        if (nameController.text.isEmpty || priceController.text.isEmpty || selectedCategoryId == null) return;
                        setModalState(() => isUploading = true);
                        try {
                          String finalImageUrl = existingImageUrl;
                          if (pickedImage != null) {
                            String? uploadedUrl = await _uploadToUploadcare(pickedImage!);
                            if (uploadedUrl != null) finalImageUrl = uploadedUrl;
                          }
                          final productDataToSave = {
                            'name': nameController.text,
                            'price': double.tryParse(priceController.text) ?? 0.0,
                            'description': descController.text,
                            'categoryId': selectedCategoryId,
                            'imageUrl': finalImageUrl,
                            'storeId': storeId, // ربط المنتج بالمتجر
                          };
                          if (isEditing) {
                            await FirebaseFirestore.instance.collection('products').doc(productId).update(productDataToSave);
                          } else {
                            productDataToSave['isAvailable'] = true;
                            productDataToSave['createdAt'] = FieldValue.serverTimestamp();
                            await FirebaseFirestore.instance.collection('products').add(productDataToSave);
                          }
                          Navigator.pop(ctx);
                        } finally {
                          setModalState(() => isUploading = false);
                        }
                      },
                      child: Text(isEditing ? 'تعديل المنتج' : 'حفظ المنتج', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المنيو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.green.shade700),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductFormSheet(),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('storeId', isEqualTo: storeId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('المنيو فارغ حالياً'));

          final products = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index].data() as Map<String, dynamic>;
              String productId = products[index].id;
              bool isAvailable = product['isAvailable'] ?? true;
              String imageUrl = product['imageUrl'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty ? const Icon(Icons.fastfood) : null,
                  ),
                  title: Text(product['name'] ?? ''),
                  subtitle: Text('${product['price']} ج'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(value: isAvailable, activeColor: Colors.green, onChanged: (val) => _toggleAvailability(productId, isAvailable)),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductFormSheet(productId: productId, existingProduct: product)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(productId)),
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
