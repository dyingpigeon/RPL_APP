import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../services/auth_service.dart';
import '../ui/signup_page.dart';
import '../ui/forgot_password_page.dart';

class LoginController with ChangeNotifier {
  LoginModel _model = LoginModel();
  final Color primaryRed = const Color(0xFFC2000E);

  LoginModel get model => _model;

  // TextEditing controllers untuk form handling
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginController() {
    // Setup listeners untuk real-time validation
    emailController.addListener(() {
      _model = _model.copyWith(email: emailController.text.trim());
      notifyListeners();
    });

    passwordController.addListener(() {
      _model = _model.copyWith(password: passwordController.text.trim());
      notifyListeners();
    });
  }

  void setLoading(bool loading) {
    _model = _model.copyWith(isLoading: loading);
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    // Validasi form
    if (!_model.isFormValid) {
      _showSnackBar(context, "Email dan password wajib diisi");
      return;
    }

    if (!_model.isValidEmail) {
      _showSnackBar(context, "Format email tidak valid");
      return;
    }

    if (_model.password!.length < 6) {
      _showSnackBar(context, "Password minimal 6 karakter");
      return;
    }

    setLoading(true);

    try {
      final result = await AuthService.login(_model.email!, _model.password!);

      setLoading(false);

      final statusCode = result["statusCode"];
      final data = result["data"];

      if (statusCode == 200 && !data.containsKey("errors")) {
        _showSnackBar(context, "Login berhasil!");

        // Navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final errorMessage = data["message"] ?? data["error"] ?? data["errors"]?.toString() ?? "Login gagal";
        _showSnackBar(context, errorMessage);
      }
    } catch (e) {
      setLoading(false);
      _showSnackBar(context, "Terjadi kesalahan: $e");
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: primaryRed, duration: const Duration(seconds: 3)));
  }

  void navigateToSignup(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()));
  }

  void navigateToForgotPassword(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage()));
  }

  void clearForm() {
    emailController.clear();
    passwordController.clear();
    _model = LoginModel();
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
