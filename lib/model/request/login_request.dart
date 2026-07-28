class LoginRequest {
  const LoginRequest({required this.mobile, required this.password});

  final String mobile;
  final String password;

  Map<String, String> toFormData() {
    return {'mobile': mobile, 'password': password};
  }
}
