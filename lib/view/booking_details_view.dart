import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/repository/enquiry_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/invoices_receipts_view.dart';
import 'package:sahubyte_user/view/service_review_sheet.dart';
import 'package:sahubyte_user/view/widgets/assigned_technician_card.dart';

class BookingDetailsView extends StatefulWidget {
  const BookingDetailsView({super.key, required this.booking});

  final EnquiryModel booking;

  @override
  State<BookingDetailsView> createState() => _BookingDetailsViewState();
}

class _BookingDetailsViewState extends State<BookingDetailsView> {
  final _repository = EnquiryRepository();
  late EnquiryModel _booking;
  late int _rating;
  late String _review;
  bool _isRefreshingBooking = false;

  EnquiryModel get booking => _booking;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _rating = booking.rating;
    _review = booking.review;
    _refreshLatestBooking(showLoader: false);
  }

  Future<void> _refreshLatestBooking({bool showLoader = true}) async {
    final userId = booking.userId.trim();
    final bookingId = booking.id.trim();
    if (userId.isEmpty || bookingId.isEmpty) return;
    if (showLoader && mounted) {
      setState(() => _isRefreshingBooking = true);
    }
    try {
      final bookings = await _repository.getEnquiries(
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
        _rating = latest.rating;
        _review = latest.review;
      });
    } catch (_) {
      // Keep the opened booking visible if a background refresh fails.
    } finally {
      if (mounted && showLoader) setState(() => _isRefreshingBooking = false);
    }
  }

  Future<void> _openReview() async {
    final result = await showServiceReviewSheet(
      context,
      booking: booking.copyWith(rating: _rating, review: _review),
    );
    if (!mounted || result == null) return;
    setState(() {
      _rating = result.rating;
      _review = result.review;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you. Your review has been saved.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final problemCharge = _problemCharge(booking);
    final amount = booking.totalPrice > 0
        ? booking.totalPrice
        : booking.serviceFee + problemCharge + booking.tax;
    final progressStep = booking.technicianProgressStep;
    final displayStatus = booking.statusLabel;
    final progressLabel = booking.progressLabel;
    final isCompleted =
        displayStatus == 'Completed' ||
        booking.technicianStatusLabel == 'Completed';
    final effectiveProgressStep = isCompleted ? 7 : progressStep;
    bool isStepDone(int step) => isCompleted || effectiveProgressStep > step;
    bool isCurrentStep(int step) =>
        !isCompleted && effectiveProgressStep == step;
    return Scaffold(
      appBar: const AppPageHeader(title: 'Booking details'),
      body: RefreshIndicator(
        onRefresh: _refreshLatestBooking,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isRefreshingBooking) ...[
                const SkeletonInlineLoader(labelWidth: 150),
                const SizedBox(height: 12),
              ],
              AppHeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0x22FFFFFF),
                          child: Icon(
                            Icons.route_outlined,
                            color: AppColors.aqua,
                            size: 19,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          booking.bookingCode,
                          style: const TextStyle(
                            color: AppColors.aqua,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayStatus == 'Awaiting'
                          ? 'Request in progress'
                          : displayStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Your service enquiry details are synced from server.',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _InfoCard(
                title: 'Booking overview',
                icon: Icons.receipt_long_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _summaryPill(
                            'Booking ID',
                            booking.bookingCode,
                            Icons.confirmation_number_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryPill(
                            'Status',
                            displayStatus,
                            Icons.verified_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (progressLabel.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _overviewTile(
                        label: 'Technician progress',
                        value: progressLabel,
                        icon: Icons.engineering_outlined,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _overviewTile(
                      label: 'Service',
                      value: booking.serviceTitle,
                      icon: Icons.home_repair_service_outlined,
                    ),
                    const SizedBox(height: 10),
                    _overviewTile(
                      label: 'Scheduled for',
                      value: booking.dateTimeSlot.isEmpty
                          ? 'Slot not selected'
                          : booking.dateTimeSlot,
                      icon: Icons.event_available_outlined,
                    ),
                    const SizedBox(height: 14),
                    _PriceBreakdown(
                      serviceFee: booking.serviceFee,
                      problemCharge: problemCharge,
                      tax: booking.tax,
                      total: amount,
                    ),
                  ],
                ),
              ),
              if (booking.hasAssignedTechnician) ...[
                const SizedBox(height: 14),
                AssignedTechnicianCard(booking: booking),
              ],
              if (booking.problemDescription.isNotEmpty) ...[
                const SizedBox(height: 14),
                _InfoCard(
                  title: 'Problem details',
                  icon: Icons.build_circle_outlined,
                  child: Text(
                    booking.problemDescription,
                    style: const TextStyle(
                      height: 1.55,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Track progress',
                icon: Icons.timeline_rounded,
                child: Column(
                  children: [
                    _TrackingItem(
                      'Request received',
                      isStepDone(0),
                      current: isCurrentStep(0),
                    ),
                    _TrackingItem(
                      'Technician assigned',
                      isStepDone(1),
                      current: isCurrentStep(1),
                    ),
                    _TrackingItem(
                      'On the way',
                      isStepDone(2),
                      current: isCurrentStep(2),
                    ),
                    _TrackingItem(
                      'Arrived',
                      isStepDone(3),
                      current: isCurrentStep(3),
                    ),
                    _TrackingItem(
                      'Inspection',
                      isStepDone(4),
                      current: isCurrentStep(4),
                    ),
                    _TrackingItem(
                      'Job card prepared',
                      isStepDone(5),
                      current: isCurrentStep(5),
                    ),
                    _TrackingItem(
                      'Work started',
                      isStepDone(6),
                      current: isCurrentStep(6),
                    ),
                    _TrackingItem(
                      'Request completed',
                      isStepDone(7),
                      current: isCurrentStep(7),
                    ),
                    _TrackingItem('Closed', isCompleted, last: true),
                  ],
                ),
              ),
              if (isCompleted) ...[
                const SizedBox(height: 14),
                _InfoCard(
                  title: _rating > 0
                      ? 'Your service review'
                      : 'Rate this service',
                  icon: Icons.star_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 25,
                          );
                        }),
                      ),
                      if (_review.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _review,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openReview,
                        icon: Icon(
                          _rating > 0
                              ? Icons.edit_outlined
                              : Icons.rate_review_outlined,
                        ),
                        label: Text(
                          _rating > 0 ? 'Edit review' : 'Write review',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _InfoCard(
                title: 'Visit address',
                icon: Icons.location_on_outlined,
                child: Text(
                  booking.address.isEmpty
                      ? 'Visit address not available.'
                      : booking.address,
                  style: const TextStyle(height: 1.55, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Download invoice',
                icon: Icons.download_rounded,
                onPressed: () {
                  final invoiceReady =
                      displayStatus == 'Completed' ||
                      booking.technicianStatusLabel == 'Completed';
                  if (!invoiceReady) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Invoice will be available after service completion.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InvoicesReceiptsView(userId: booking.userId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryPill(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _overviewTile({
    required String label,
    required String value,
    required IconData icon,
  }) => Container(
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
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

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
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      children: [
        _PriceLine('Service fee', serviceFee, Icons.receipt_long_outlined),
        const SizedBox(height: 9),
        _PriceLine(
          'Problem charge (pay after job card)',
          problemCharge,
          Icons.task_alt,
        ),
        const SizedBox(height: 9),
        _PriceLine('Tax', tax, Icons.percent_rounded),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: Colors.white,
                size: 21,
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Paid at booking',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Rs. $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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

class _PriceLine extends StatelessWidget {
  const _PriceLine(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final display = value < 0 ? '- Rs. ${-value}' : 'Rs. $value';
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 9),
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
          display,
          style: TextStyle(
            color: value < 0 ? AppColors.success : AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sky,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1),
        ),
        child,
      ],
    ),
  );
}

class _TrackingItem extends StatelessWidget {
  const _TrackingItem(
    this.label,
    this.done, {
    this.current = false,
    this.last = false,
  });
  final String label;
  final bool done;
  final bool current;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final markerColor = done
        ? AppColors.success
        : current
        ? AppColors.primary
        : AppColors.surface;
    final borderColor = done || current ? markerColor : AppColors.line;
    final textColor = done || current ? AppColors.text : AppColors.muted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: markerColor,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15,
                    )
                  : current
                  ? const Icon(
                      Icons.radio_button_checked_rounded,
                      color: Colors.white,
                      size: 13,
                    )
                  : null,
            ),
            if (!last)
              Container(
                width: 2,
                height: 34,
                color: done
                    ? AppColors.success.withValues(alpha: .45)
                    : AppColors.line,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: current ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
