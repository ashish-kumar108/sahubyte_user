class TableDataRequest {
  const TableDataRequest({required this.tableName, this.extra = const {}});

  final String tableName;
  final Map<String, String> extra;

  Map<String, String> toJson() {
    return {'tableName': tableName, ...extra};
  }
}
