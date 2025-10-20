class SignupModel {
  String? name;
  String? email;
  String? password;
  String? confirmPassword;
  String? role;
  bool isLoading;

  SignupModel({this.name, this.email, this.password, this.confirmPassword, this.role, this.isLoading = false});

  SignupModel copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    String? role,
    bool? isLoading,
  }) {
    return SignupModel(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isFormValid =>
      name?.isNotEmpty == true && email?.isNotEmpty == true && password?.isNotEmpty == true && role?.isNotEmpty == true;

  bool get passwordsMatch => password == confirmPassword;
}
