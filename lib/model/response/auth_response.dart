class AuthResponse {
  const AuthResponse({
    this.status,
    this.success,
    this.message,
    this.otp,
    this.data,
    required this.raw,
  });

  final String? status;
  final bool? success;
  final String? message;
  final String? otp;
  final dynamic data;
  final Map<String, dynamic> raw;

  bool get isSuccess {
    if (success != null) return success!;
    return status == '200' || status?.toLowerCase() == 'success';
  }

  String get displayMessage {
    return message ??
        (isSuccess ? 'Request completed successfully.' : 'Request failed.');
  }

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status']?.toString(),
      success: _parseSuccess(json),
      message: json['message']?.toString() ?? json['msg']?.toString(),
      otp: json['otp']?.toString(),
      data: json['userData'] ?? json['data'],
      raw: json,
    );
  }

  static bool? _parseSuccess(Map<String, dynamic> json) {
    final value = json['success'] ?? json['status'];
    if (value is bool) return value;
    if (value is num) return value == 1 || value == 200 || value == 201;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' ||
          normalized == 'success' ||
          normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'error' || normalized == '0') {
        return false;
      }
    }
    return null;
  }
}
