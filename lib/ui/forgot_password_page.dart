import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ForgotPasswordController(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Reset Password", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
      ),
      backgroundColor: const Color(0xFFC2000E),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 30),
            
            // Email Field
            _buildEmailField(),
            const SizedBox(height: 30),
            
            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 20),
            
            // Back Button
            _buildBackButton(),
            
            // Spacer untuk push content ke atas
            const Expanded(child: SizedBox()),
            
            // Info Section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Lupa Password?",
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Color(0xFF333333)
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Masukkan email Anda untuk menerima kode verifikasi reset password",
          style: TextStyle(
            fontSize: 16, 
            color: Color(0xFF666666), 
            height: 1.4
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Consumer<ForgotPasswordController>(
      builder: (context, controller, child) {
        return TextField(
          controller: controller.emailController,
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
              borderSide: BorderSide(color: controller.primaryRed),
            ),
            labelText: "Email",
            hintText: "contoh@email.com",
            prefixIcon: const Icon(Icons.email_outlined),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorText: controller.model.errorMessage,
          ),
          onSubmitted: (_) => controller.sendVerificationCode(context),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<ForgotPasswordController>(
      builder: (context, controller, child) {
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              shadowColor: controller.primaryRed.withOpacity(0.3),
            ),
            onPressed: controller.model.canSubmit
                ? () => controller.sendVerificationCode(context)
                : null,
            child: controller.model.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, 
                      color: Colors.white
                    ),
                  )
                : const Text(
                    "Kirim Kode Verifikasi",
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Consumer<ForgotPasswordController>(
      builder: (context, controller, child) {
        return Center(
          child: TextButton(
            onPressed: controller.model.isLoading 
                ? null 
                : () => controller.navigateBack(context),
            child: const Text(
              "Kembali ke Login", 
              style: TextStyle(
                color: Color(0xFF666666), 
                fontSize: 14
              )
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection() {
    return Container(
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
              Text(
                "Informasi", 
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  color: Color(0xFF333333)
                )
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Kode verifikasi akan dikirim ke email Anda dan berlaku selama 10 menit. Pastikan email yang Anda masukkan benar.",
            style: TextStyle(
              fontSize: 13, 
              color: Color(0xFF6C757D), 
              height: 1.4
            ),
          ),
        ],
      ),
    );
  }
}