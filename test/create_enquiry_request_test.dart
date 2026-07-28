import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/create_enquiry_request.dart';

void main() {
  test('create enquiry request sends booking flow payload contract', () {
    const request = CreateEnquiryRequest(
      userId: '1',
      categoryId: '2',
      subCategoryId: '3',
      brandId: '4',
      categoryName: 'Software',
      subCategoryName: 'Desktop',
      brandName: 'Dell',
      dateTimeSlot: 'Saturday, 6 June 2026, 11:00AM - 1:00PM',
      address: 'H.No 123, Sector 15, Noida',
      serviceFee: 500,
      tax: 90,
      totalPrice: 590,
      details: 'Screen is broken and touch not working',
      problemIds: ['1', '2', '3'],
      problemDescription: 'Screen is broken and touch not working',
      problemDetails: [
        {
          'problemId': '1',
          'problemName': 'Application crash',
          'price': '100',
          'problemDescription': 'App freezes after launch',
        },
        {'problemId': '2', 'problemName': 'Slow performance', 'price': 200},
      ],
      document1: 'data:image/png;base64,abc',
      document1Type: 'image',
      document2: 'data:video/mp4;base64,xyz',
      document2Type: 'video',
    );

    final payload = request.toJson();
    final formFields = request.toFormFields();

    expect(payload['userId'], '1');
    expect(payload['categoryId'], '2');
    expect(payload['subcategoryId'], '3');
    expect(payload['subCategoryId'], '3');
    expect(payload['brandId'], '4');
    expect(payload['categoryName'], 'Software');
    expect(payload['subCategoryName'], 'Desktop');
    expect(payload['brandName'], 'Dell');
    expect(payload['dateTimeSlot'], 'Saturday, 6 June 2026, 11:00AM - 1:00PM');
    expect(payload['address'], 'H.No 123, Sector 15, Noida');
    expect(payload.containsKey('state'), isFalse);
    expect(payload['serviceFee'], 500);
    expect(payload['tax'], 90);
    expect(payload['totalPrice'], 590);
    expect(payload['details'], isA<Map<String, dynamic>>());
    expect(payload['details'].keys, ['problemDescription']);
    expect(payload['details'].containsKey('category'), isFalse);
    expect(payload['details'].containsKey('brand'), isFalse);
    expect(payload['details'].containsKey('address'), isFalse);
    expect(payload['details'].containsKey('charges'), isFalse);
    expect(payload['details'].containsKey('problemIds'), isFalse);
    expect(payload['details'].containsKey('problemDetails'), isFalse);
    expect(
      payload['details']['problemDescription'],
      'Screen is broken and touch not working',
    );
    expect(payload['detailsText'], 'Screen is broken and touch not working');
    expect(payload['description'], 'Screen is broken and touch not working');
    expect(
      payload['problemDescription'],
      'Screen is broken and touch not working',
    );
    expect(payload['problemIds'], [1, 2, 3]);
    expect(payload['problemDetails'], [
      {
        'problemId': 1,
        'problemName': 'Application crash',
        'price': 100,
        'problemDescription': 'App freezes after launch',
      },
      {
        'problemId': 2,
        'problemName': 'Slow performance',
        'price': 200,
        'problemDescription': '',
      },
    ]);
    expect(payload['document1Type'], 'image');
    expect(payload['document2Type'], 'video');

    expect(formFields['userId'], '1');
    expect(formFields['subCategoryId'], '3');
    expect(formFields.containsKey('state'), isFalse);
    final detailsJson = jsonDecode(formFields['details']!) as Map;
    expect(detailsJson.keys, ['problemDescription']);
    expect(detailsJson.containsKey('category'), isFalse);
    expect(detailsJson.containsKey('brand'), isFalse);
    expect(detailsJson.containsKey('charges'), isFalse);
    expect(detailsJson.containsKey('problemIds'), isFalse);
    expect(detailsJson.containsKey('problemDetails'), isFalse);
    expect(
      detailsJson['problemDescription'],
      'Screen is broken and touch not working',
    );
    expect(formFields['detailsJson'], formFields['details']);
    expect(formFields['description'], 'Screen is broken and touch not working');
    expect(jsonDecode(formFields['problemIds']!) as List, [1, 2, 3]);
    expect(jsonDecode(formFields['problemDetails']!) as List, [
      {
        'problemId': 1,
        'problemName': 'Application crash',
        'price': 100,
        'problemDescription': 'App freezes after launch',
      },
      {
        'problemId': 2,
        'problemName': 'Slow performance',
        'price': 200,
        'problemDescription': '',
      },
    ]);
  });
}
