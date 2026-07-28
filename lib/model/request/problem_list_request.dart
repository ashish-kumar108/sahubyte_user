class ProblemListRequest {
  const ProblemListRequest({
    required this.categoryId,
    required this.subCategoryId,
    required this.problemIds,
  });

  final String categoryId;
  final String subCategoryId;
  final List<String> problemIds;

  Map<String, dynamic> toJson() {
    return {
      'categoryId': int.tryParse(categoryId) ?? categoryId,
      'subCategoryId': int.tryParse(subCategoryId) ?? subCategoryId,
      'problemIds': problemIds
          .map((id) => int.tryParse(id) ?? id)
          .toList(growable: false),
    };
  }
}
