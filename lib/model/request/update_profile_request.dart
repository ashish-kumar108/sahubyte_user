class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    this.dob,
    this.state,
    this.profileImageBase64,
  });

  final String id;
  final String name;
  final String mobile;
  final String email;
  final String? dob;
  final String? state;
  final String? profileImageBase64;

  Map<String, String> toJson() {
    final payload = <String, String>{
      'tableName': 'users',
      'act': 'edit',
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
    };

    if (dob?.isNotEmpty == true) {
      payload['dob'] = dob!;
    }
    if (state?.isNotEmpty == true) {
      payload['state'] = state!;
    }
    if (profileImageBase64?.isNotEmpty == true) {
      payload['folderName'] = 'userprofile';
      payload['profileImage'] = profileImageBase64!;
    }

    return payload;
  }
}
