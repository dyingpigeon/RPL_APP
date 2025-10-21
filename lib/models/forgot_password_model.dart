class ForgotPasswordModel {
  String? email;
  bool isLoading;
  String? errorMessage;

  ForgotPasswordModel({
    this.email,
    this.isLoading = false,
    this.errorMessage,
  });

  ForgotPasswordModel copyWith({
    String? email,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ForgotPasswordModel(
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isEmailValid =>
      email?.isNotEmpty == true &&
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email!);

  bool get canSubmit => email?.isNotEmpty == true && !isLoading;
}