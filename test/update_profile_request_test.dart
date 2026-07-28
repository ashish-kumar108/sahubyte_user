import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/update_profile_request.dart';

void main() {
  test('profile update sends the PHP API field contract', () {
    const request = UpdateProfileRequest(
      id: '42',
      name: 'Test User',
      mobile: '9999999999',
      email: 'user@example.com',
      dob: '2000-01-31',
      profileImageBase64: 'encoded-image',
    );

    expect(request.toJson(), {
      'tableName': 'users',
      'act': 'edit',
      'id': '42',
      'name': 'Test User',
      'mobile': '9999999999',
      'email': 'user@example.com',
      'dob': '2000-01-31',
      'folderName': 'userprofile',
      'profileImage': 'encoded-image',
    });
  });
}
