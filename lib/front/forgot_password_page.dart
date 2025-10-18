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
      print('🎬 START FORGOT PASSWORD PROCESS');
      print('📧 Email: $email');

      // Pakai AuthService untuk API call
      final result = await AuthService.forgotPassword(email);

      print('-----------------------');
      print('🎯 FORGOT PASSWORD RESULT IN UI:');
      print('✅ Success: ${result['success']}');
      print('💬 Message: ${result['message']}');
      print('-----------------------');

      // Tampilkan snackbar dengan pesan dari API (baik sukses maupun error)
      _showSnackBar(result['message']);

      // Jika sukses, navigate ke verification page
      if (result['success'] == true) {
        // Delay sedikit agar user bisa baca snackbar
        await Future.delayed(const Duration(milliseconds: 1500));

        Navigator.push(context, MaterialPageRoute(builder: (context) => VerificationCodePage(email: email)));
      }
    } catch (e) {
      print('❌ Error in UI: $e');
      _showSnackBar("Terjadi kesalahan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryRed,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              const Text(
                "Lupa Password?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Masukkan email Anda untuk menerima kode verifikasi reset password",
                style: TextStyle(fontSize: 16, color: Color(0xFF666666), height: 1.4),
              ),
              const SizedBox(height: 30),
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryRed),
                  ),
                  labelText: "Email",
                  hintText: "contoh@email.com",
                  prefixIcon: const Icon(Icons.email_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (_) => _sendVerificationCode(),
              ),
              const SizedBox(height: 30),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    shadowColor: primaryRed.withOpacity(0.3),
                  ),
                  onPressed: _isLoading ? null : _sendVerificationCode,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                          : const Text(
                            "Kirim Kode Verifikasi",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                ),
              ),
              const SizedBox(height: 20),
              // Back Button
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Kembali ke Login", style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
                ),
              ),
              // Spacer untuk push content ke atas
              const Expanded(child: SizedBox()),
              // Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFF6C757D)),
                        SizedBox(width: 8),
                        Text("Informasi", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Kode verifikasi akan dikirim ke email Anda dan berlaku selama 10 menit. Pastikan email yang Anda masukkan benar.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF6C757D), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
