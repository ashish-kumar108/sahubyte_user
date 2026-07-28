class UserAddressRequest {
  const UserAddressRequest({
    required this.act,
    required this.userId,
    required this.address,
    this.state,
    this.id,
    this.createdAt,
  });

  final String act;
  final String userId;
  final String address;
  final String? state;
  final String? id;
  final String? createdAt;

  Map<String, String> toJson() {
    final payload = <String, String>{
      'tableName': 'userAddress',
      'act': act,
      'userId': userId,
      'address': address,
    };

    if (state?.isNotEmpty == true) {
      payload['state'] = state!;
    }
    if (id?.isNotEmpty == true) {
      payload['id'] = id!;
    }
    if (createdAt?.isNotEmpty == true) {
      payload['createdAt'] = createdAt!;
    }

    return payload;
  }
}
