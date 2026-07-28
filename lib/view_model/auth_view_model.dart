import 'package:flutter/foundation.dart';

import '../model/request/login_request.dart';
import '../model/request/reset_password_request.dart';
import '../model/request/send_otp_login_request.dart';
import '../model/request/signup_otp_request.dart';
import '../model/request/signup_request.dart';
import '../model/response/auth_response.dart';
import '../repository/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository})
    : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<AuthResponse> login({
    required String mobile,
    required String password,
  }) {
    return _run(
      () => _repository.login(LoginRequest(mobile: mobile, password: password)),
    );
  }

  Future<AuthResponse> sendOtpLogin(String mobile) {
    return _run(
      () => _repository.sendOtpLogin(SendOtpLoginRequest(mobile: mobile)),
    );
  }

  Future<AuthResponse> signupOtp(String mobile) {
    return _run(() => _repository.signupOtp(SignupOtpRequest(mobile: mobile)));
  }

  Future<AuthResponse> signup({
    required String mobile,
    required String email,
    required String name,
    required String dob,
    required String password,
  }) {
    return _run(
      () => _repository.signup(
        SignupRequest(
          mobile: mobile,
          email: email,
          name: name,
          dob: dob,
          password: password,
        ),
      ),
    );
  }

  Future<AuthResponse> resetPassword({
    required String userId,
    required String password,
  }) {
    return _run(
      () => _repository.resetPassword(
        ResetPasswordRequest(userId: userId, password: password),
      ),
    );
  }

  Future<String> findUserIdByMobile(String mobile) {
    return _run(() => _repository.findUserIdByMobile(mobile));
  }

  Future<T> _run<T>(Future<T> Function() request) async {
    _setLoading(true);
    try {
      return await request();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
