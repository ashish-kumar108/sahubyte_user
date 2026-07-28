class SignupOtpRequest {
  const SignupOtpRequest({required this.mobile});

  final String mobile;

  Map<String, String> toFormData() {
    return {'mobile': mobile};
  }
}
