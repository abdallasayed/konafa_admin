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
  
  bool _isSuperAdminSetup = false; // هل نحن في وضع تسجيل المدير العام؟
  bool _hideSuperAdminButton = true; // يتم إخفاؤه افتراضياً حتى نتأكد من قاعدة البيانات

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSuperAdminExistence();
  }

  // دالة تفحص هل يوجد مدير عام مسجل مسبقاً أم لا
  Future<void> _checkSuperAdminExistence() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('system').doc('config').get();
      if (!doc.exists || doc.data()?['hasSuperAdmin'] != true) {
        setState(() => _hideSuperAdminButton = false); // إظهار الزر لأنه لا يوجد مدير بعد
      }
    } catch (e) {
      debugPrint("Error checking super admin: $e");
    }
  }

  void _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && !_isSuperAdminSetup && _storeNameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال جميع البيانات')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        
        if (_isSuperAdminSetup) {
          // تسجيل كـ "مدير عام للمنصة"
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'role': 'super_admin',
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          // قفل الزر للأبد!
          await FirebaseFirestore.instance.collection('system').doc('config').set({'hasSuperAdmin': true});
        } else {
          // تسجيل كـ "تاجر عادي"
          await FirebaseFirestore.instance.collection('stores').doc(userCredential.user!.uid).set({
            'storeName': _storeNameController.text.trim(),
            'ownerEmail': email,
            'isActive': true,
            'role': 'store_owner',
            'createdAt': FieldValue.serverTimestamp(),
          });
          // حفظ بياناته كمستخدم عادي أيضاً
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'role': 'store_owner',
            'email': email,
          });
        }
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
      backgroundColor: _isSuperAdminSetup ? Colors.red.shade50 : Colors.blueGrey.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSuperAdminSetup ? Icons.admin_panel_settings : Icons.storefront, 
                        size: 80, 
                        color: _isSuperAdminSetup ? Colors.red.shade700 : Colors.blueGrey.shade700
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isSuperAdminSetup ? 'إنشاء حساب المالك' : (_isLogin ? 'دخول التجار' : 'تسجيل متجر جديد'), 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isSuperAdminSetup ? Colors.red.shade800 : Colors.blueGrey.shade800)
                      ),
                      const SizedBox(height: 20),
                      
                      if (!_isLogin && !_isSuperAdminSetup) ...[
                        TextField(controller: _storeNameController, decoration: const InputDecoration(labelText: 'اسم المتجر', border: OutlineInputBorder())),
                        const SizedBox(height: 10),
                      ],
                      
                      TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
                      const SizedBox(height: 20),
                      
                      if (_isLoading) const CircularProgressIndicator()
                      else ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSuperAdminSetup ? Colors.red.shade800 : Colors.blueGrey.shade800, 
                          minimumSize: const Size(double.infinity, 50)
                        ),
                        onPressed: _submitAuthForm,
                        child: Text(_isLogin ? 'دخول' : 'تسجيل', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      
                      if (!_isSuperAdminSetup)
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin ? 'ليس لديك متجر؟ سجل الآن' : 'لديك متجر بالفعل؟ سجل دخول', style: const TextStyle(color: Colors.blueGrey)),
                        )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // الزر السري الذي سيختفي للأبد بعد الاستخدام الأول!
              if (!_hideSuperAdminButton && !_isLogin) 
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSuperAdminSetup = !_isSuperAdminSetup;
                    });
                  }, 
                  icon: Icon(_isSuperAdminSetup ? Icons.cancel : Icons.security, color: Colors.red), 
                  label: Text(_isSuperAdminSetup ? 'إلغاء وضع المالك' : 'تسجيل كمالك المنصة (لمرة واحدة)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))
                )
            ],
          ),
        ),
      ),
    );
  }
}
