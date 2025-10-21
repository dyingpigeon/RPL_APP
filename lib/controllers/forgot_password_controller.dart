import 'package:flutter/material.dart';
import '../models/forgot_password_model.dart';
import '../services/auth_service.dart';
import '../ui/verification_code_page.dart';

class ForgotPasswordController with ChangeNotifier {
  ForgotPasswordModel _model = ForgotPasswordModel();
  final Color primaryRed = const Color(0xFFC2000E);

  ForgotPasswordModel get model => _model;

  // TextEditing controller untuk form handling
  final TextEditingController emailController = TextEditingController();

  ForgotPasswordController() {
    // Setup listener untuk real-time validation
    emailController.addListener(() {
      _model = _model.copyWith(email: emailController.text.trim());
      notifyListeners();
    });
  }

  Future<void> sendVerificationCode(BuildContext context) async {
    // Validasi email
    if (_model.email?.isEmpty == true) {
      _showSnackBar(context, "Email wajib diisi!");
      return;
    }

    if (!_model.isEmailValid) {
      _showSnackBar(context, "Format email tidak valid!");
      return;
    }

    _model = _model.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      print('🎬 START FORGOT PASSWORD PROCESS');
      print('📧 Email: ${_model.email}');

      // Pakai AuthService untuk API call
      final result = await AuthService.forgotPassword(_model.email!);

      print('-----------------------');
      print('🎯 FORGOT PASSWORD RESULT IN CONTROLLER:');
      print('✅ Success: ${result['success']}');
      print('💬 Message: ${result['message']}');
      print('-----------------------');

      // Tampilkan snackbar dengan pesan dari API (baik sukses maupun error)
      _showSnackBar(context, result['message']);

      // Jika sukses, navigate ke verification page
      if (result['success'] == true) {
        // Delay sedikit agar user bisa baca snackbar
        await Future.delayed(const Duration(milliseconds: 1500));

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationCodePage(email: _model.email!),
            ),
          );
        }
      } else {
        // Set error message jika gagal
        _model = _model.copyWith(errorMessage: result['message']);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error in Controller: $e');
      final errorMessage = "Terjadi kesalahan: $e";
      _showSnackBar(context, errorMessage);
      _model = _model.copyWith(errorMessage: errorMessage);
      notifyListeners();
    } finally {
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
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

  void navigateBack(BuildContext context) {
    Navigator.pop(context);
  }

  void clearForm() {
    emailController.clear();
    _model = ForgotPasswordModel();
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}