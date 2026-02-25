import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isLogin = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController(); // اسم المحل الجديد

  void _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && _storeNameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال جميع البيانات')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        
        // إنشاء ملف للمتجر في قاعدة البيانات وربطه بهذا المدير
        await FirebaseFirestore.instance.collection('stores').doc(userCredential.user!.uid).set({
          'storeName': _storeNameController.text.trim(),
          'ownerEmail': email,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $error')));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront, size: 80, color: Colors.blueGrey.shade700),
                  const SizedBox(height: 10),
                  Text(_isLogin ? 'دخول لوحة التحكم' : 'تسجيل متجر جديد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                  const SizedBox(height: 20),
                  
                  if (!_isLogin) ...[
                    TextField(controller: _storeNameController, decoration: const InputDecoration(labelText: 'اسم نشاطك التجاري (مثال: مطعم الأمانة)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                  ],
                  
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
                  const SizedBox(height: 20),
                  
                  if (_isLoading) const CircularProgressIndicator()
                  else ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, minimumSize: const Size(double.infinity, 50)),
                    onPressed: _submitAuthForm,
                    child: Text(_isLogin ? 'دخول' : 'إنشاء المتجر', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'ليس لديك متجر؟ سجل الآن' : 'لديك متجر بالفعل؟ سجل دخول', style: const TextStyle(color: Colors.blueGrey)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
