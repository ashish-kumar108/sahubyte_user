import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/user_address_list_request.dart';
import 'package:sahubyte_user/model/response/user_address_model.dart';

void main() {
  test('user address list request sends getData field contract', () {
    const request = UserAddressListRequest(userId: '42');

    expect(request.toJson(), {'tableName': 'userAddress', 'userId': '42'});
  });

  test('user address model parses db row', () {
    final address = UserAddressModel.fromJson({
      'id': 7,
      'address': 'D1/37, Sector 16D, Rohini, Delhi - 110089',
      'state': 'Delhi',
      'userId': 42,
      'createdAt': '2026-06-03 10:30:00',
    });

    expect(address.id, '7');
    expect(address.address, 'D1/37, Sector 16D, Rohini, Delhi - 110089');
    expect(address.state, 'Delhi');
    expect(address.userId, '42');
    expect(address.createdAt, '2026-06-03 10:30:00');
  });
}
