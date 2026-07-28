import 'package:flutter_test/flutter_test.dart';
import 'package:sahubyte_user/model/request/problem_list_request.dart';
import 'package:sahubyte_user/model/request/table_data_request.dart';
import 'package:sahubyte_user/model/response/service_category_model.dart';
import 'package:sahubyte_user/model/response/service_problem_model.dart';
import 'package:sahubyte_user/model/response/support_faq_model.dart';

void main() {
  test('table data request sends getData table contract', () {
    const request = TableDataRequest(
      tableName: 'subCategory',
      extra: {'categoryId': '1'},
    );

    expect(request.toJson(), {'tableName': 'subCategory', 'categoryId': '1'});
  });

  test('service category model parses db row', () {
    final category = ServiceCategoryModel.fromJson({
      'id': 1,
      'categoryName': 'Hardware',
      'categoryImage': 'uploads/categoryImage/hardware.jpg',
    });

    expect(category.id, '1');
    expect(category.name, 'Hardware');
    expect(category.image, contains('uploads/categoryImage/hardware.jpg'));
    expect(category.imageCandidates, isNotEmpty);
  });

  test('service sub category model parses db row', () {
    final subCategory = ServiceSubCategoryModel.fromJson({
      'id': 4,
      'categoryId': 1,
      'subCategoryName': 'Screen',
      'subCategoryImage': 'uploads/subCategoryImage/screen.avif',
    });

    expect(subCategory.id, '4');
    expect(subCategory.categoryId, '1');
    expect(subCategory.name, 'Screen');
    expect(subCategory.image, contains('uploads/subCategoryImage/screen.avif'));
    expect(subCategory.imageCandidates, isNotEmpty);
  });

  test('service brand model parses db row', () {
    final brand = ServiceBrandModel.fromJson({
      'id': 2,
      'brandName': 'Apple',
      'brandImage': 'uploads/brandImages/apple.png',
    });

    expect(brand.id, '2');
    expect(brand.name, 'Apple');
    expect(brand.image, contains('uploads/brandImages/apple.png'));
    expect(brand.imageCandidates, isNotEmpty);
  });

  test('service settings model parses complete store row', () {
    final settings = ServiceSettingsModel.fromJson({
      'id': 1,
      'baseServiceFee': '199',
      'taxPercent': '18',
      'storeName': 'Sahubyte Store',
      'location': 'Delhi',
      'contactNumber': '9876543210',
      'contactEmail': 'support@sahubyte.com',
      'availableService': 'Laptop repair,Networking,Software support',
    });

    expect(settings.baseServiceFee, 199);
    expect(settings.taxPercent, 18);
    expect(settings.storeName, 'Sahubyte Store');
    expect(settings.location, 'Delhi');
    expect(settings.contactNumber, '9876543210');
    expect(settings.contactEmail, 'support@sahubyte.com');
    expect(settings.availableServices, [
      'Laptop repair',
      'Networking',
      'Software support',
    ]);
  });

  test('support FAQ model parses faq table row', () {
    final faq = SupportFaqModel.fromJson({
      'id': '3',
      'title': 'How do I track a booking?',
      'description': 'Open Bookings and select View details.',
      'sortOrder': '2',
    });

    expect(faq.id, '3');
    expect(faq.title, 'How do I track a booking?');
    expect(faq.description, 'Open Bookings and select View details.');
    expect(faq.sortOrder, 2);
  });

  test('problem list request sends getProblems contract', () {
    const request = ProblemListRequest(
      categoryId: '1',
      subCategoryId: '1',
      problemIds: ['2', '3', '4'],
    );

    expect(request.toJson(), {
      'categoryId': 1,
      'subCategoryId': 1,
      'problemIds': [2, 3, 4],
    });
  });

  test('problem mapping and problem model parse db rows', () {
    final mapping = ProblemMappingModel.fromJson({
      'id': 8,
      'categoryId': 1,
      'subCategoryId': 1,
      'problemId': 4,
      'status': 1,
      'price': 200,
    });
    final problem = ServiceProblemModel.fromJson({
      'id': 4,
      'problemName': 'Overheating',
      'problemDescription': 'Device gets hot and shuts down',
      'problemImage': 'uploads/problemImage/overheating.png',
      'price': 200,
    });

    expect(mapping.problemId, '4');
    expect(mapping.price, 200);
    expect(problem.name, 'Overheating');
    expect(problem.description, 'Device gets hot and shuts down');
    expect(problem.price, 200);
    expect(problem.image, contains('uploads/problemImage/overheating.png'));
    expect(problem.imageCandidates, isNotEmpty);
  });
}
