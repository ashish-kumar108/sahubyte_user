import 'package:flutter/foundation.dart';

import '../model/request/update_profile_request.dart';
import '../model/request/user_address_request.dart';
import '../model/response/auth_response.dart';
import '../model/response/user_address_model.dart';
import '../model/response/user_model.dart';
import '../repository/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<UserModel> getUserDetail(String id) {
    return _run(() => _repository.getUserDetail(id));
  }

  Future<List<UserAddressModel>> getUserAddresses(String userId) {
    return _run(() => _repository.getUserAddresses(userId));
  }

  Future<AuthResponse> updateProfile({
    required String id,
    required String name,
    required String mobile,
    required String email,
    String? dob,
    String? state,
    String? profileImageBase64,
  }) {
    return _run(
      () => _repository.updateProfile(
        UpdateProfileRequest(
          id: id,
          name: name,
          mobile: mobile,
          email: email,
          dob: dob,
          state: state,
          profileImageBase64: profileImageBase64,
        ),
      ),
    );
  }

  Future<AuthResponse> saveUserAddress({
    required String act,
    required String userId,
    required String address,
    String? state,
    String? id,
    String? createdAt,
  }) {
    return _run(
      () => _repository.saveUserAddress(
        UserAddressRequest(
          act: act,
          userId: userId,
          address: address,
          state: state,
          id: id,
          createdAt: createdAt,
        ),
      ),
    );
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
