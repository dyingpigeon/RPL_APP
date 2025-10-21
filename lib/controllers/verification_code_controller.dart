import 'package:flutter/material.dart';
import '../models/verification_code_model.dart';
import '../services/auth_service.dart';
import '../ui/login_page.dart';

class VerificationCodeController with ChangeNotifier {
  VerificationCodeModel _model;
  final Color primaryRed = const Color(0xFFC2000E);

  // TextEditing controllers untuk form handling
  final List<TextEditingController> codeControllers = List.generate(6, (_) => TextEditingController());
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  VerificationCodeController({required String email}) : _model = VerificationCodeModel(email: email) {
    _setupListeners();
  }

  VerificationCodeModel get model => _model;

  void _setupListeners() {
    // Setup listeners untuk code fields
    for (int i = 0; i < codeControllers.length; i++) {
      codeControllers[i].addListener(() {
        final newCode = List<String>.from(_model.code);
        newCode[i] = codeControllers[i].text;
        _model = _model.copyWith(code: newCode);
        notifyListeners();
      });
    }

    // Setup listeners untuk password fields
    newPasswordController.addListener(() {
      _model = _model.copyWith(newPassword: newPasswordController.text.trim());
      notifyListeners();
    });

    confirmPasswordController.addListener(() {
      _model = _model.copyWith(confirmPassword: confirmPasswordController.text.trim());
      notifyListeners();
    });
  }

  void updateCode(int index, String value, BuildContext context) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).nextFocus();
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).previousFocus();
    }
  }

  Future<void> resetPassword(BuildContext context) async {
    if (!_model.isTokenValid) {
      _showSnackBar(context, "Harap isi semua kode OTP");
      return;
    }

    if (!_model.arePasswordsValid) {
      _showSnackBar(context, "Harap isi password baru dan konfirmasinya");
      return;
    }

    if (!_model.doPasswordsMatch) {
      _showSnackBar(context, "Password dan konfirmasi password tidak sama");
      return;
    }

    _model = _model.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await AuthService.resetPassword(
        email: _model.email,
        token: _model.token,
        password: _model.newPassword,
        passwordConfirmation: _model.confirmPassword,
      );

      _model = _model.copyWith(isLoading: false);
      notifyListeners();

      if (result['statusCode'] == 200) {
        _showSnackBar(context, "Password berhasil direset");

        // Kembali ke login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        final errorMessage = result['data']['message'] ?? "Reset password gagal";
        _showSnackBar(context, errorMessage);
      }
    } catch (e) {
      _model = _model.copyWith(isLoading: false);
      notifyListeners();
      _showSnackBar(context, "Terjadi kesalahan: $e");
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: primaryRed, duration: const Duration(seconds: 3)));
  }

  void clearForm() {
    for (var controller in codeControllers) {
      controller.clear();
    }
    newPasswordController.clear();
    confirmPasswordController.clear();
    _model = VerificationCodeModel(email: _model.email);
    notifyListeners();
  }

  @override
  void dispose() {
    for (var controller in codeControllers) {
      controller.dispose();
    }
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
