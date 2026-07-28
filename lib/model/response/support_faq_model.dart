class SupportFaqModel {
  const SupportFaqModel({
    required this.id,
    required this.title,
    required this.description,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final int sortOrder;

  factory SupportFaqModel.fromJson(Map<String, dynamic> json) {
    return SupportFaqModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
    );
  }
}
