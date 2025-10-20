import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final Color primaryRed = const Color(0xFFC2000E);

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();

  String? selectedRole; // Mahasiswa atau Dosen
  bool isLoading = false;

  void _register() async {
    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    final confirmPassword = confirmPassCtrl.text.trim();
    final role = selectedRole?.toLowerCase(); // API pakai lowercase

    if (name.isEmpty || email.isEmpty || password.isEmpty || role == null) {
      _showSnackBar("Semua field wajib diisi");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Password dan konfirmasi tidak sama");
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.register(name: name, email: email, password: password, role: role);

    setState(() => isLoading = false);

    final statusCode = result["statusCode"];
    final data = result["data"];

    if (statusCode == 200 && !data.containsKey("errors")) {
      _showSnackBar("Registrasi berhasil, silakan login");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } else {
      _showSnackBar(data["message"] ?? "Registrasi gagal");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: primaryRed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silahkan Buat Akun Terlebih Dahulu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Name
              const Text('Name'),
              TextField(controller: nameCtrl),
              const SizedBox(height: 20),

              // Email
              const Text('Email'),
              TextField(controller: emailCtrl),
              const SizedBox(height: 20),

              // Password
              const Text('Password'),
              TextField(controller: passCtrl, obscureText: true),
              const SizedBox(height: 20),

              // Confirm Password
              const Text('Confirm password'),
              TextField(controller: confirmPassCtrl, obscureText: true),
              const SizedBox(height: 20),

              // Role
              const Text('Role'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'Mahasiswa', child: Text('Mahasiswa')),
                  DropdownMenuItem(value: 'Dosen', child: Text('Dosen')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: isLoading ? null : _register,
                  child:
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Register', style: TextStyle(color: Colors.white)),
                ),
              ),

              const SizedBox(height: 24),

              // Sign In link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an Account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // balik ke login
                    },
                    child: Text('Sign In', style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
