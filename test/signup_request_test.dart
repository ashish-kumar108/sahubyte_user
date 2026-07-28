import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/signup_request.dart';

void main() {
  test('signup request sends the PHP API field contract', () {
    const request = SignupRequest(
      mobile: '9999999999',
      email: 'user@example.com',
      name: 'Test User',
      dob: '2000-01-02',
      password: 'Secure@123',
    );

    expect(request.toFormData(), {
      'mobile': '9999999999',
      'email': 'user@example.com',
      'name': 'Test User',
      'dob': '2000-01-02',
      'password': 'Secure@123',
    });
  });
}
