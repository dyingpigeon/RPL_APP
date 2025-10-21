import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/signup_controller.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView(
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Sign Up!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silahkan Buat Akun Terlebih Dahulu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 40),

                // Name Field
                const Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Masukkan nama lengkap',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                const Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<SignupController>(
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
                const Text(
                  'Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<SignupController>(
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
                const SizedBox(height: 20),

                // Confirm Password Field
                const Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return TextField(
                      controller: controller.confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Konfirmasi password',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Role Field
                const Text(
                  'Role',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        hintText: 'Pilih role',
                      ),
                      value: controller.model.role,
                      items: const [
                        DropdownMenuItem(
                          value: 'Mahasiswa',
                          child: Text('Mahasiswa'),
                        ),
                        DropdownMenuItem(
                          value: 'Dosen',
                          child: Text('Dosen'),
                        ),
                      ],
                      onChanged: controller.updateRole,
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Register Button
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        onPressed: controller.model.isLoading
                            ? null
                            : () => controller.register(context),
                        child: controller.model.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Sign In Link
                Consumer<SignupController>(
                  builder: (context, controller, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an Account? ",
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.navigateToLogin(context),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: controller.primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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