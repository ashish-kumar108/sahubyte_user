import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/get_enquiries_request.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';

void main() {
  test('get enquiries request sends user pagination fields', () {
    const request = GetEnquiriesRequest(userId: '7', page: 2, limit: 20);

    expect(request.toJson(), {'userId': '7', 'page': '2', 'limit': '20'});
  });

  test('enquiry model parses booking row', () {
    final enquiry = EnquiryModel.fromJson({
      'id': 9,
      'userId': 1,
      'categoryId': 2,
      'subCategoryId': 3,
      'brandId': 4,
      'categoryName': 'Hardware',
      'subCategoryName': 'Laptop',
      'brandName': 'Dell',
      'dateTimeSlot': 'Tuesday, 9 June 2026, 11:00AM - 1:00PM',
      'address': 'B2/113, Rohini',
      'serviceFee': '199',
      'status': '0',
      'details': '{"problemDescription":"Screen flickering"}',
      'problemDetails': [
        {'problemId': '4', 'problemName': 'Display issue', 'price': '200'},
      ],
      'tax': '36',
      'totalPrice': '235',
      'createdAt': '2026-06-09',
    });

    expect(enquiry.bookingCode, 'SB-000009');
    expect(enquiry.serviceTitle, 'Hardware / Laptop / Dell');
    expect(enquiry.statusLabel, 'Awaiting');
    expect(enquiry.problemDescription, 'Screen flickering');
    expect(enquiry.problemSummary, 'Display issue');
    expect(enquiry.totalPrice, 235);
  });
}
