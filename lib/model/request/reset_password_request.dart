class ResetPasswordRequest {
  const ResetPasswordRequest({required this.userId, required this.password});

  final String userId;
  final String password;

  Map<String, String> toFormData() {
    return {
      'tableName': 'users',
      'act': 'edit',
      'id': userId,
      'password': password,
    };
  }
}
