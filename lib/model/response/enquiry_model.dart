import 'dart:convert';

import 'package:sahubyte_user/model/response/service_category_model.dart';

class EnquiryModel {
  const EnquiryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.categoryId,
    required this.subCategoryId,
    required this.brandId,
    required this.categoryName,
    required this.subCategoryName,
    required this.brandName,
    required this.dateTimeSlot,
    required this.address,
    required this.state,
    required this.serviceFee,
    required this.status,
    required this.workConfirmation,
    required this.details,
    required this.problemDetails,
    required this.tax,
    required this.totalPrice,
    required this.createdAt,
    required this.attachments,
    required this.technicianId,
    required this.technicianName,
    required this.technicianMobile,
    required this.technicianEmail,
    required this.technicianProfileImage,
    required this.technicianSkillName,
    required this.technicianStatus,
    this.partTotalPrice = 0,
    this.oldProblemPrice = 0,
    this.newProblemPrice = 0,
    this.problemAdjustmentAmount = 0,
    this.problemAdditionalAmount = 0,
    this.changedProblemName = '',
    this.paymentType = '',
    this.paymentStatus = '',
    this.rating = 0,
    this.review = '',
  });

  final String id;
  final String userId;
  final String userName;
  final String categoryId;
  final String subCategoryId;
  final String brandId;
  final String categoryName;
  final String subCategoryName;
  final String brandName;
  final String dateTimeSlot;
  final String address;
  final String state;
  final int serviceFee;
  final String status;
  final String workConfirmation;
  final String details;
  final dynamic problemDetails;
  final int tax;
  final int totalPrice;
  final String createdAt;
  final List<EnquiryAttachmentModel> attachments;
  final String technicianId;
  final String technicianName;
  final String technicianMobile;
  final String technicianEmail;
  final String technicianProfileImage;
  final String technicianSkillName;
  final String technicianStatus;
  final int partTotalPrice;
  final int oldProblemPrice;
  final int newProblemPrice;
  final int problemAdjustmentAmount;
  final int problemAdditionalAmount;
  final String changedProblemName;
  final String paymentType;
  final String paymentStatus;
  final int rating;
  final String review;

  EnquiryModel copyWith({
    String? status,
    String? workConfirmation,
    String? technicianId,
    String? technicianName,
    String? technicianMobile,
    String? technicianEmail,
    String? technicianProfileImage,
    String? technicianSkillName,
    String? technicianStatus,
    int? partTotalPrice,
    int? oldProblemPrice,
    int? newProblemPrice,
    int? problemAdjustmentAmount,
    int? problemAdditionalAmount,
    String? changedProblemName,
    String? paymentType,
    String? paymentStatus,
    int? rating,
    String? review,
  }) {
    return EnquiryModel(
      id: id,
      userId: userId,
      userName: userName,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      brandId: brandId,
      categoryName: categoryName,
      subCategoryName: subCategoryName,
      brandName: brandName,
      dateTimeSlot: dateTimeSlot,
      address: address,
      state: state,
      serviceFee: serviceFee,
      status: status ?? this.status,
      workConfirmation: workConfirmation ?? this.workConfirmation,
      details: details,
      problemDetails: problemDetails,
      tax: tax,
      totalPrice: totalPrice,
      createdAt: createdAt,
      attachments: attachments,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      technicianMobile: technicianMobile ?? this.technicianMobile,
      technicianEmail: technicianEmail ?? this.technicianEmail,
      technicianProfileImage:
          technicianProfileImage ?? this.technicianProfileImage,
      technicianSkillName: technicianSkillName ?? this.technicianSkillName,
      technicianStatus: technicianStatus ?? this.technicianStatus,
      partTotalPrice: partTotalPrice ?? this.partTotalPrice,
      oldProblemPrice: oldProblemPrice ?? this.oldProblemPrice,
      newProblemPrice: newProblemPrice ?? this.newProblemPrice,
      problemAdjustmentAmount:
          problemAdjustmentAmount ?? this.problemAdjustmentAmount,
      problemAdditionalAmount:
          problemAdditionalAmount ?? this.problemAdditionalAmount,
      changedProblemName: changedProblemName ?? this.changedProblemName,
      paymentType: paymentType ?? this.paymentType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  factory EnquiryModel.fromJson(Map<String, dynamic> json) {
    final details = json['details']?.toString() ?? '';
    final problemChange = _firstMap(json, const [
      'problemChangeDetails',
      'problemChange',
      'problem_change_details',
      'problem_change',
    ]);
    final technicianJson = _firstMap(json, const [
      'technician',
      'technicianData',
      'technicianDetail',
      'technicianDetails',
      'assignedTechnician',
      'assignedTechnicianData',
    ]);
    return EnquiryModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName:
          json['userName']?.toString() ??
          json['customerName']?.toString() ??
          json['user_name']?.toString() ??
          json['customer_name']?.toString() ??
          json['name']?.toString() ??
          '',
      categoryId: json['categoryId']?.toString() ?? '',
      subCategoryId:
          json['subCategoryId']?.toString() ??
          json['subcategoryId']?.toString() ??
          '',
      brandId: json['brandId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      subCategoryName: json['subCategoryName']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      dateTimeSlot: json['dateTimeSlot']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      serviceFee: _toInt(json['serviceFee']),
      status: json['status']?.toString() ?? '',
      workConfirmation: json['workConfirmation']?.toString() ?? '',
      details: details,
      problemDetails:
          json['problemDetails'] ??
          json['enquiryProblemDetails'] ??
          json['problems'],
      tax: _toInt(json['tax']),
      totalPrice: _toInt(json['totalPrice']),
      partTotalPrice: _toInt(
        json['partTotalPrice'] ?? json['partsTotalPrice'] ?? json['partsTotal'],
      ),
      oldProblemPrice: _toInt(
        problemChange['oldProblemPrice'] ??
            problemChange['oldProblemTotal'] ??
            problemChange['previousProblemPrice'] ??
            json['oldProblemPrice'] ??
            json['oldProblemTotal'] ??
            json['previousProblemPrice'],
      ),
      newProblemPrice: _toInt(
        problemChange['newProblemPrice'] ??
            problemChange['newProblemTotal'] ??
            problemChange['currentProblemPrice'] ??
            json['newProblemPrice'] ??
            json['newProblemTotal'] ??
            json['currentProblemPrice'],
      ),
      problemAdjustmentAmount: _toInt(
        problemChange['problemAdjustmentAmount'] ??
            problemChange['adjustmentAmount'] ??
            problemChange['adjustedAmount'] ??
            json['problemAdjustmentAmount'] ??
            json['adjustmentAmount'] ??
            json['adjustedAmount'],
      ),
      problemAdditionalAmount: _toInt(
        problemChange['problemAdditionalAmount'] ??
            problemChange['additionalAmount'] ??
            problemChange['extraAmount'] ??
            json['problemAdditionalAmount'] ??
            json['additionalAmount'] ??
            json['extraAmount'],
      ),
      changedProblemName:
          problemChange['changedProblemName']?.toString() ??
          problemChange['newProblemName']?.toString() ??
          json['changedProblemName']?.toString() ??
          json['newProblemName']?.toString() ??
          '',
      paymentType: json['paymentType']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      attachments: EnquiryAttachmentModel.fromEnquiryJson(json, details),
      technicianId: _firstString([
        _stringFrom(json, const [
          'technicianId',
          'technician_id',
          'assignedTechnicianId',
          'assigned_technician_id',
        ]),
        _stringFrom(technicianJson, const ['id', 'technicianId', 'userId']),
      ]),
      technicianName: _firstString([
        _stringFrom(json, const [
          'technicianName',
          'technician_name',
          'assignedTechnicianName',
          'assigned_technician_name',
        ]),
        _stringFrom(technicianJson, const [
          'name',
          'fullName',
          'full_name',
          'technicianName',
        ]),
      ]),
      technicianMobile: _firstString([
        _stringFrom(json, const [
          'technicianMobile',
          'technician_mobile',
          'technicianPhone',
          'technician_phone',
          'assignedTechnicianMobile',
        ]),
        _stringFrom(technicianJson, const [
          'mobile',
          'phone',
          'contact',
          'technicianMobile',
        ]),
      ]),
      technicianEmail: _firstString([
        _stringFrom(json, const ['technicianEmail', 'technician_email']),
        _stringFrom(technicianJson, const ['email', 'technicianEmail']),
      ]),
      technicianProfileImage: _firstString([
        _stringFrom(json, const [
          'technicianProfileImage',
          'technician_profile_image',
          'technicianImage',
          'technician_image',
          'assignedTechnicianImage',
        ]),
        _stringFrom(technicianJson, const [
          'profileImage',
          'profile_image',
          'image',
          'photo',
        ]),
      ]),
      technicianSkillName: _firstString([
        _stringFrom(json, const [
          'technicianSkill',
          'technicianSkillName',
          'technician_skill',
          'skillName',
          'skills',
          'expertise',
        ]),
        _stringFrom(technicianJson, const [
          'skillName',
          'skills',
          'technicianSkill',
          'expertise',
          'categoryName',
          'subCategoryName',
        ]),
      ]),
      technicianStatus: _firstString([
        _stringFrom(json, const ['technicianStatus', 'technician_status']),
        _stringFrom(technicianJson, const ['technicianStatus', 'status']),
      ]),
      rating: _toInt(json['rating']),
      review:
          json['review']?.toString() ??
          json['customerReview']?.toString() ??
          '',
    );
  }

  String get bookingCode => id.isEmpty ? 'SB-NEW' : 'SB-${id.padLeft(6, '0')}';

  String get serviceTitle {
    final parts = [
      categoryName,
      subCategoryName,
      brandName,
    ].where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Service enquiry' : parts.join(' / ');
  }

  String get statusLabel {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty || normalized == '0' || normalized == 'pending') {
      return 'Awaiting';
    }
    if (normalized == '1' ||
        normalized == 'technician assigned' ||
        normalized == 'assigned' ||
        normalized == 'accepted') {
      return 'Technician Assigned';
    }
    if (normalized == '2' ||
        normalized == 'completed' ||
        normalized == 'done') {
      return 'Completed';
    }
    if (normalized == '3' ||
        normalized == 'cancelled' ||
        normalized == 'canceled') {
      return 'Cancelled';
    }
    if (normalized == '4' || normalized == 'expired') {
      return 'Expired';
    }
    if (normalized == '5' || normalized == 'reallocated') {
      return 'Reallocated';
    }
    return status;
  }

  String get technicianStatusLabel {
    final normalized = technicianStatus.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    if (normalized == '0' || normalized == 'assigned') {
      return 'Technician Assigned';
    }
    if (normalized == '1' || normalized == 'on the way') return 'On The Way';
    if (normalized == '2' || normalized == 'arrived') return 'Arrived';
    if (normalized == '3' || normalized == 'inspection') return 'Inspection';
    if (normalized == '4' || normalized == 'job card') return 'Job Card';
    if (normalized == '5' || normalized == 'job started') return 'Job Started';
    if (normalized == '6' || normalized == 'job completed') return 'Completed';
    if (normalized == '7' || normalized == 'reallocated') return 'Reallocated';
    return technicianStatus;
  }

  String get displayStatusLabel {
    return statusLabel;
  }

  String get progressLabel {
    final technicianLabel = technicianStatusLabel;
    if (technicianLabel.isNotEmpty &&
        technicianLabel != 'Technician Assigned' &&
        statusLabel == 'Technician Assigned') {
      return technicianLabel;
    }
    return '';
  }

  bool get isClosed =>
      statusLabel == 'Completed' ||
      statusLabel == 'Cancelled' ||
      statusLabel == 'Expired' ||
      statusLabel == 'Reallocated';

  int get technicianProgressStep {
    final normalized = technicianStatus.trim().toLowerCase();
    if (normalized == '1' || normalized == 'on the way') return 2;
    if (normalized == '2' || normalized == 'arrived') return 3;
    if (normalized == '3' || normalized == 'inspection') return 4;
    if (normalized == '4' || normalized == 'job card') return 5;
    if (normalized == '5' || normalized == 'job started') return 6;
    if (normalized == '6' || normalized == 'job completed') return 7;
    if (statusLabel != 'Awaiting') return 1;
    return 0;
  }

  String get problemDescription {
    final decoded = _decodeDetails();
    final value =
        decoded['problemDescription']?.toString() ??
        decoded['description']?.toString() ??
        details;
    return value.trim();
  }

  List<Map<String, dynamic>> get problemItems {
    final value = problemDetails;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (value is Map) return [Map<String, dynamic>.from(value)];
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
        if (decoded is Map) return [Map<String, dynamic>.from(decoded)];
      } catch (_) {}
    }
    final decoded = _decodeDetails();
    final detailsProblems = decoded['problemDetails'];
    if (detailsProblems is List) {
      return detailsProblems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  String get problemSummary {
    final names = problemItems
        .map((problem) {
          return problem['problemName']?.toString() ??
              problem['name']?.toString() ??
              '';
        })
        .where((value) => value.trim().isNotEmpty)
        .toList();
    if (names.isNotEmpty) return names.join(', ');
    return problemDescription;
  }

  bool get hasAssignedTechnician =>
      statusLabel == 'Technician Assigned' ||
      technicianId.trim().isNotEmpty ||
      technicianName.trim().isNotEmpty;

  Map<String, dynamic> _decodeDetails() {
    if (details.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(details);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _firstMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String && value.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
    }
    return const {};
  }

  static String _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  static String _firstString(List<String> values) {
    for (final value in values) {
      final text = value.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }
}

class EnquiryAttachmentModel {
  const EnquiryAttachmentModel({
    required this.url,
    required this.type,
    required this.name,
  });

  final String url;
  final String type;
  final String name;

  bool get isVideo => type.toLowerCase().contains('video') || _looksVideo(url);
  bool get isImage => !isVideo;

  List<String> get imageCandidates {
    if (!isImage || url.startsWith('data:')) return const [];
    return imageUrlCandidates(url);
  }

  static List<EnquiryAttachmentModel> fromEnquiryJson(
    Map<String, dynamic> json,
    String details,
  ) {
    final items = <EnquiryAttachmentModel>[];

    void add(dynamic source, {String? type, String? name}) {
      final value = source?.toString().trim() ?? '';
      if (value.isEmpty || value.toLowerCase() == 'null') return;
      final normalizedType = (type?.trim().isNotEmpty == true
          ? type!.trim()
          : (_looksVideo(value) ? 'video' : 'image'));
      final normalizedName = name?.trim().isNotEmpty == true
          ? name!.trim()
          : _fileName(value);
      items.add(
        EnquiryAttachmentModel(
          url: value,
          type: normalizedType,
          name: normalizedName,
        ),
      );
    }

    add(
      json['document1'] ??
          json['document'] ??
          json['attachment1'] ??
          json['file1'] ??
          json['image1'],
      type:
          json['document1Type']?.toString() ??
          json['attachment1Type']?.toString(),
      name: json['document1Name']?.toString(),
    );
    add(
      json['document2'] ??
          json['attachment2'] ??
          json['file2'] ??
          json['image2'],
      type:
          json['document2Type']?.toString() ??
          json['attachment2Type']?.toString(),
      name: json['document2Name']?.toString(),
    );

    for (final key in [
      'attachments',
      'enquiriesAttachment',
      'enquiryAttachment',
      'enquiryAttachments',
      'documents',
      'files',
    ]) {
      _collectAttachmentValue(json[key], add);
    }

    if (details.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(details);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          add(map['document1'], type: map['document1Type']?.toString());
          add(map['document2'], type: map['document2Type']?.toString());
          _collectAttachmentValue(map['attachments'], add);
        }
      } catch (_) {}
    }

    final seen = <String>{};
    return items.where((item) => seen.add(item.url)).toList();
  }

  static void _collectAttachmentValue(
    dynamic value,
    void Function(dynamic source, {String? type, String? name}) add,
  ) {
    if (value == null) return;
    if (value is List) {
      for (final item in value) {
        _collectAttachmentValue(item, add);
      }
      return;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      add(
        map['document'] ??
            map['file'] ??
            map['url'] ??
            map['path'] ??
            map['attachment'] ??
            map['image'] ??
            map['video'] ??
            map['media'],
        type:
            map['type']?.toString() ??
            map['fileType']?.toString() ??
            map['documentType']?.toString(),
        name:
            map['name']?.toString() ??
            map['fileName']?.toString() ??
            map['title']?.toString(),
      );
      return;
    }
    final text = value.toString().trim();
    if (text.startsWith('[') || text.startsWith('{')) {
      try {
        _collectAttachmentValue(jsonDecode(text), add);
        return;
      } catch (_) {}
    }
    add(text);
  }

  static bool _looksVideo(String value) {
    final text = value.toLowerCase();
    return text.startsWith('data:video') ||
        text.endsWith('.mp4') ||
        text.endsWith('.mov') ||
        text.endsWith('.m4v') ||
        text.endsWith('.webm');
  }

  static String _fileName(String value) {
    if (value.startsWith('data:')) {
      return _looksVideo(value) ? 'Video' : 'Image';
    }
    final clean = value.split('?').first.split('#').first;
    final parts = clean.split('/');
    return parts.isEmpty || parts.last.trim().isEmpty
        ? 'Attachment'
        : parts.last;
  }
}
