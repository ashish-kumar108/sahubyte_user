import '../data/network/api_service.dart';
import '../data/network/network_api_service.dart';
import '../model/request/problem_list_request.dart';
import '../model/request/table_data_request.dart';
import '../model/response/service_category_model.dart';
import '../model/response/service_problem_model.dart';
import '../model/response/support_faq_model.dart';
import '../res/api_constants.dart';

class ServiceCatalogRepository {
  ServiceCatalogRepository({BaseApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  final BaseApiService _apiService;

  Future<List<ServiceCategoryModel>> getCategories() async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const TableDataRequest(tableName: 'category').toJson(),
    );
    return _extractListJson(response)
        .map(ServiceCategoryModel.fromJson)
        .where((category) => category.id.isNotEmpty && category.name.isNotEmpty)
        .toList();
  }

  Future<ServiceSettingsModel> getServiceSettings({
    int fallbackServiceFee = 199,
    int fallbackTaxPercent = 18,
  }) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const TableDataRequest(tableName: 'settings').toJson(),
    );
    final rows = _extractListJson(response);
    if (rows.isEmpty) {
      return ServiceSettingsModel(
        baseServiceFee: fallbackServiceFee,
        taxPercent: fallbackTaxPercent,
      );
    }

    final settings = ServiceSettingsModel.fromJson(rows.first);
    return ServiceSettingsModel(
      baseServiceFee: settings.baseServiceFee > 0
          ? settings.baseServiceFee
          : fallbackServiceFee,
      taxPercent: settings.taxPercent > 0
          ? settings.taxPercent
          : fallbackTaxPercent,
      storeName: settings.storeName,
      location: settings.location,
      contactNumber: settings.contactNumber,
      contactEmail: settings.contactEmail,
      availableServices: settings.availableServices,
    );
  }

  Future<ServiceSettingsModel> getStoreSettings() async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const TableDataRequest(tableName: 'settings').toJson(),
    );
    final rows = _extractListJson(response);
    if (rows.isEmpty) {
      throw Exception('Store settings were not found.');
    }
    final settings = ServiceSettingsModel.fromJson(rows.first);
    if (settings.storeName.isEmpty ||
        settings.location.isEmpty ||
        settings.contactNumber.isEmpty ||
        settings.contactEmail.isEmpty ||
        settings.availableServices.isEmpty) {
      throw Exception('Store settings are incomplete.');
    }
    return settings;
  }

  Future<int> getBaseServiceFee({int fallback = 199}) async {
    final settings = await getServiceSettings(fallbackServiceFee: fallback);
    return settings.baseServiceFee;
  }

  Future<double?> getStoreAverageRating() async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const TableDataRequest(tableName: 'enquiries').toJson(),
    );
    final ratings = _extractListJson(response)
        .map((row) => double.tryParse(row['rating']?.toString() ?? ''))
        .whereType<double>()
        .where((rating) => rating > 0)
        .toList();
    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  Future<List<ServiceTestimonialModel>> getTestimonials() async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const TableDataRequest(tableName: 'testimonial').toJson(),
    );
    return _extractListJson(response)
        .map(ServiceTestimonialModel.fromJson)
        .where(
          (testimonial) =>
              testimonial.userName.isNotEmpty &&
              testimonial.description.isNotEmpty,
        )
        .toList();
  }

  Future<List<SupportFaqModel>> getFaqs() async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const TableDataRequest(tableName: 'faq').toJson(),
    );
    final faqs = _extractListJson(response)
        .map(SupportFaqModel.fromJson)
        .where((faq) => faq.title.isNotEmpty && faq.description.isNotEmpty)
        .toList();
    faqs.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      return a.id.compareTo(b.id);
    });
    return faqs;
  }

  Future<List<ServiceSubCategoryModel>> getSubCategories({
    required String categoryId,
  }) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      TableDataRequest(
        tableName: 'subCategory',
        extra: {'categoryId': categoryId},
      ).toJson(),
    );
    return _extractListJson(response)
        .map(ServiceSubCategoryModel.fromJson)
        .where(
          (subCategory) =>
              subCategory.id.isNotEmpty &&
              subCategory.name.isNotEmpty &&
              (subCategory.categoryId.isEmpty ||
                  subCategory.categoryId == categoryId),
        )
        .toList();
  }

  Future<List<ServiceBrandModel>> getBrands({
    required String categoryId,
    required String subCategoryId,
  }) async {
    final response = await _apiService
        .getPostApiRequest(ApiConstants.userGetBrands, {
          'categoryId': int.tryParse(categoryId) ?? categoryId,
          'subCategoryId': int.tryParse(subCategoryId) ?? subCategoryId,
        });
    var rows = _extractListJson(response);
    if (rows.isEmpty) {
      final fallbackResponse = await _apiService.getPostFormApiRequest(
        ApiConstants.userGetData,
        const TableDataRequest(tableName: 'brand').toJson(),
      );
      rows = _extractListJson(fallbackResponse);
    }

    return rows
        .map(ServiceBrandModel.fromJson)
        .where((brand) => brand.id.isNotEmpty && brand.name.isNotEmpty)
        .toList();
  }

  Future<List<ServiceProblemModel>> getProblems({
    required String categoryId,
    required String subCategoryId,
  }) async {
    final mappingsResponse = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      TableDataRequest(
        tableName: 'problemMapping',
        extra: {'categoryId': categoryId, 'subCategoryId': subCategoryId},
      ).toJson(),
    );
    final mappings = _extractListJson(mappingsResponse)
        .map(ProblemMappingModel.fromJson)
        .where(
          (mapping) =>
              mapping.status == '1' &&
              mapping.problemId.isNotEmpty &&
              mapping.categoryId == categoryId &&
              mapping.subCategoryId == subCategoryId,
        )
        .toList();

    final pricesByProblemId = {
      for (final mapping in mappings) mapping.problemId: mapping.price,
    };
    final problemIds = mappings.map((mapping) => mapping.problemId).toList();
    dynamic problemsResponse;
    if (problemIds.isNotEmpty) {
      problemsResponse = await _apiService.getPostApiRequest(
        ApiConstants.userGetProblems,
        ProblemListRequest(
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          problemIds: problemIds,
        ).toJson(),
      );
    } else {
      problemsResponse = await _apiService.getPostFormApiRequest(
        ApiConstants.userGetData,
        const TableDataRequest(tableName: 'problem').toJson(),
      );
    }

    final mappedProblems = _extractListJson(problemsResponse)
        .map(ServiceProblemModel.fromJson)
        .where((problem) => problem.id.isNotEmpty && problem.name.isNotEmpty)
        .map(
          (problem) =>
              problem.withFallbackPrice(pricesByProblemId[problem.id] ?? 0),
        )
        .toList();

    final allProblemsResponse = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const TableDataRequest(tableName: 'problem').toJson(),
    );
    final existingIds = mappedProblems.map((problem) => problem.id).toSet();
    final remainingProblems = _extractListJson(allProblemsResponse)
        .map(ServiceProblemModel.fromJson)
        .where(
          (problem) =>
              problem.id.isNotEmpty &&
              problem.name.isNotEmpty &&
              !existingIds.contains(problem.id),
        )
        .map(
          (problem) =>
              problem.withFallbackPrice(pricesByProblemId[problem.id] ?? 0),
        )
        .toList();

    return [...mappedProblems, ...remainingProblems];
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
        json['message'] ??
        json['result'] ??
        json['rows'] ??
        json['records'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map) return [Map<String, dynamic>.from(data)];

    return const [];
  }
}
