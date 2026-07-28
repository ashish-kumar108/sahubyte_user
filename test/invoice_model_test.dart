import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';

void main() {
  test('invoice model parses backend parts total', () {
    final booking = EnquiryModel.fromJson({
      'id': '42',
      'userId': '7',
      'userName': 'Ashish Kumar',
      'status': '2',
      'partTotalPrice': '350',
      'tax': '99',
      'totalPrice': '1148',
    });

    expect(booking.userName, 'Ashish Kumar');
    expect(booking.partTotalPrice, 350);
    expect(booking.tax, 99);
    expect(booking.totalPrice, 1148);
  });
}
