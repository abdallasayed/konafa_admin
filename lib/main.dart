import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_auth_screen.dart';
import 'screens/super_admin_dashboard.dart';

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
      title: 'إدارة المنصة',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          
          if (snapshot.hasData) {
            // التحقق من نوع الحساب المسجل
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                
                String role = 'store_owner'; // الافتراضي تاجر
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  role = (userSnapshot.data!.data() as Map<String, dynamic>)['role'] ?? 'store_owner';
                }

                // التوجيه الذكي بناءً على الصلاحية
                if (role == 'super_admin') {
                  return const SuperAdminDashboard(); // فتح لوحة التحكم الخارقة لك
                } else {
                  return const DashboardScreen(); // فتح لوحة المتجر العادية للتاجر
                }
              },
            );
          }
          
          return const AdminAuthScreen();
        },
      ),
    );
  }
}
