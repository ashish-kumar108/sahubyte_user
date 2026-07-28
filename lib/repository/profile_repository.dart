import '../data/network/api_service.dart';
import '../data/network/network_api_service.dart';
import '../model/request/update_profile_request.dart';
import '../model/request/user_address_list_request.dart';
import '../model/request/user_address_request.dart';
import '../model/request/user_detail_request.dart';
import '../model/response/auth_response.dart';
import '../model/response/user_address_model.dart';
import '../model/response/user_model.dart';
import '../res/api_constants.dart';

class ProfileRepository {
  ProfileRepository({BaseApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  final BaseApiService _apiService;

  Future<UserModel> getUserDetail(String id) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userDetail,
      UserDetailRequest(id: id).toJson(),
    );
    return UserModel.fromJson(_extractUserJson(response));
  }

  Future<AuthResponse> updateProfile(UpdateProfileRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userCreateFunction,
      request.toJson(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> saveUserAddress(UserAddressRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userCreateFunction,
      request.toJson(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<UserAddressModel>> getUserAddresses(String userId) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      UserAddressListRequest(userId: userId).toJson(),
    );
    return _extractListJson(response)
        .map((json) => UserAddressModel.fromJson(json))
        .where((address) => address.address.trim().isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _extractUserJson(dynamic response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }

    final json = Map<String, dynamic>.from(response as Map);

    // getData returns { status, data: [...] } or { status, result: [...] }
    final data = json['data'] ?? json['user'] ?? json['result'];

    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map) return Map<String, dynamic>.from(data);

    // fallback: response itself is the user object
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
        json['message'] ??
        json['result'] ??
        json['rows'] ??
        json['userAddress'];

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
