import 'package:elearning_rpl_5d/front/class_page.dart';
import 'package:flutter/material.dart';
import 'front/login_page.dart';
import 'front/signup_page.dart';
import 'front/home_page.dart';
import 'front/edit_profile_page.dart';
import 'front/forgot_password_page.dart';
import 'front/main_wrapper.dart'; // ← IMPORT BARU

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const MainWrapper(), // ← UBAH KE MAIN WRAPPER
        '/edit': (context) => const EditProfilePage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/class': (context) => const ClassPage(),
      },
    );
  }
}
