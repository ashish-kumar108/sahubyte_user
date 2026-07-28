import '../data/network/api_service.dart';
import '../data/network/network_api_service.dart';
import '../model/request/login_request.dart';
import '../model/request/reset_password_request.dart';
import '../model/request/send_otp_login_request.dart';
import '../model/request/signup_otp_request.dart';
import '../model/request/signup_request.dart';
import '../model/response/auth_response.dart';
import '../res/api_constants.dart';

class AuthRepository {
  AuthRepository({BaseApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  final BaseApiService _apiService;

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userLogin,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> sendOtpLogin(SendOtpLoginRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userSendOtpLogin,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> signupOtp(SignupOtpRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userSignupOtp,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> signup(SignupRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userSignup,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResponse> resetPassword(ResetPasswordRequest request) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userCreateFunction,
      request.toFormData(),
    );
    return AuthResponse.fromJson(Map<String, dynamic>.from(response));
  }

  Future<String> findUserIdByMobile(String mobile) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      const {'tableName': 'users'},
    );
    final rows = _extractRows(response);
    final expectedMobile = mobile.replaceAll(RegExp(r'\D'), '');
    for (final row in rows) {
      final rowMobile =
          (row['mobile'] ?? row['phone'] ?? row['contactNumber'])
              ?.toString()
              .replaceAll(RegExp(r'\D'), '') ??
          '';
      if (rowMobile != expectedMobile) continue;
      return (row['id'] ?? row['userId'] ?? row['user_id'])?.toString() ?? '';
    }
    return '';
  }

  List<Map<String, dynamic>> _extractRows(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (response is! Map) return const [];
    final json = Map<String, dynamic>.from(response);
    final data = json['data'] ?? json['message'] ?? json['result'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (data is Map) return [Map<String, dynamic>.from(data)];
    return const [];
  }
}
