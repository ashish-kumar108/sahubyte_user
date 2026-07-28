import 'dart:convert';

class CreateEnquiryRequest {
  const CreateEnquiryRequest({
    required this.userId,
    required this.categoryId,
    required this.subCategoryId,
    required this.brandId,
    required this.categoryName,
    required this.subCategoryName,
    required this.brandName,
    required this.dateTimeSlot,
    required this.address,
    required this.serviceFee,
    required this.tax,
    required this.totalPrice,
    required this.details,
    required this.problemIds,
    this.problemDescription,
    this.problemDetails = const [],
    this.document1,
    this.document1Type,
    this.document2,
    this.document2Type,
  });

  final String userId;
  final String categoryId;
  final String subCategoryId;
  final String brandId;
  final String categoryName;
  final String subCategoryName;
  final String brandName;
  final String dateTimeSlot;
  final String address;
  final int serviceFee;
  final int tax;
  final int totalPrice;
  final String details;
  final List<String> problemIds;
  final String? problemDescription;
  final List<Map<String, dynamic>> problemDetails;
  final String? document1;
  final String? document1Type;
  final String? document2;
  final String? document2Type;

  Map<String, dynamic> toJson() {
    final normalizedProblemIds = _normalizedProblemIds();
    final normalizedProblemDetails = _normalizedProblemDetails();
    final detailsPayload = _detailsPayload();
    final payload = <String, dynamic>{
      'userId': userId,
      'categoryId': categoryId,
      'subcategoryId': subCategoryId,
      'subCategoryId': subCategoryId,
      'brandId': brandId,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'brandName': brandName,
      'dateTimeSlot': dateTimeSlot,
      'address': address,
      'serviceFee': serviceFee,
      'tax': tax,
      'totalPrice': totalPrice,
      'details': detailsPayload,
      'detailsText': detailsPayload['problemDescription'],
      'description': detailsPayload['problemDescription'],
      'detailsJson': detailsPayload,
      'problemDescription': problemDescription?.trim().isNotEmpty == true
          ? problemDescription!.trim()
          : details,
      'createdAt': DateTime.now().toIso8601String(),
      'problemIds': normalizedProblemIds,
      'problemDetails': normalizedProblemDetails,
    };

    if (document1?.trim().isNotEmpty == true) {
      payload['document1'] = document1!.trim();
      if (document1Type?.trim().isNotEmpty == true) {
        payload['document1Type'] = document1Type!.trim();
      }
    }
    if (document2?.trim().isNotEmpty == true) {
      payload['document2'] = document2!.trim();
      if (document2Type?.trim().isNotEmpty == true) {
        payload['document2Type'] = document2Type!.trim();
      }
    }

    return payload;
  }

  Map<String, String> toFormFields() {
    final normalizedProblemIds = _normalizedProblemIds();
    final normalizedProblemDetails = _normalizedProblemDetails();
    final detailsPayload = _detailsPayload();
    final encodedDetails = jsonEncode(detailsPayload);
    final payload = <String, String>{
      'userId': userId,
      'categoryId': categoryId,
      'subcategoryId': subCategoryId,
      'subCategoryId': subCategoryId,
      'brandId': brandId,
      'categoryName': categoryName,
      'subCategoryName': subCategoryName,
      'brandName': brandName,
      'dateTimeSlot': dateTimeSlot,
      'address': address,
      'serviceFee': serviceFee.toString(),
      'tax': tax.toString(),
      'totalPrice': totalPrice.toString(),
      'details': encodedDetails,
      'detailsText': detailsPayload['problemDescription'].toString(),
      'description': detailsPayload['problemDescription'].toString(),
      'detailsJson': encodedDetails,
      'problemDescription': problemDescription?.trim().isNotEmpty == true
          ? problemDescription!.trim()
          : details,
      'createdAt': DateTime.now().toIso8601String(),
      'problemIds': jsonEncode(normalizedProblemIds),
      'problemDetails': jsonEncode(normalizedProblemDetails),
    };

    if (document1?.trim().isNotEmpty == true) {
      payload['document1'] = document1!.trim();
      if (document1Type?.trim().isNotEmpty == true) {
        payload['document1Type'] = document1Type!.trim();
      }
    }
    if (document2?.trim().isNotEmpty == true) {
      payload['document2'] = document2!.trim();
      if (document2Type?.trim().isNotEmpty == true) {
        payload['document2Type'] = document2Type!.trim();
      }
    }

    return payload;
  }

  List<Object> _normalizedProblemIds() {
    return problemIds
        .map((id) => int.tryParse(id) ?? id)
        .where((id) => id.toString().trim().isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _normalizedProblemDetails() {
    return problemDetails
        .where((problem) {
          return problem['problemId']?.toString().trim().isNotEmpty == true;
        })
        .map((problem) {
          return {
            'problemId':
                int.tryParse(problem['problemId']?.toString() ?? '') ??
                problem['problemId']?.toString() ??
                '',
            'problemName': problem['problemName']?.toString() ?? '',
            'price':
                int.tryParse(problem['price']?.toString() ?? '') ??
                problem['price'] ??
                0,
            'problemDescription':
                problem['problemDescription']?.toString() ?? '',
          };
        })
        .toList();
  }

  Map<String, dynamic> _detailsPayload() {
    final fallbackDescription = details.trim().isNotEmpty
        ? details.trim()
        : (problemDescription?.trim().isNotEmpty == true
              ? problemDescription!.trim()
              : 'Service enquiry');
    return {
      'problemDescription': problemDescription?.trim().isNotEmpty == true
          ? problemDescription!.trim()
          : fallbackDescription,
    };
  }
}
