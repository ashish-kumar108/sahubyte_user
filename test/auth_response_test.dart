import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/response/auth_response.dart';

void main() {
  test('auth response treats numeric 200 status as success', () {
    final response = AuthResponse.fromJson({
      'status': 200,
      'message': 'Address added',
    });

    expect(response.isSuccess, isTrue);
    expect(response.displayMessage, 'Address added');
  });
}
