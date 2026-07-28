import 'package:shared_preferences/shared_preferences.dart';

class UserSessionStore {
  const UserSessionStore._();

  static const List<String> _userScopedKeys = [
    'user_id',
    'userId',
    'id',
    'name',
    'user_name',
    'fullName',
    'full_name',
    'email',
    'user_email',
    'mobile',
    'user_mobile',
    'dob',
    'state',
    'profile_state',
    'profileImage',
    'profile_image',
  ];

  static Future<void> saveLoggedInUser({
    required SharedPreferences prefs,
    required String mobile,
    required Map<String, dynamic> raw,
    String? fallbackName,
    String? fallbackEmail,
    String? fallbackDob,
  }) async {
    await clearUserScopedData(prefs);

    final user = extractUserData(raw);
    final id = _firstValue(user, const [
      'id',
      'userId',
      'user_id',
      'customerId',
      'customer_id',
    ]);
    final resolvedMobile =
        _firstValue(user, const ['mobile', 'phone', 'contactNumber']) ?? mobile;

    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('is_guest', false);
    if (id != null && id.isNotEmpty) {
      await prefs.setString('user_id', id);
    }
    await prefs.setString('mobile', resolvedMobile);

    await _setIfPresent(
      prefs,
      'name',
      _firstValue(user, const ['name', 'userName', 'fullName', 'full_name']) ??
          fallbackName,
    );
    await _setIfPresent(
      prefs,
      'email',
      _firstValue(user, const ['email', 'userEmail']) ?? fallbackEmail,
    );
    await _setIfPresent(
      prefs,
      'dob',
      _firstValue(user, const ['dob', 'dateOfBirth']) ?? fallbackDob,
    );
    final state = _firstValue(user, const ['state']);
    await _setIfPresent(prefs, 'state', state);
    await _setIfPresent(prefs, 'profile_state', state);
    await _setIfPresent(
      prefs,
      'profileImage',
      _firstValue(user, const ['profileImage', 'profile_image']),
    );
  }

  static Future<void> saveGuestSession(SharedPreferences prefs) async {
    await clearUserScopedData(prefs);
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('is_guest', true);
  }

  static Future<void> clearUserScopedData(SharedPreferences prefs) async {
    for (final key in _userScopedKeys) {
      await prefs.remove(key);
    }
  }

  static Map<String, dynamic> extractUserData(Map<String, dynamic> raw) {
    final direct = _mapFrom(raw['userData']);
    if (direct != null) return direct;

    for (final key in const ['data', 'user', 'result', 'message']) {
      final value = raw[key];
      final map = _mapFrom(value);
      if (map != null) return map;
      if (value is List && value.isNotEmpty) {
        final first = _mapFrom(value.first);
        if (first != null) return first;
      }
    }

    return raw;
  }

  static String extractUserId(Map<String, dynamic> raw) {
    final user = extractUserData(raw);
    return _firstValue(user, const [
          'id',
          'userId',
          'user_id',
          'customerId',
          'customer_id',
        ]) ??
        '';
  }

  static Map<String, dynamic>? _mapFrom(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  static Future<void> _setIfPresent(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    final cleaned = value?.trim();
    if (cleaned != null &&
        cleaned.isNotEmpty &&
        cleaned.toLowerCase() != 'null') {
      await prefs.setString(key, cleaned);
    }
  }
}
