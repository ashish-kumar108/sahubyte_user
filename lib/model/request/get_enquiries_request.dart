class GetEnquiriesRequest {
  const GetEnquiriesRequest({
    required this.userId,
    this.page = 1,
    this.limit = 10,
  });

  final String userId;
  final int page;
  final int limit;

  Map<String, String> toJson() {
    return {
      'userId': userId,
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }
}
