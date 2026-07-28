class UserAddressModel {
  const UserAddressModel({
    required this.id,
    required this.address,
    required this.state,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String address;
  final String state;
  final String userId;
  final String createdAt;

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: json['id']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
