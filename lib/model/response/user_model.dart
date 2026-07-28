class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.dob,
    required this.state,
    this.profileImage,
  });

  final String id;
  final String name;
  final String email;
  final String mobile;
  final String dob;
  final String state;
  final String? profileImage;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      profileImage:
          json['profileImage']?.toString() ?? json['profile_image']?.toString(),
    );
  }
}
