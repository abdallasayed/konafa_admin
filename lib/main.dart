import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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

class KonafaAdminApp extends StatefulWidget {
  const KonafaAdminApp({super.key});

  @override
  State<KonafaAdminApp> createState() => _KonafaAdminAppState();
}

class _KonafaAdminAppState extends State<KonafaAdminApp> {
  
  @override
  void initState() {
    super.initState();
    _setupOneSignal();
  }

  void _setupOneSignal() {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    // ستقوم باستبدال هذا بـ APP ID الخاص بك
    OneSignal.initialize("2d506dcb-8201-4f28-9c4e-6aeff5c6245f");
    OneSignal.Notifications.requestPermission(true);

    // عندما يتم توليد كود الهاتف، نحفظه فوراً في حساب المستخدم
    OneSignal.User.pushSubscription.addObserver((state) {
      if (state.current.id != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
           FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'oneSignalId': state.current.id,
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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey), scaffoldBackgroundColor: Colors.grey[100], useMaterial3: true),
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

                if (role == 'super_admin') return const SuperAdminDashboard();
                return const DashboardScreen();
              },
            );
          }
          return const AdminAuthScreen();
        },
      ),
    );
  }
}
// Force GitHub update for OneSignal
// Updated MinSDK for OneSignal
// Force SDK 21 via append
// Force Kotlin 1.9.24
// Updated Kotlin to 1.9.24 for OneSignal
// Fixed Kotlin version everywhere
