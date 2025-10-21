class LoginModel {
  String? email;
  String? password;
  bool isLoading;

  LoginModel({this.email, this.password, this.isLoading = false});

  LoginModel copyWith({String? email, String? password, bool? isLoading}) {
    return LoginModel(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isFormValid => email?.isNotEmpty == true && password?.isNotEmpty == true;

  bool get isValidEmail => email?.contains('@') == true && email!.length > 3;
}
