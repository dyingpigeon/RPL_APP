import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/verification_code_controller.dart';

class VerificationCodePage extends StatefulWidget {
  final String email;
  const VerificationCodePage({super.key, required this.email});

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VerificationCodeController(email: widget.email),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Verification Code"),
      backgroundColor: const Color(0xFFC2000E),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildEmailInfo(),
            const SizedBox(height: 20),
            _buildCodeInputSection(),
            const SizedBox(height: 20),
            _buildPasswordSection(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailInfo() {
    return Consumer<VerificationCodeController>(
      builder: (context, controller, child) {
        return Text(
          "Kode OTP telah dikirim ke email: ${controller.model.email}",
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildCodeInputSection() {
    return Consumer<VerificationCodeController>(
      builder: (context, controller, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 40,
              child: TextField(
                controller: controller.codeControllers[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                decoration: const InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => controller.updateCode(index, value, context),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPasswordSection() {
    return Consumer<VerificationCodeController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            TextField(
              controller: controller.newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller.confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Konfirmasi Password Baru",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<VerificationCodeController>(
      builder: (context, controller, child) {
        return SizedBox(
          width: 180,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: controller.model.canSubmit
                ? () => controller.resetPassword(context)
                : null,
            child: controller.model.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        );
      },
    );
  }
}