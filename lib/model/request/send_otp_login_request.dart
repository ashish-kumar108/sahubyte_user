class SendOtpLoginRequest {
  const SendOtpLoginRequest({required this.mobile});

  final String mobile;

  Map<String, String> toFormData() {
    return {'mobile': mobile};
  }
}
