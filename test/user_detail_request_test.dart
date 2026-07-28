import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/user_detail_request.dart';

void main() {
  test('user detail sends the JSON API field contract', () {
    const request = UserDetailRequest(id: '42');

    expect(request.toJson(), {'id': '42'});
  });
}
