class VerificationCodeModel {
  String email;
  List<String> code;
  String newPassword;
  String confirmPassword;
  bool isLoading;

  VerificationCodeModel({
    required this.email,
    List<String>? code,
    this.newPassword = '',
    this.confirmPassword = '',
    this.isLoading = false,
  }) : code = code ?? List.filled(6, '');

  VerificationCodeModel copyWith({
    String? email,
    List<String>? code,
    String? newPassword,
    String? confirmPassword,
    bool? isLoading,
  }) {
    return VerificationCodeModel(
      email: email ?? this.email,
      code: code ?? this.code,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String get token => code.join();
  bool get isTokenValid => token.length == 6;
  bool get arePasswordsValid => newPassword.isNotEmpty && confirmPassword.isNotEmpty;
  bool get doPasswordsMatch => newPassword == confirmPassword;
  bool get canSubmit => isTokenValid && arePasswordsValid && doPasswordsMatch && !isLoading;
}