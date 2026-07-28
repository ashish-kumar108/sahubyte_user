class UserAddressListRequest {
  const UserAddressListRequest({required this.userId});

  final String userId;

  Map<String, String> toJson() {
    return {'tableName': 'userAddress', 'userId': userId};
  }
}
