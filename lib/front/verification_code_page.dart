import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';

class VerificationCodePage extends StatefulWidget {
  final String email; // email yang dikirim dari ForgotPasswordPage
  const VerificationCodePage({super.key, required this.email, required token});

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final Color primaryRed = const Color(0xFFC2000E);

  // Controller untuk 6 kode OTP
  final List<TextEditingController> codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final TextEditingController newPasswordController = TextEditingController();
  bool isLoading = false;

  Future<void> _resetPassword(String token) async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        "https://6c9f952c8e28.ngrok-free.app/api/v1/resetPassword",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "token": token, // gunakan token yang dikirim email
          "password": newPasswordController.text.trim(),
          "password_confirmation": newPasswordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Reset berhasil")),
        );

        // Kembali ke login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Reset gagal")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verification Code"),
        backgroundColor: primaryRed,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Kode OTP telah dikirim ke email: ${widget.email}",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Input token/OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 40,
                    child: TextField(
                      controller: codeControllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(
                        counterText: "",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Input password baru
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password Baru",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Submit
              SizedBox(
                width: 180,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          String token = codeControllers
                              .map((e) => e.text)
                              .join();
                          if (token.length == 6 &&
                              newPasswordController.text.isNotEmpty) {
                            _resetPassword(token);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Harap isi semua kode & password baru",
                                ),
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit",
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
