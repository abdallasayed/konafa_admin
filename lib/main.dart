import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_auth_screen.dart';
import 'screens/super_admin_dashboard.dart';

// دالة لاستقبال الإشعارات والتطبيق مغلق (في الخلفية)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

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

  // تفعيل الاستماع للإشعارات في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const KonafaAdminApp());
}

class KonafaAdminApp extends StatefulWidget {
  const KonafaAdminApp({super.key});

  @override
  State<KonafaAdminApp> createState() => _KonafaAdminAppState();
}

class _KonafaAdminAppState extends State<KonafaAdminApp> {
  
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  // دالة تهيئة الإشعارات
  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // طلب الصلاحية من المستخدم لإظهار الإشعار (مهم للأندرويد الحديث والآيفون)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // جلب كود الهاتف الفريد (Token) وحفظه في قاعدة البيانات بمجرد تسجيل الدخول
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        String? token = await messaging.getToken();
        if (token != null) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': token, // حفظ كود الهاتف
          }, SetOptions(merge: true));
        }
      }
    });
  }

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
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
                
                String role = 'store_owner';
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  role = (userSnapshot.data!.data() as Map<String, dynamic>)['role'] ?? 'store_owner';
                }

                if (role == 'super_admin') {
                  return const SuperAdminDashboard();
                } else {
                  return const DashboardScreen();
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
