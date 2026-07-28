import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/user_address_request.dart';

void main() {
  test('user address add sends createFunction field contract', () {
    const request = UserAddressRequest(
      act: 'add',
      userId: '42',
      address: 'D1/37, Sector 16D, Rohini, Delhi - 110089',
      createdAt: '2026-06-03 10:30:00',
    );

    expect(request.toJson(), {
      'tableName': 'userAddress',
      'act': 'add',
      'userId': '42',
      'address': 'D1/37, Sector 16D, Rohini, Delhi - 110089',
      'createdAt': '2026-06-03 10:30:00',
    });
  });

  test('user address edit sends id and edit act', () {
    const request = UserAddressRequest(
      act: 'edit',
      id: '7',
      userId: '42',
      address: 'Cyber Park, Gomti Nagar, Lucknow, Uttar Pradesh - 226010',
    );

    expect(request.toJson(), {
      'tableName': 'userAddress',
      'act': 'edit',
      'id': '7',
      'userId': '42',
      'address': 'Cyber Park, Gomti Nagar, Lucknow, Uttar Pradesh - 226010',
    });
  });
}
