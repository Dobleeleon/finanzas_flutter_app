import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAeviSI6VfGJuEwffxNFuTmvS5p4zjYfZM",
        authDomain: "finanzas-pareja-123bf.firebaseapp.com",
        projectId: "finanzas-pareja-123bf",
        storageBucket: "finanzas-pareja-123bf.firebasestorage.app",
        messagingSenderId: "289380627307",
        appId: "1:289380627307:web:5d95c73b01c1b59f7ad22e",
      ),
    );
  } catch (e) {
    // Silenciar error de inicialización de Firebase
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finanzas Pareja',
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}