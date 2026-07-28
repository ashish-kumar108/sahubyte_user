import 'package:flutter/material.dart';
import 'package:sahubyte_user/data/network/network_api_service.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/model/response/service_category_model.dart';
import 'package:sahubyte_user/res/api_constants.dart';
import 'package:sahubyte_user/res/app_ui.dart';

class AssignedTechnicianCard extends StatefulWidget {
  const AssignedTechnicianCard({super.key, required this.booking});

  final EnquiryModel booking;

  @override
  State<AssignedTechnicianCard> createState() => _AssignedTechnicianCardState();
}

class _AssignedTechnicianCardState extends State<AssignedTechnicianCard> {
  final _apiService = NetworkApiService();
  _TechnicianInfo? _info;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _info = _TechnicianInfo.fromBooking(widget.booking);
    if (widget.booking.technicianId.isNotEmpty && _info!.isSparse) {
      _loadTechnician();
    }
  }

  @override
  void didUpdateWidget(covariant AssignedTechnicianCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id == widget.booking.id &&
        oldWidget.booking.technicianId == widget.booking.technicianId) {
      return;
    }
    _info = _TechnicianInfo.fromBooking(widget.booking);
    if (widget.booking.technicianId.isNotEmpty && _info!.isSparse) {
      _loadTechnician();
    }
  }

  Future<void> _loadTechnician() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final technicianRows = await _getTableRows('technician');
      var row = _findById(technicianRows, widget.booking.technicianId);
      if (row.isEmpty) {
        final fallbackRows = await _getTableRows('technicians');
        row = _findById(fallbackRows, widget.booking.technicianId);
      }

      var skill = '';
      try {
        skill = await _loadSkillLabel(widget.booking.technicianId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _info = _info!.merge(_TechnicianInfo.fromJson(row, skillLabel: skill));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<String> _loadSkillLabel(String technicianId) async {
    final rows = await _getTableRows('technicianSkill');
    final matching = rows.where((row) {
      final id =
          row['technicianId']?.toString() ??
          row['technician_id']?.toString() ??
          '';
      return id == technicianId;
    }).toList();
    if (matching.isEmpty) return '';

    final labels = matching
        .map((row) {
          final direct =
              row['skillName']?.toString() ??
              row['skill']?.toString() ??
              row['serviceName']?.toString() ??
              '';
          if (direct.trim().isNotEmpty) return direct.trim();

          final category =
              row['categoryName']?.toString() ??
              row['category_name']?.toString() ??
              '';
          final subCategory =
              row['subCategoryName']?.toString() ??
              row['subcategoryName']?.toString() ??
              row['sub_category_name']?.toString() ??
              '';
          return [
            category,
            subCategory,
          ].where((value) => value.trim().isNotEmpty).join(' / ');
        })
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    return labels.join(', ');
  }

  Future<List<Map<String, dynamic>>> _getTableRows(String tableName) async {
    final response = await _apiService.getPostFormApiRequest(
      ApiConstants.userGetData,
      {'tableName': tableName},
    );
    if (response is List) {
      return response
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    final json = Map<String, dynamic>.from(response as Map);
    final data =
        json['data'] ?? json['result'] ?? json['rows'] ?? json['message'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    if (data is Map) return [Map<String, dynamic>.from(data)];
    return const [];
  }

  Map<String, dynamic> _findById(
    List<Map<String, dynamic>> rows,
    String technicianId,
  ) {
    for (final row in rows) {
      final ids = [
        row['id']?.toString(),
        row['technicianId']?.toString(),
        row['technician_id']?.toString(),
        row['userId']?.toString(),
      ];
      if (ids.any((id) => id == technicianId)) return row;
    }
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final showCard = widget.booking.hasAssignedTechnician || _info!.hasContent;
    if (!showCard) return const SizedBox.shrink();

    final info = _info!;
    final name = info.name.isEmpty ? 'Technician assigned' : info.name;
    final skill = info.skillName.isNotEmpty
        ? info.skillName
        : (widget.booking.serviceTitle.isNotEmpty
              ? widget.booking.serviceTitle
              : 'Service technician');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navyDark, AppColors.navy, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                _TechnicianAvatar(
                  image: info.profileImage,
                  isLoading: _isLoading,
                  onDark: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Assigned technician',
                              style: TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                          _StatusChip(
                            icon: Icons.verified_rounded,
                            label: 'Assigned',
                            dark: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Verified Sahubyte service partner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkillPanel(skill: skill),
                if (info.mobile.isNotEmpty || info.email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (info.mobile.isNotEmpty)
                        Expanded(
                          child: _ContactChip(
                            icon: Icons.call_outlined,
                            label: info.mobile,
                          ),
                        ),
                      if (info.mobile.isNotEmpty && info.email.isNotEmpty)
                        const SizedBox(width: 8),
                      if (info.email.isNotEmpty)
                        Expanded(
                          child: _ContactChip(
                            icon: Icons.mail_outline_rounded,
                            label: info.email,
                          ),
                        ),
                    ],
                  ),
                ],
                if (_isLoading && !info.hasContent) ...[
                  const SizedBox(height: 10),
                  const SkeletonInlineLoader(labelWidth: 150),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianAvatar extends StatelessWidget {
  const _TechnicianAvatar({
    required this.image,
    required this.isLoading,
    this.onDark = false,
  });

  final String image;
  final bool isLoading;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final candidates = _profileImageCandidates(image);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: .16) : AppColors.sky,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: .22) : AppColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: isLoading && candidates.isEmpty
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: SkeletonInlineLoader(labelWidth: 100),
              ),
            )
          : (candidates.isEmpty
                ? const Icon(
                    Icons.engineering_rounded,
                    color: AppColors.primary,
                    size: 32,
                  )
                : _FallbackImage(candidates: candidates)),
    );
  }
}

class _SkillPanel extends StatelessWidget {
  const _SkillPanel({required this.skill});

  final String skill;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.sky,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.home_repair_service_outlined,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service expertise',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                skill,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: dark
          ? Colors.white.withValues(alpha: .14)
          : AppColors.success.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: dark
            ? Colors.white.withValues(alpha: .16)
            : AppColors.success.withValues(alpha: .16),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: dark ? AppColors.aqua : AppColors.success),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: dark ? Colors.white : AppColors.success,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _FallbackImage extends StatefulWidget {
  const _FallbackImage({required this.candidates});

  final List<String> candidates;

  @override
  State<_FallbackImage> createState() => _FallbackImageState();
}

class _FallbackImageState extends State<_FallbackImage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.candidates.length) {
      return const Icon(
        Icons.engineering_rounded,
        color: AppColors.primary,
        size: 32,
      );
    }
    return Image.network(
      widget.candidates[_index],
      fit: BoxFit.cover,
      headers: const {'User-Agent': 'SahubyteUserApp/1.0'},
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((duration) {
          if (mounted) setState(() => _index++);
        });
        return const Center(
          child: Icon(
            Icons.engineering_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        );
      },
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TechnicianInfo {
  const _TechnicianInfo({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.profileImage,
    required this.skillName,
  });

  final String id;
  final String name;
  final String mobile;
  final String email;
  final String profileImage;
  final String skillName;

  bool get hasContent =>
      name.isNotEmpty ||
      mobile.isNotEmpty ||
      email.isNotEmpty ||
      profileImage.isNotEmpty ||
      skillName.isNotEmpty;

  bool get isSparse =>
      name.isEmpty || profileImage.isEmpty || skillName.isEmpty;

  factory _TechnicianInfo.fromBooking(EnquiryModel booking) => _TechnicianInfo(
    id: booking.technicianId,
    name: booking.technicianName,
    mobile: booking.technicianMobile,
    email: booking.technicianEmail,
    profileImage: booking.technicianProfileImage,
    skillName: booking.technicianSkillName,
  );

  factory _TechnicianInfo.fromJson(
    Map<String, dynamic> json, {
    String skillLabel = '',
  }) => _TechnicianInfo(
    id: _first(json, const ['id', 'technicianId', 'technician_id', 'userId']),
    name: _first(json, const [
      'name',
      'fullName',
      'full_name',
      'technicianName',
    ]),
    mobile: _first(json, const [
      'mobile',
      'phone',
      'contact',
      'technicianMobile',
    ]),
    email: _first(json, const ['email', 'technicianEmail']),
    profileImage: _first(json, const [
      'profileImage',
      'profile_image',
      'technicianProfileImage',
      'image',
      'photo',
    ]),
    skillName: skillLabel.trim().isNotEmpty
        ? skillLabel.trim()
        : _first(json, const ['skillName', 'skills', 'expertise']),
  );

  _TechnicianInfo merge(_TechnicianInfo other) => _TechnicianInfo(
    id: id.isNotEmpty ? id : other.id,
    name: name.isNotEmpty ? name : other.name,
    mobile: mobile.isNotEmpty ? mobile : other.mobile,
    email: email.isNotEmpty ? email : other.email,
    profileImage: profileImage.isNotEmpty ? profileImage : other.profileImage,
    skillName: skillName.isNotEmpty ? skillName : other.skillName,
  );

  static String _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }
}

List<String> _profileImageCandidates(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return const [];
  final candidates = <String>{...imageUrlCandidates(raw)};
  if (raw.startsWith('http') && raw.contains('/sahubyte/uploads/')) {
    candidates.add(
      raw.replaceFirst('/sahubyte/uploads/', '/sahubyte/public/uploads/'),
    );
  }
  return candidates.toList();
}
