import 'package:flutter/material.dart';
import '../models/signup_model.dart';
import '../services/auth_service.dart';
import '../ui/login_page.dart';

class SignupController with ChangeNotifier {
  SignupModel _model = SignupModel();
  final Color primaryRed = const Color(0xFFC2000E);

  SignupModel get model => _model;

  // TextEditing controllers untuk form handling yang lebih baik
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  SignupController() {
    // Setup listeners untuk real-time validation
    nameController.addListener(() {
      _model = _model.copyWith(name: nameController.text.trim());
      notifyListeners();
    });

    emailController.addListener(() {
      _model = _model.copyWith(email: emailController.text.trim());
      notifyListeners();
    });

    passwordController.addListener(() {
      _model = _model.copyWith(password: passwordController.text.trim());
      notifyListeners();
    });

    confirmPasswordController.addListener(() {
      _model = _model.copyWith(confirmPassword: confirmPasswordController.text.trim());
      notifyListeners();
    });
  }

  void updateRole(String? role) {
    _model = _model.copyWith(role: role);
    notifyListeners();
  }

  void setLoading(bool loading) {
    _model = _model.copyWith(isLoading: loading);
    notifyListeners();
  }

  Future<void> register(BuildContext context) async {
    // Validasi form
    if (!_model.isFormValid) {
      _showSnackBar(context, "Semua field wajib diisi");
      return;
    }

    if (!_model.passwordsMatch) {
      _showSnackBar(context, "Password dan konfirmasi tidak sama");
      return;
    }

    if (_model.password!.length < 6) {
      _showSnackBar(context, "Password minimal 6 karakter");
      return;
    }

    setLoading(true);

    try {
      final result = await AuthService.register(
        name: _model.name!,
        email: _model.email!,
        password: _model.password!,
        role: _model.role!.toLowerCase(),
      );

      setLoading(false);

      final statusCode = result["statusCode"];
      final data = result["data"];

      if (statusCode == 200 && !data.containsKey("errors")) {
        _showSnackBar(context, "Registrasi berhasil, silakan login");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        _showSnackBar(context, data["message"] ?? "Registrasi gagal");
      }
    } catch (e) {
      setLoading(false);
      _showSnackBar(context, "Terjadi kesalahan: $e");
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void navigateToLogin(BuildContext context) {
    Navigator.pop(context);
  }

  void clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _model = SignupModel();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}