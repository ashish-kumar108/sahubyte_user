import 'package:sahubyte_user/model/response/service_category_model.dart';

class ProblemMappingModel {
  const ProblemMappingModel({
    required this.id,
    required this.categoryId,
    required this.subCategoryId,
    required this.problemId,
    required this.price,
    required this.status,
  });

  final String id;
  final String categoryId;
  final String subCategoryId;
  final String problemId;
  final int price;
  final String status;

  factory ProblemMappingModel.fromJson(Map<String, dynamic> json) {
    return ProblemMappingModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      subCategoryId: json['subCategoryId']?.toString() ?? '',
      problemId: json['problemId']?.toString() ?? '',
      price: int.tryParse(json['price']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? '',
    );
  }
}

class ServiceProblemModel {
  const ServiceProblemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.imageCandidates,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final String image;
  final List<String> imageCandidates;

  factory ServiceProblemModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['problemImage']?.toString() ?? '';
    final candidates = imageUrlCandidates(rawImage);
    return ServiceProblemModel(
      id: json['id']?.toString() ?? '',
      name: json['problemName']?.toString() ?? '',
      description:
          json['problemDescription']?.toString() ??
          json['description']?.toString() ??
          json['details']?.toString() ??
          '',
      price: int.tryParse(json['price']?.toString() ?? '') ?? 0,
      image: candidates.isEmpty ? '' : candidates.first,
      imageCandidates: candidates,
    );
  }

  ServiceProblemModel withFallbackPrice(int fallbackPrice) {
    return ServiceProblemModel(
      id: id,
      name: name,
      description: description,
      price: price > 0 ? price : fallbackPrice,
      image: image,
      imageCandidates: imageCandidates,
    );
  }
}
