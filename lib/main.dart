import 'package:elearning_rpl_5d/ui/class_page.dart';
import 'package:flutter/material.dart';
import 'ui/login_page.dart';
import 'ui/signup_page.dart';
import 'ui/edit_profile_page.dart';
import 'ui/forgot_password_page.dart';
import 'ui/main_wrapper.dart';
import 'controllers/edit_profile_controller.dart'; // IMPORT CONTROLLER

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ✅ TAMBAHKAN NAVIGATOR KEY DI SINI
      navigatorKey: EditProfileController.navigatorKey,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const MainWrapper(),
        '/edit': (context) => const EditProfilePage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/class': (context) => const ClassPage(),
      },
    );
  }
}
