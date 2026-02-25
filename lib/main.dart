import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAegRWgOmfPF4IXwkGQlEmeCQC5ch6AxC8",
      authDomain: "konafa-app.firebaseapp.com",
      projectId: "konafa-app",
      storageBucket: "konafa-app.firebasestorage.app",
      messagingSenderId: "487013929710",
      appId: "1:487013929710:web:b2ef64c2dda93a3ba8d9ff",
    ),
  );
  
  runApp(const KonafaAdminApp());
}

class KonafaAdminApp extends StatelessWidget {
  const KonafaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة المتاجر',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      // مراقبة حالة تسجيل الدخول للمدير
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // إذا كان مسجلاً، ادخله للوحة التحكم
            return const DashboardScreen();
          }
          // إذا لم يكن مسجلاً، اطلب منه الدخول أو إنشاء متجر
          return const AdminAuthScreen();
        },
      ),
    );
  }
}
