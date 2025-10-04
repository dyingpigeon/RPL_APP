import 'package:flutter/material.dart';
import 'verification_code_page.dart';
import '/back/login_sign_service.dart'; // pastikan path AuthService benar

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final Color primaryRed = const Color(0xFFC2000E);

  final TextEditingController emailCtrl = TextEditingController();
  bool isLoading = false;

  void _sendToken() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Email wajib diisi!");
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.forgotPassword(email);

    setState(() => isLoading = false);

    if (result['statusCode'] == 200) {
      final token = result['data']['token'];
      _showSnackBar("Kode verifikasi sudah dikirim ke email Anda");

      // Lanjut ke halaman verifikasi kode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VerificationCodePage(email: email, token: token),
        ),
      );
    } else {
      _showSnackBar(result['data']?['message'] ?? "Gagal mengirim kode");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: primaryRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: primaryRed,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text("Masukkan email untuk menerima kode verifikasi"),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Email",
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isLoading ? null : _sendToken,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Kirim Kode",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
