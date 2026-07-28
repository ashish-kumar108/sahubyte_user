import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/repository/enquiry_repository.dart';
import 'package:sahubyte_user/repository/profile_repository.dart';
import 'package:sahubyte_user/res/api_constants.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/widgets/assigned_technician_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobCardView extends StatefulWidget {
  const JobCardView({super.key, required this.booking});

  final EnquiryModel booking;

  @override
  State<JobCardView> createState() => _JobCardViewState();
}

class _JobCardViewState extends State<JobCardView> {
  String _cachedUserName = '';
  final _profileRepository = ProfileRepository();
  final _enquiryRepository = EnquiryRepository();
  late EnquiryModel _booking;
  Map<String, dynamic>? _createdJobCard;
  bool _isLoadingCreatedJobCard = true;
  bool _isApprovingJobCard = false;
  bool _isUpdatingFinalPayment = false;
  bool _jobCardApproved = false;
  bool _isRefreshingBooking = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _jobCardApproved = _booking.workConfirmation.trim() == '1';
    _loadLoggedInUserName();
    _refreshLatestBooking(showLoader: false);
    _loadCreatedJobCard();
  }

  Future<void> _refreshLatestBooking({bool showLoader = true}) async {
    final userId = _booking.userId.trim();
    final bookingId = _booking.id.trim();
    if (userId.isEmpty || bookingId.isEmpty) return;
    if (showLoader && mounted) {
      setState(() => _isRefreshingBooking = true);
    }
    try {
      final bookings = await _enquiryRepository.getEnquiries(
        userId: userId,
        page: 1,
        limit: 100,
      );
      EnquiryModel? latest;
      for (final item in bookings) {
        if (item.id.trim() == bookingId) {
          latest = item;
          break;
        }
      }
      if (!mounted || latest == null) return;
      setState(() {
        _booking = latest!;
        _jobCardApproved = latest.workConfirmation.trim() == '1';
      });
      await _loadCreatedJobCard();
    } catch (_) {
      // Keep the current job card visible if background refresh fails.
    } finally {
      if (mounted && showLoader) setState(() => _isRefreshingBooking = false);
    }
  }

  Future<void> _loadCreatedJobCard() async {
    if (_booking.id.trim().isEmpty) {
      if (mounted) setState(() => _isLoadingCreatedJobCard = false);
      return;
    }
    try {
      final jobCard = await _enquiryRepository.getJobCard(_booking.id);
      if (!mounted) return;
      setState(() {
        _createdJobCard = _hasCreatedJobCard(jobCard) ? jobCard : null;
        _isLoadingCreatedJobCard = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCreatedJobCard = false);
    }
  }

  bool _hasCreatedJobCard(Map<String, dynamic>? jobCard) {
    if (jobCard == null || jobCard.isEmpty) return false;
    final id =
        jobCard['id']?.toString().trim() ??
        jobCard['jobCardId']?.toString().trim() ??
        jobCard['enquiryId']?.toString().trim() ??
        '';
    final parts = _CreatedJobCardEstimateCard.partsFrom(jobCard);
    final details =
        jobCard['details']?.toString().trim() ??
        jobCard['description']?.toString().trim() ??
        '';
    return id.isNotEmpty || parts.isNotEmpty || details.isNotEmpty;
  }

  Future<void> _approveJobCard() async {
    final jobCard = _createdJobCard;
    if (jobCard == null) return;
    if (_booking.id.trim().isEmpty) {
      _showSnack('Booking ID is missing.');
      return;
    }
    final partsTotal = _CreatedJobCardEstimateCard.partsTotalFrom(jobCard);
    setState(() => _isApprovingJobCard = true);
    try {
      await _enquiryRepository.approveJobCard(
        enquiryId: _booking.id,
        partTotalPrice: partsTotal,
      );
      if (!mounted) return;
      setState(() => _jobCardApproved = true);
      _showSnack('Job card approved successfully.');
      await _showFinalPaymentSheet();
    } catch (error) {
      if (mounted) {
        _showSnack('Unable to approve the job card. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isApprovingJobCard = false);
    }
  }

  int get _finalPaymentAmount {
    if (_booking.totalPrice > 0) return _booking.totalPrice;
    final jobCard = _createdJobCard;
    if (jobCard == null) return 0;
    return _CreatedJobCardEstimateCard.partsTotalFrom(jobCard);
  }

  bool get _isFinalPaymentPaid =>
      _booking.paymentStatus.trim().toLowerCase() == 'paid';

  bool get _needsFinalPayment =>
      _jobCardApproved && !_isFinalPaymentPaid && _finalPaymentAmount > 0;

  Future<void> _saveFinalPayment({
    required String paymentType,
    required String paymentStatus,
  }) async {
    if (_isUpdatingFinalPayment) return;
    setState(() => _isUpdatingFinalPayment = true);
    try {
      await _enquiryRepository.updateFinalPayment(
        enquiryId: _booking.id,
        paymentType: paymentType,
        paymentStatus: paymentStatus,
      );
      if (!mounted) return;
      setState(() {
        _booking = _booking.copyWith(
          paymentType: paymentType,
          paymentStatus: paymentStatus,
        );
      });
      _showSnack(
        paymentStatus == 'paid'
            ? 'Final payment confirmed successfully.'
            : paymentType == 'online'
            ? 'Online payment selected. Waiting for gateway confirmation.'
            : 'Cash payment selected. Please pay the technician before completion.',
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Payment preference could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _isUpdatingFinalPayment = false);
    }
  }

  Future<void> _showFinalPaymentSheet() async {
    if (!_needsFinalPayment || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.navyDark.withValues(alpha: .45),
      builder: (context) => _FinalPaymentSheet(
        amount: _finalPaymentAmount,
        isSaving: _isUpdatingFinalPayment,
        onCash: () async {
          Navigator.pop(context);
          await _saveFinalPayment(
            paymentType: 'cash',
            paymentStatus: 'pending',
          );
        },
        onOnline: () async {
          Navigator.pop(context);
          await _saveFinalPayment(
            paymentType: 'online',
            paymentStatus: 'pending',
          );
        },
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _loadLoggedInUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName =
        prefs.getString('name') ??
        prefs.getString('user_name') ??
        prefs.getString('fullName') ??
        prefs.getString('full_name') ??
        '';
    if (mounted && cachedName.trim().isNotEmpty) {
      setState(() => _cachedUserName = cachedName.trim());
    }

    final loggedInUserId =
        prefs.getString('user_id') ??
        prefs.getString('userId') ??
        prefs.getString('id') ??
        '';
    if (loggedInUserId.trim().isEmpty) return;

    try {
      final user = await _profileRepository.getUserDetail(
        loggedInUserId.trim(),
      );
      if (!mounted || user.name.trim().isEmpty) return;
      await prefs.setString('name', user.name.trim());
      setState(() => _cachedUserName = user.name.trim());
    } catch (_) {
      // Keep cached name if the profile call fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final problemCharge = _problemCharge(booking);
    final amount = booking.totalPrice > 0
        ? booking.totalPrice
        : booking.serviceFee + problemCharge + booking.tax;
    final userName = booking.userName.trim().isNotEmpty
        ? booking.userName.trim()
        : _cachedUserName;
    final displayStatus = booking.statusLabel;
    final progressLabel = booking.progressLabel;
    final heroStatus = progressLabel.isNotEmpty ? progressLabel : displayStatus;
    final heroTitle = _jobHeroTitle(heroStatus);
    final heroSubtitle = _jobHeroSubtitle(heroStatus);

    return Scaffold(
      appBar: const AppPageHeader(title: 'Job card'),
      body: RefreshIndicator(
        onRefresh: _refreshLatestBooking,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isRefreshingBooking) ...[
                const SkeletonInlineLoader(labelWidth: 145),
                const SizedBox(height: 12),
              ],
              AppHeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x18FFFFFF)),
                          ),
                          child: const Icon(
                            Icons.engineering_rounded,
                            color: AppColors.aqua,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        _HeroBadge(
                          icon: Icons.confirmation_number_outlined,
                          label: booking.bookingCode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      heroTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      heroSubtitle,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroBadge(
                            icon: Icons.pending_actions_rounded,
                            label: displayStatus,
                            fullWidth: true,
                          ),
                        ),
                        if (progressLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _HeroBadge(
                              icon: Icons.engineering_outlined,
                              label: progressLabel,
                              fullWidth: true,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _HeroBadge(
                      icon: Icons.schedule_rounded,
                      label: booking.dateTimeSlot.isEmpty
                          ? booking.createdAt
                          : booking.dateTimeSlot,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _PriceSummaryCard(
                serviceFee: booking.serviceFee,
                problemCharge: problemCharge,
                tax: booking.tax,
                total: amount,
              ),
              const SizedBox(height: 14),
              if (booking.hasAssignedTechnician) ...[
                AssignedTechnicianCard(booking: booking),
                const SizedBox(height: 14),
              ],
              _JobSection(
                title: 'Visit details',
                icon: Icons.location_on_outlined,
                children: [
                  _Detail(
                    'Customer name',
                    userName.isEmpty ? '-' : userName,
                    icon: Icons.person_outline_rounded,
                    compact: true,
                  ),
                  _Detail(
                    'Address',
                    booking.address.isEmpty ? 'Not available' : booking.address,
                    icon: Icons.home_work_outlined,
                  ),
                  _Detail(
                    'Slot',
                    booking.dateTimeSlot.isEmpty ? '-' : booking.dateTimeSlot,
                    icon: Icons.event_available_outlined,
                  ),
                  _Detail(
                    'Status',
                    displayStatus,
                    icon: Icons.verified_outlined,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _JobSection(
                title: 'Service request',
                icon: Icons.build_outlined,
                children: [
                  _Detail(
                    'Enquiry ID',
                    booking.id.isEmpty ? '-' : booking.id,
                    icon: Icons.tag_rounded,
                    compact: true,
                  ),
                  _Detail(
                    'Category',
                    _join([booking.categoryName, booking.subCategoryName]),
                    icon: Icons.category_outlined,
                  ),
                  _Detail(
                    'Brand',
                    booking.brandName.isEmpty ? '-' : booking.brandName,
                    icon: Icons.devices_other_outlined,
                    compact: true,
                  ),
                  _Detail(
                    'Issue',
                    booking.problemSummary.isEmpty
                        ? '-'
                        : booking.problemSummary,
                    icon: Icons.report_problem_outlined,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              if (booking.problemItems.isNotEmpty) ...[
                const SizedBox(height: 14),
                _JobSection(
                  title: 'Selected problems',
                  icon: Icons.list_alt_rounded,
                  children: booking.problemItems.map((problem) {
                    final name =
                        problem['problemName']?.toString() ??
                        problem['name']?.toString() ??
                        'Problem';
                    final price = problem['price']?.toString() ?? '';
                    return _Detail(
                      name,
                      price.isEmpty ? '-' : 'Rs. $price',
                      icon: Icons.task_alt_rounded,
                      compact: true,
                    );
                  }).toList(),
                ),
              ],
              if (booking.attachments.isNotEmpty) ...[
                const SizedBox(height: 14),
                _JobSection(
                  title: 'Uploaded evidence',
                  icon: Icons.perm_media_outlined,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: booking.attachments.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.sizeOf(context).width < 350
                            ? 1
                            : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: MediaQuery.sizeOf(context).width < 350
                            ? 2.0
                            : 1.12,
                      ),
                      itemBuilder: (context, index) {
                        return _AttachmentTile(
                          attachment: booking.attachments[index],
                          index: index,
                        );
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              AppSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppScreenIntro(
                      title: 'Customer note',
                      subtitle: 'Problem description shared by the user.',
                      icon: Icons.notes_rounded,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        booking.problemDescription.isEmpty
                            ? 'No additional problem description available.'
                            : booking.problemDescription,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingCreatedJobCard) ...[
                const SizedBox(height: 14),
                const _JobCardWaitingCard(isLoading: true),
              ] else if (_createdJobCard != null) ...[
                const SizedBox(height: 14),
                _CreatedJobCardEstimateCard(
                  jobCard: _createdJobCard!,
                  isApproving: _isApprovingJobCard,
                  isApproved: _jobCardApproved,
                  onApprove: _approveJobCard,
                ),
                if (_jobCardApproved) ...[
                  const SizedBox(height: 14),
                  _FinalPaymentCard(
                    amount: _finalPaymentAmount,
                    paymentType: _booking.paymentType,
                    paymentStatus: _booking.paymentStatus,
                    isUpdating: _isUpdatingFinalPayment,
                    onChoosePayment: _showFinalPaymentSheet,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _join(List<String> values) {
    final parts = values.where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? '-' : parts.join(' / ');
  }

  int _problemCharge(EnquiryModel booking) {
    var total = 0;
    for (final problem in booking.problemItems) {
      final raw = problem['price'];
      if (raw is int) {
        total += raw;
        continue;
      }
      if (raw is num) {
        total += raw.round();
        continue;
      }
      final text = raw?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
      total += double.tryParse(text)?.round() ?? 0;
    }
    return total;
  }

  String _jobHeroTitle(String status) {
    if (status == 'Awaiting') return 'Technician not assigned yet';
    if (status == 'Technician Assigned') return 'Technician assigned';
    if (status == 'On The Way') return 'Technician on the way';
    if (status == 'Arrived') return 'Technician arrived';
    if (status == 'Inspection') return 'Inspection in progress';
    if (status == 'Job Card') return 'Job card prepared';
    if (status == 'Job Started') return 'Work started';
    if (status == 'Completed') return 'Service completed';
    if (status == 'Cancelled') return 'Booking cancelled';
    if (status == 'Expired') return 'Booking expired';
    if (status == 'Reallocated') return 'Technician reallocated';
    return status;
  }

  String _jobHeroSubtitle(String status) {
    if (status == 'Awaiting') {
      return 'We will update this card as soon as a technician accepts your request.';
    }
    if (status == 'Technician Assigned') {
      return 'A technician has accepted your enquiry and will follow the appointment slot.';
    }
    if (status == 'On The Way') {
      return 'Your technician is travelling to the service address.';
    }
    if (status == 'Arrived') {
      return 'Your technician has reached the visit location.';
    }
    if (status == 'Inspection') {
      return 'The technician is inspecting the issue and preparing the next step.';
    }
    if (status == 'Job Card') {
      return 'The technician has prepared the job card for this visit.';
    }
    if (status == 'Job Started') {
      return 'Repair work has started for your service request.';
    }
    if (status == 'Completed') {
      return 'Your service request has been marked completed.';
    }
    if (status == 'Cancelled') {
      return 'This service enquiry has been cancelled.';
    }
    if (status == 'Expired') return 'This enquiry is no longer active.';
    if (status == 'Reallocated') {
      return 'Your request has been reallocated for further technician assignment.';
    }
    return 'Your service enquiry details are synced from server.';
  }
}

class _JobCardWaitingCard extends StatelessWidget {
  const _JobCardWaitingCard({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(16),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SkeletonInlineLoader(labelWidth: 120),
                  )
                : const Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checking job card',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Estimate will appear here after technician creates it.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatedJobCardEstimateCard extends StatelessWidget {
  const _CreatedJobCardEstimateCard({
    required this.jobCard,
    required this.onApprove,
    required this.isApproving,
    required this.isApproved,
  });

  final Map<String, dynamic> jobCard;
  final VoidCallback onApprove;
  final bool isApproving;
  final bool isApproved;

  static List<Map<String, dynamic>> partsFrom(Map<String, dynamic> jobCard) {
    final source = jobCard['parts'] ?? jobCard['part'] ?? jobCard['items'];
    dynamic parsed = source;
    if (source is String && source.trim().isNotEmpty) {
      try {
        parsed = jsonDecode(source);
      } catch (_) {}
    }
    if (parsed is! List) return const [];
    return parsed
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => _first(item, const ['partName', 'name']).isNotEmpty)
        .toList();
  }

  static String _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  static Map<String, dynamic> detailsJson(Map<String, dynamic> jobCard) {
    final raw =
        jobCard['details']?.toString().trim() ??
        jobCard['description']?.toString().trim() ??
        '';
    if (raw.isEmpty) return const {};
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return const {};
  }

  static String detailsFrom(Map<String, dynamic> jobCard) {
    final parsed = detailsJson(jobCard);
    final note =
        parsed['technicianObservation'] ??
        parsed['technicianNote'] ??
        parsed['observation'] ??
        parsed['problemDescription'] ??
        parsed['details'] ??
        parsed['description'];
    if (note != null && note.toString().trim().isNotEmpty) {
      return note.toString().trim();
    }
    return jobCard['details']?.toString().trim() ??
        jobCard['description']?.toString().trim() ??
        '';
  }

  static List<String> selectedIssuesFrom(Map<String, dynamic> jobCard) {
    final source =
        detailsJson(jobCard)['selectedIssues'] ??
        detailsJson(jobCard)['issues'];
    if (source is! List) return const [];
    return source
        .map((item) => item.toString().trim())
        .map(_cleanIssueName)
        .where((item) => item.isNotEmpty && item.toLowerCase() != 'null')
        .toList();
  }

  static String _cleanIssueName(String value) {
    return value
        .replaceFirst(RegExp(r'^Initial\s+Complaint\s*:\s*'), '')
        .trim();
  }

  static int _price(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final text = raw?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '';
    return double.tryParse(text)?.round() ?? 0;
  }

  static bool _bool(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    return value == 'true' || value == '1' || value == 'yes';
  }

  static int partsTotalFrom(Map<String, dynamic> jobCard) {
    final currentProblemPrice = currentProblemPriceFrom(jobCard);
    if (currentProblemPrice > 0) {
      return partsOnlyTotalFrom(jobCard) + currentProblemPrice;
    }
    final approvalEstimate = _price(
      detailsJson(jobCard)['approvalEstimate'] ??
          detailsJson(jobCard)['estimateTotal'],
    );
    if (approvalEstimate > 0) return approvalEstimate;
    return partsFrom(jobCard).fold<int>(
      0,
      (sum, item) => sum + _price(item['price'] ?? item['amount']),
    );
  }

  static int partsOnlyTotalFrom(Map<String, dynamic> jobCard) {
    return partsFrom(jobCard).fold<int>(
      0,
      (sum, item) => sum + _price(item['price'] ?? item['amount']),
    );
  }

  static int currentProblemPriceFrom(Map<String, dynamic> jobCard) {
    final details = detailsJson(jobCard);
    final change = details['problemChange'];
    return _price(
      details['problemCharge'] ??
          details['newProblemPrice'] ??
          (change is Map
              ? change['newProblemPrice'] ?? change['currentProblemPrice']
              : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parts = partsFrom(jobCard);
    final details = detailsFrom(jobCard);
    final selectedIssues = selectedIssuesFrom(jobCard);
    final issueChanged = _bool(detailsJson(jobCard)['issueChanged']);
    final approvalEstimate = partsTotalFrom(jobCard);
    final partsTotal = partsOnlyTotalFrom(jobCard);
    final currentProblemPrice = currentProblemPriceFrom(jobCard);
    final total = _price(
      jobCard['totalPrice'] ?? jobCard['total'] ?? jobCard['amount'],
    );
    final displayTotal = total > 0 ? total : approvalEstimate;
    final alreadyApproved =
        isApproved ||
        _first(jobCard, const [
              'approvalStatus',
              'userApproval',
              'isApproved',
              'approved',
              'status',
            ]).toLowerCase() ==
            'approved' ||
        _first(jobCard, const ['userApproval', 'isApproved', 'approved']) ==
            '1';

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: 26,
      color: const Color(0xFFF5F3FF),
      borderColor: const Color(0xFFD9D4FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technician estimate ready',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Review job card parts and visit notes.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                details,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (issueChanged && selectedIssues.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_outlined,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Technician updated the diagnosis',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...selectedIssues.map(
                          (issue) => Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 7),
                                  child: Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    issue,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (parts.isEmpty)
            const Text(
              'No parts are required for this job card.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            ...parts.map((part) {
              final name = _first(part, const ['partName', 'name']);
              final price = _price(part['price'] ?? part['amount']);
              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Rs. $price',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          _AdjustmentLine(label: 'Parts total', value: partsTotal),
          const SizedBox(height: 7),
          _AdjustmentLine(
            label: 'Current problem charge',
            value: currentProblemPrice,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: .28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.success,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval amount',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Confirm this estimate to start the work.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs. $displayTotal',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: alreadyApproved
                ? 'Job Card Approved'
                : (isApproving ? 'Approving...' : 'Approve Job Card'),
            icon: alreadyApproved
                ? Icons.verified_rounded
                : Icons.check_circle_outline_rounded,
            onPressed: alreadyApproved || isApproving ? null : onApprove,
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _AdjustmentLine extends StatelessWidget {
  const _AdjustmentLine({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final display = value < 0 ? '- Rs. ${-value}' : 'Rs. $value';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          display,
          style: TextStyle(
            color: value < 0 ? AppColors.success : AppColors.text,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FinalPaymentCard extends StatelessWidget {
  const _FinalPaymentCard({
    required this.amount,
    required this.paymentType,
    required this.paymentStatus,
    required this.isUpdating,
    required this.onChoosePayment,
  });

  final int amount;
  final String paymentType;
  final String paymentStatus;
  final bool isUpdating;
  final VoidCallback onChoosePayment;

  bool get _paid => paymentStatus.trim().toLowerCase() == 'paid';
  bool get _cashPending =>
      paymentType.trim().toLowerCase() == 'cash' &&
      paymentStatus.trim().toLowerCase() != 'paid';
  bool get _onlinePending =>
      paymentType.trim().toLowerCase() == 'online' &&
      paymentStatus.trim().toLowerCase() != 'paid';

  @override
  Widget build(BuildContext context) {
    final title = _paid
        ? 'Final payment paid'
        : _cashPending
        ? 'Cash payment pending'
        : _onlinePending
        ? 'Online payment pending'
        : 'Final payment required';
    final subtitle = _paid
        ? 'The job-card amount has been confirmed.'
        : _cashPending
        ? 'Pay Rs. $amount in cash to the technician before completion.'
        : _onlinePending
        ? 'Waiting for secure gateway confirmation.'
        : 'Choose online or cash payment before the job is completed.';
    final icon = _paid
        ? Icons.verified_rounded
        : _cashPending
        ? Icons.payments_outlined
        : Icons.account_balance_wallet_outlined;
    final color = _paid
        ? AppColors.success
        : _cashPending
        ? AppColors.coral
        : AppColors.primary;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payable amount',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Rs. $amount',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (!_paid) ...[
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: isUpdating ? 'Saving payment...' : 'Choose payment',
              icon: Icons.arrow_forward_rounded,
              onPressed: isUpdating ? null : onChoosePayment,
            ),
          ],
        ],
      ),
    );
  }
}

class _FinalPaymentSheet extends StatelessWidget {
  const _FinalPaymentSheet({
    required this.amount,
    required this.isSaving,
    required this.onCash,
    required this.onOnline,
  });

  final int amount;
  final bool isSaving;
  final Future<void> Function() onCash;
  final Future<void> Function() onOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const AppScreenIntro(
            title: 'Complete final payment',
            subtitle:
                'This amount includes approved problem changes and selected parts only.',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .18),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Final payable',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'Rs. $amount',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: isSaving ? 'Processing...' : 'Pay online',
            icon: Icons.language_rounded,
            onPressed: isSaving ? null : onOnline,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : onCash,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Pay cash to technician'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.index});

  final EnquiryAttachmentModel attachment;
  final int index;

  @override
  Widget build(BuildContext context) {
    final label = attachment.isVideo ? 'Video' : 'Photo';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openAttachment(context),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (attachment.isImage)
                  _EvidenceImage(attachment: attachment)
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.navy, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                Positioned(
                  left: 9,
                  top: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$label ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 9,
                  top: 9,
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      attachment.isVideo
                          ? Icons.play_arrow_rounded
                          : Icons.open_in_full_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  right: 9,
                  bottom: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .90),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAttachment(BuildContext context) async {
    if (attachment.isImage) {
      _showImagePreview(context);
      return;
    }

    if (attachment.url.startsWith('data:video')) {
      await _openDataVideo(context);
      return;
    }

    final url = _resolvedAttachmentUrl();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _showError(context, 'Attachment URL is not valid.');
      return;
    }
    await _openRemoteVideo(context, uri);
  }

  Future<void> _openRemoteVideo(BuildContext context, Uri uri) async {
    try {
      final response = await http
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Video download failed.');
      }
      final dir = await getTemporaryDirectory();
      final extension = _extensionFromPath(uri.path);
      final file = File(
        '${dir.path}/sahubyte_video_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        _showError(context, 'Unable to open video.');
      }
    } catch (_) {
      if (context.mounted) _showError(context, 'Unable to open video.');
    }
  }

  Future<void> _openDataVideo(BuildContext context) async {
    try {
      final commaIndex = attachment.url.indexOf(',');
      if (commaIndex == -1) throw const FormatException('Invalid video data.');
      final bytes = base64Decode(attachment.url.substring(commaIndex + 1));
      final dir = await getTemporaryDirectory();
      final extension = _videoExtension();
      final file = File(
        '${dir.path}/sahubyte_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        _showError(context, 'Unable to open video.');
      }
    } catch (_) {
      if (context.mounted) _showError(context, 'Unable to open video.');
    }
  }

  String _videoExtension() {
    final header = attachment.url
        .split(',')
        .first
        .toLowerCase()
        .replaceAll('data:', '');
    if (header.contains('webm')) return 'webm';
    if (header.contains('quicktime') || header.contains('mov')) return 'mov';
    if (header.contains('m4v')) return 'm4v';
    return 'mp4';
  }

  String _extensionFromPath(String path) {
    final value = path.toLowerCase();
    if (value.endsWith('.webm')) return 'webm';
    if (value.endsWith('.mov')) return 'mov';
    if (value.endsWith('.m4v')) return 'm4v';
    return 'mp4';
  }

  void _showImagePreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .90),
      builder: (context) {
        final image = attachment.url.startsWith('data:image')
            ? Image.memory(
                base64Decode(attachment.url.split(',').last),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 52,
                ),
              )
            : _PreviewNetworkImage(urls: _resolvedImageUrls());
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: .7,
                    maxScale: 4,
                    child: Center(child: image),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _resolvedImageUrls() {
    final candidates = attachment.imageCandidates;
    if (candidates.isNotEmpty) return candidates;
    final resolvedUrl = _resolvedAttachmentUrl();
    return resolvedUrl.isEmpty ? const [] : [resolvedUrl];
  }

  String _resolvedAttachmentUrl() {
    final value = attachment.url.trim();
    if (value.isEmpty ||
        value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:')) {
      return value;
    }
    final root = ApiConstants.userBaseUrl.replaceFirst('/userApi/', '/');
    final normalized = value
        .replaceAll('\\', '/')
        .replaceFirst(RegExp(r'^/+'), '');
    if (normalized.startsWith('public/')) return '$root$normalized';
    if (normalized.startsWith('uploads/enquiries/')) return '$root$normalized';
    if (normalized.startsWith('uploads/')) return '${root}public/$normalized';
    return '${root}public/uploads/$normalized';
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _PreviewNetworkImage extends StatefulWidget {
  const _PreviewNetworkImage({required this.urls});

  final List<String> urls;

  @override
  State<_PreviewNetworkImage> createState() => _PreviewNetworkImageState();
}

class _PreviewNetworkImageState extends State<_PreviewNetworkImage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return const Icon(
        Icons.broken_image_outlined,
        color: Colors.white,
        size: 52,
      );
    }

    return Image.network(
      widget.urls[_index],
      fit: BoxFit.contain,
      headers: const {'User-Agent': 'Mozilla/5.0'},
      errorBuilder: (context, error, stackTrace) {
        if (_index < widget.urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index++);
          });
          return const SkeletonBox(width: 40, height: 40, radius: 12);
        }
        return const Icon(
          Icons.broken_image_outlined,
          color: Colors.white,
          size: 52,
        );
      },
    );
  }
}

class _EvidenceImage extends StatefulWidget {
  const _EvidenceImage({required this.attachment});

  final EnquiryAttachmentModel attachment;

  @override
  State<_EvidenceImage> createState() => _EvidenceImageState();
}

class _EvidenceImageState extends State<_EvidenceImage> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _EvidenceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.url != widget.attachment.url) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final dataUri = widget.attachment.url;
    if (dataUri.startsWith('data:image')) {
      final commaIndex = dataUri.indexOf(',');
      if (commaIndex != -1) {
        try {
          return Image.memory(
            base64Decode(dataUri.substring(commaIndex + 1)),
            fit: BoxFit.cover,
          );
        } catch (_) {}
      }
    }

    final urls = widget.attachment.imageCandidates;
    if (urls.isEmpty) return const _EvidencePlaceholder();
    return Image.network(
      urls[_index],
      fit: BoxFit.cover,
      headers: const {'User-Agent': 'Mozilla/5.0'},
      errorBuilder: (context, error, stackTrace) {
        if (_index < urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index++);
          });
          return const _EvidencePlaceholder();
        }
        return const _EvidencePlaceholder();
      },
    );
  }
}

class _EvidencePlaceholder extends StatelessWidget {
  const _EvidencePlaceholder();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFEDEBFF), Color(0xFFF8FAFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Icon(Icons.image_outlined, color: AppColors.primary, size: 34),
    ),
  );
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => Container(
    width: fullWidth ? double.infinity : null,
    constraints: fullWidth ? null : const BoxConstraints(maxWidth: 150),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0x1FFFFFFF),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0x18FFFFFF)),
    ),
    child: Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.aqua, size: 15),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label.isEmpty ? '-' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PriceSummaryCard extends StatelessWidget {
  const _PriceSummaryCard({
    required this.serviceFee,
    required this.problemCharge,
    required this.tax,
    required this.total,
  });

  final int serviceFee;
  final int problemCharge;
  final int tax;
  final int total;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _PriceIcon(
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment breakdown',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Transparent charges for this enquiry',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PriceRow(
            label: 'Service fee',
            value: serviceFee,
            icon: Icons.miscellaneous_services_outlined,
          ),
          const SizedBox(height: 9),
          _PriceRow(
            label: 'Problem charge (job-card stage)',
            value: problemCharge,
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 9),
          _PriceRow(label: 'Tax', value: tax, icon: Icons.percent_rounded),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Paid at booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'Rs. $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _PriceIcon(icon: icon, color: AppColors.primary),
      const SizedBox(width: 11),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      Text(
        'Rs. $value',
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _PriceIcon extends StatelessWidget {
  const _PriceIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

class _JobSection extends StatelessWidget {
  const _JobSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppScreenIntro(title: title, icon: icon),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1),
        ),
        ...children,
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(
    this.label,
    this.value, {
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: compact ? 1 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
