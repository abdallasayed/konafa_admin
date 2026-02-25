import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class MenuAdminScreen extends StatefulWidget {
  const MenuAdminScreen({super.key});

  @override
  State<MenuAdminScreen> createState() => _MenuAdminScreenState();
}

class _MenuAdminScreenState extends State<MenuAdminScreen> {
  
  // دالة الرفع إلى Uploadcare
  Future<String?> _uploadToUploadcare(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://upload.uploadcare.com/base/'));
      // إضافة مفتاحك الخاص
      request.fields['UPLOADCARE_PUB_KEY'] = '740f07d1a15d7ad16ff0';
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        String uuid = json['file'];
        // تكوين الرابط النهائي للصورة المرفوعة
        return 'https://ucarecdn.com/$uuid/';
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

  void _toggleAvailability(String productId, bool currentValue) {
    FirebaseFirestore.instance.collection('products').doc(productId).update({
      'isAvailable': !currentValue,
    });
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red)),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا المنتج نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(productId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح')));
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddProductSheet() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    String? selectedCategoryId;
    
    File? pickedImage;
    bool isUploading = false;

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
              if (pickedFile != null) {
                setModalState(() {
                  pickedImage = File(pickedFile.path);
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('إضافة منتج جديد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 15),
                    
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green.shade50,
                        backgroundImage: pickedImage != null ? FileImage(pickedImage!) : null,
                        child: pickedImage == null ? const Icon(Icons.add_a_photo, size: 40, color: Colors.green) : null,
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
                      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final categories = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'القسم', border: OutlineInputBorder()),
                          value: selectedCategoryId,
                          items: categories.map((cat) {
                            return DropdownMenuItem<String>(value: cat.id, child: Text(cat['name']));
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() { selectedCategoryId = val; });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    isUploading 
                      ? const CircularProgressIndicator(color: Colors.green)
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                          onPressed: () async {
                            if (nameController.text.isEmpty || priceController.text.isEmpty || selectedCategoryId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال البيانات الأساسية')));
                              return;
                            }

                            setModalState(() { isUploading = true; });

                            try {
                              String imageUrl = '';
                              
                              // الرفع إلى Uploadcare إذا تم اختيار صورة
                              if (pickedImage != null) {
                                String? uploadedUrl = await _uploadToUploadcare(pickedImage!);
                                if (uploadedUrl != null) {
                                  imageUrl = uploadedUrl;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل رفع الصورة، سيتم الحفظ بدونها')));
                                }
                              }

                              await FirebaseFirestore.instance.collection('products').add({
                                'name': nameController.text,
                                'price': double.tryParse(priceController.text) ?? 0.0,
                                'description': descController.text,
                                'categoryId': selectedCategoryId,
                                'isAvailable': true,
                                'imageUrl': imageUrl,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة بنجاح!')));
                            } catch (error) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $error')));
                            } finally {
                              setModalState(() { isUploading = false; });
                            }
                          },
                          child: const Text('حفظ المنتج', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المنيو', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductSheet,
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة منتج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: isAvailable ? Colors.green.shade50 : Colors.grey.shade200,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty ? Icon(Icons.fastfood, color: isAvailable ? Colors.green : Colors.grey) : null,
                  ),
                  title: Text(product['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, decoration: isAvailable ? null : TextDecoration.lineThrough)),
                  subtitle: Text('${product['price']} ج\n${product['description'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isAvailable,
                        activeColor: Colors.green,
                        onChanged: (val) => _toggleAvailability(productId, isAvailable),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(productId),
                      ),
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
