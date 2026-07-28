import 'dart:convert';

import 'package:sahubyte_user/res/api_constants.dart';

class ServiceCategoryModel {
  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.imageCandidates,
  });

  final String id;
  final String name;
  final String image;
  final List<String> imageCandidates;

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['categoryImage']?.toString() ?? '';
    final candidates = imageUrlCandidates(rawImage);
    return ServiceCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['categoryName']?.toString() ?? '',
      image: candidates.isEmpty ? '' : candidates.first,
      imageCandidates: candidates,
    );
  }
}

class ServiceSubCategoryModel {
  const ServiceSubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.image,
    required this.imageCandidates,
  });

  final String id;
  final String categoryId;
  final String name;
  final String image;
  final List<String> imageCandidates;

  factory ServiceSubCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['subCategoryImage']?.toString() ?? '';
    final candidates = imageUrlCandidates(rawImage);
    return ServiceSubCategoryModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      name: json['subCategoryName']?.toString() ?? '',
      image: candidates.isEmpty ? '' : candidates.first,
      imageCandidates: candidates,
    );
  }
}

class ServiceBrandModel {
  const ServiceBrandModel({
    required this.id,
    required this.name,
    required this.image,
    required this.imageCandidates,
  });

  final String id;
  final String name;
  final String image;
  final List<String> imageCandidates;

  factory ServiceBrandModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['brandImage']?.toString() ?? '';
    final candidates = imageUrlCandidates(rawImage);
    return ServiceBrandModel(
      id: json['id']?.toString() ?? '',
      name: json['brandName']?.toString() ?? '',
      image: candidates.isEmpty ? '' : candidates.first,
      imageCandidates: candidates,
    );
  }
}

class ServiceSettingsModel {
  const ServiceSettingsModel({
    required this.baseServiceFee,
    required this.taxPercent,
    this.storeName = '',
    this.location = '',
    this.contactNumber = '',
    this.contactEmail = '',
    this.availableServices = const [],
  });

  final int baseServiceFee;
  final int taxPercent;
  final String storeName;
  final String location;
  final String contactNumber;
  final String contactEmail;
  final List<String> availableServices;

  factory ServiceSettingsModel.fromJson(Map<String, dynamic> json) {
    final rawFee =
        json['baseServiceFee'] ??
        json['base_service_fee'] ??
        json['serviceFee'] ??
        json['service_fee'] ??
        0;
    final rawTax =
        json['taxPercent'] ??
        json['tax_percent'] ??
        json['taxPercentage'] ??
        json['tax_percentage'] ??
        0;
    return ServiceSettingsModel(
      baseServiceFee: _parseAmount(rawFee),
      taxPercent: _parseAmount(rawTax),
      storeName: json['storeName']?.toString().trim() ?? '',
      location: json['location']?.toString().trim() ?? '',
      contactNumber: json['contactNumber']?.toString().trim() ?? '',
      contactEmail: json['contactEmail']?.toString().trim() ?? '',
      availableServices: _parseServices(json['availableService']),
    );
  }
}

class ServiceTestimonialModel {
  const ServiceTestimonialModel({
    required this.id,
    required this.userName,
    required this.userImage,
    required this.imageCandidates,
    required this.description,
    required this.rating,
  });

  final String id;
  final String userName;
  final String userImage;
  final List<String> imageCandidates;
  final String description;
  final int rating;

  factory ServiceTestimonialModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['userImage']?.toString() ?? '';
    final candidates = imageUrlCandidates(rawImage);
    return ServiceTestimonialModel(
      id: json['id']?.toString() ?? '',
      userName: json['userName']?.toString().trim() ?? '',
      userImage: candidates.isEmpty ? '' : candidates.first,
      imageCandidates: candidates,
      description: json['description']?.toString().trim() ?? '',
      rating: _parseAmount(json['rating']).clamp(0, 5),
    );
  }
}

List<String> _parseServices(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
  } catch (_) {}

  return raw
      .split(RegExp(r'[,|\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

int _parseAmount(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();

  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return 0;

  final normalized = text.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(normalized)?.round() ?? 0;
}

List<String> imageUrlCandidates(String value) {
  final path = value.trim();
  if (path.isEmpty) return const [];
  if (path.startsWith('http')) return [path];

  final sahubyteRoot = ApiConstants.userBaseUrl.replaceFirst('/userApi/', '/');
  final normalized = path.startsWith('/') ? path.substring(1) : path;

  if (normalized.startsWith('uploads/enquiries/')) {
    return <String>[
      '$sahubyteRoot$normalized',
      '${sahubyteRoot}public/$normalized',
      '${ApiConstants.userBaseUrl}$normalized',
    ];
  }

  return <String>{
    '${sahubyteRoot}public/$normalized',
    '$sahubyteRoot$normalized',
    '${ApiConstants.userBaseUrl}$normalized',
  }.toList();
}
