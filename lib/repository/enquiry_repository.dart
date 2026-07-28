import '../data/network/api_service.dart';
import '../data/network/network_api_service.dart';
import '../model/request/create_enquiry_request.dart';
import '../model/request/get_enquiries_request.dart';
import '../model/response/enquiry_model.dart';
import '../res/api_constants.dart';

class EnquiryRepository {
  EnquiryRepository({BaseApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  final BaseApiService _apiService;

  Future<Map<String, dynamic>> createEnquiry(
    CreateEnquiryRequest request,
  ) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userCreateEnquiry,
      request.toFormFields(),
    );
    return _ensureSuccess(response);
  }

  Future<List<EnquiryModel>> getEnquiries({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetEnquiries,
      GetEnquiriesRequest(userId: userId, page: page, limit: limit).toJson(),
    );
    final enquiries = _extractListJson(response)
        .map(EnquiryModel.fromJson)
        .where((enquiry) => enquiry.id.isNotEmpty)
        .toList();
    return _withAssignedTechnicianProgress(enquiries, userId: userId);
  }

  Future<Map<String, dynamic>?> getJobCard(String enquiryId) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.technicianGetJobCard,
      {'enquiryId': enquiryId},
    );
    final rows = _extractListJson(response);
    if (rows.isNotEmpty) return rows.first;
    if (response is Map) {
      final json = Map<String, dynamic>.from(response);
      final data = json['data'] ?? json['jobCard'] ?? json['result'];
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<Map<String, dynamic>> approveJobCard({
    required String enquiryId,
    required int partTotalPrice,
  }) async {
    final approvedAt = _apiTimestamp(DateTime.now());
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.userCreateFunction, {
          'tableName': 'enquiries',
          'act': 'edit',
          'id': enquiryId,
          'workConfirmation': '1',
          'workConfirmationDate': approvedAt,
          'partTotalPrice': partTotalPrice.toString(),
        });
    return _ensureSuccess(response);
  }

  Future<Map<String, dynamic>> updateFinalPayment({
    required String enquiryId,
    required String paymentType,
    required String paymentStatus,
  }) async {
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.userCreateFunction, {
          'tableName': 'enquiries',
          'act': 'edit',
          'id': enquiryId.trim(),
          'paymentType': paymentType.trim().toLowerCase(),
          'paymentStatus': paymentStatus.trim().toLowerCase(),
        });
    return _ensureSuccess(response);
  }

  Future<Map<String, dynamic>> submitJobReview({
    required String enquiryId,
    required int rating,
    required String review,
  }) async {
    final response = await _apiService
        .getPostFormApiRequest(ApiConstants.userCreateFunction, {
          'tableName': 'enquiries',
          'act': 'edit',
          'id': enquiryId.trim(),
          'rating': rating.toString(),
          'review': review.trim(),
        });
    return _ensureSuccess(response);
  }

  String _apiTimestamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}-${two(value.month)}-${value.year} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  Map<String, dynamic> _ensureSuccess(dynamic response) {
    final json = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{'status': true, 'message': response};
    final status = json['status'];
    final isSuccess =
        status == true ||
        status?.toString() == '1' ||
        status?.toString().toLowerCase() == 'true' ||
        status?.toString() == '200';
    if (!isSuccess) {
      throw Exception(json['message']?.toString() ?? 'Enquiry not created.');
    }
    return json;
  }

  List<Map<String, dynamic>> _extractListJson(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final json = Map<String, dynamic>.from(response as Map);
    final data =
        json['data'] ??
        json['enquiries'] ??
        json['result'] ??
        json['rows'] ??
        json['message'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map) return [Map<String, dynamic>.from(data)];
    return const [];
  }

  Future<List<EnquiryModel>> _withAssignedTechnicianProgress(
    List<EnquiryModel> enquiries, {
    required String userId,
  }) async {
    if (enquiries.isEmpty) return enquiries;

    try {
      final techniciansResponse = await _apiService.getPostFormApiRequest(
        ApiConstants.userGetData,
        {'tableName': 'technician'},
      );
      final technicians = _extractListJson(
        techniciansResponse,
      ).where((row) => (row['id']?.toString() ?? '').isNotEmpty).toList();
      if (technicians.isEmpty) return enquiries;

      final enquiryIds = enquiries.map((item) => item.id).toSet();
      final assignedRows = await Future.wait(
        technicians.map((technician) async {
          final technicianId = technician['id']?.toString() ?? '';
          if (technicianId.isEmpty) return const <Map<String, dynamic>>[];
          try {
            final response = await _apiService.getPostFormApiRequest(
              ApiConstants.technicianGetAssignedEnquiries,
              {
                'technicianId': technicianId,
                'enquiryStatus': '1',
                'page': '1',
                'limit': '100',
              },
            );
            return _extractListJson(response).map((row) {
              final enriched = Map<String, dynamic>.from(row);
              enriched['_technicianId'] = technicianId;
              enriched['_technicianName'] =
                  technician['name']?.toString() ?? '';
              enriched['_technicianMobile'] =
                  technician['mobile']?.toString() ?? '';
              enriched['_technicianEmail'] =
                  technician['email']?.toString() ?? '';
              enriched['_technicianProfileImage'] =
                  technician['profileImage']?.toString() ?? '';
              return enriched;
            }).toList();
          } catch (_) {
            return const <Map<String, dynamic>>[];
          }
        }),
      );

      final assignedByEnquiryId = <String, Map<String, dynamic>>{};
      for (final rows in assignedRows) {
        for (final row in rows) {
          final id =
              row['id']?.toString() ?? row['enquiryId']?.toString() ?? '';
          final rowUserId = row['userId']?.toString() ?? '';
          if (!enquiryIds.contains(id) || rowUserId != userId) continue;
          assignedByEnquiryId[id] = row;
        }
      }

      if (assignedByEnquiryId.isEmpty) return enquiries;

      return enquiries.map((enquiry) {
        final assigned = assignedByEnquiryId[enquiry.id];
        if (assigned == null) return enquiry;
        return enquiry.copyWith(
          status: _firstString([
            assigned['status']?.toString() ?? '',
            enquiry.status,
          ]),
          technicianId: _firstString([
            assigned['technicianId']?.toString() ?? '',
            assigned['_technicianId']?.toString() ?? '',
            enquiry.technicianId,
          ]),
          technicianName: _firstString([
            assigned['technicianName']?.toString() ?? '',
            assigned['_technicianName']?.toString() ?? '',
            enquiry.technicianName,
          ]),
          technicianMobile: _firstString([
            assigned['technicianMobile']?.toString() ?? '',
            assigned['_technicianMobile']?.toString() ?? '',
            enquiry.technicianMobile,
          ]),
          technicianEmail: _firstString([
            assigned['technicianEmail']?.toString() ?? '',
            assigned['_technicianEmail']?.toString() ?? '',
            enquiry.technicianEmail,
          ]),
          technicianProfileImage: _firstString([
            assigned['technicianProfileImage']?.toString() ?? '',
            assigned['_technicianProfileImage']?.toString() ?? '',
            enquiry.technicianProfileImage,
          ]),
          technicianStatus: _firstString([
            assigned['technicianStatus']?.toString() ?? '',
            assigned['technician_status']?.toString() ?? '',
            enquiry.technicianStatus,
          ]),
        );
      }).toList();
    } catch (_) {
      return enquiries;
    }
  }

  String _firstString(List<String> values) {
    for (final value in values) {
      final text = value.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}
