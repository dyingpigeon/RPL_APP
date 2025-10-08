import 'package:flutter/material.dart';
import 'verification_code_page.dart';
import '../back/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final Color primaryRed = const Color(0xFFC2000E);
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    // Validasi email
    if (email.isEmpty) {
      _showSnackBar("Email wajib diisi!");
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Format email tidak valid!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Pakai AuthService untuk API call
      final result = await AuthService.forgotPassword(email);

      // Handle response dari API
      if (result['statusCode'] == 200) {
        _showSnackBar("Kode verifikasi telah dikirim ke email Anda");

        // Navigate ke verification page
        Navigator.push(context, MaterialPageRoute(builder: (context) => VerificationCodePage(email: email)));
      } else {
        final errorMessage = result['data']?['message'] ?? "Gagal mengirim kode verifikasi";
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: primaryRed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password"), backgroundColor: primaryRed),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Masukkan email untuk menerima kode verifikasi",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Email",
                  hintText: "contoh@email.com",
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Kirim Kode", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kembali ke Login")),
            ],
          ),
        ),
      ),
    );
  }
}
