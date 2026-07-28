import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/view/service_review_sheet.dart';

void main() {
  test('enquiry model parses saved job rating and review', () {
    final enquiry = EnquiryModel.fromJson({
      'id': '42',
      'userId': '7',
      'status': '2',
      'rating': '5',
      'review': 'Excellent and professional service.',
    });

    expect(enquiry.rating, 5);
    expect(enquiry.review, 'Excellent and professional service.');
    expect(enquiry.statusLabel, 'Completed');
  });

  test('automatic review prompt is reserved once per completed job', () {
    final completed = EnquiryModel.fromJson({
      'id': 'auto-review-101',
      'userId': '7',
      'status': '2',
      'rating': '0',
    });

    expect(reserveAutomaticReviewPrompt(completed), isTrue);
    expect(reserveAutomaticReviewPrompt(completed), isFalse);

    final rated = EnquiryModel.fromJson({
      'id': 'auto-review-102',
      'userId': '7',
      'status': '2',
      'rating': '5',
    });
    expect(reserveAutomaticReviewPrompt(rated), isFalse);
  });
}
