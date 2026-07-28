import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/reset_password_request.dart';

void main() {
  test('password reset sends existing user edit contract', () {
    const request = ResetPasswordRequest(
      userId: '42',
      password: 'Secure@123',
    );

    expect(request.toFormData(), {
      'tableName': 'users',
      'act': 'edit',
      'id': '42',
      'password': 'Secure@123',
    });
  });
}
