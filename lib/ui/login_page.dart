import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView(
              children: [
                const SizedBox(height: 60),

                // Welcome Header
                const Text(
                  'Welcome, Bro!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan email dan password Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                // Email Field
                const Text('Email', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                const SizedBox(height: 8),
                Consumer<LoginController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Masukkan email',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                const Text('Password', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                const SizedBox(height: 8),
                Consumer<LoginController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Masukkan password',
                      ),
                    );
                  },
                ),

                // Forgot Password
                Consumer<LoginController>(
                  builder: (context, controller, child) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => controller.navigateToForgotPassword(context),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: controller.primaryRed, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Login Button
                Consumer<LoginController>(
                  builder: (context, controller, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.primaryRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 2,
                        ),
                        onPressed: controller.model.isLoading ? null : () => controller.login(context),
                        child:
                            controller.model.isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                                : const Text(
                                  'Login',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Sign Up Link
                Consumer<LoginController>(
                  builder: (context, controller, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Colors.black54)),
                        GestureDetector(
                          onTap: () => controller.navigateToSignup(context),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(color: controller.primaryRed, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
