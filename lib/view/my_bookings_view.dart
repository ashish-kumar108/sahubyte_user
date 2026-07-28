import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/repository/enquiry_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/booking_details_view.dart';
import 'package:sahubyte_user/view/job_card_view.dart';
import 'package:sahubyte_user/view/service_review_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyBookingsView extends StatefulWidget {
  const MyBookingsView({super.key});
  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  final _repository = EnquiryRepository();
  final _scrollController = ScrollController();
  final _filters = [
    'All',
    'Awaiting',
    'Technician Assigned',
    'Completed',
    'Cancelled',
    'Expired',
    'Reallocated',
  ];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  String _userId = '';
  int _page = 1;
  static const int _limit = 10;
  List<EnquiryModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBookings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore ||
        _selectedFilter != 'All') {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      _loadNextPage();
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('user_id') ??
          prefs.getString('userId') ??
          prefs.getString('id') ??
          '';
      if (userId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _bookings = [];
          _error = 'Please login to view your bookings.';
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }
      _userId = userId;
      final bookings = await _repository.getEnquiries(
        userId: userId,
        page: _page,
        limit: _limit,
      );
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
        _hasMore = bookings.length == _limit;
      });
      _scheduleAutomaticReview(bookings);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = professionalErrorMessage(
          error,
          fallback: 'Bookings could not be refreshed. Please try again.',
        );
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  void _scheduleAutomaticReview(List<EnquiryModel> bookings) {
    for (final booking in bookings) {
      if (!reserveAutomaticReviewPrompt(booking)) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final result = await showServiceReviewSheet(context, booking: booking);
        if (!mounted || result == null) return;
        await _loadBookings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for rating your completed service.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
      break;
    }
  }

  Future<void> _loadNextPage() async {
    if (_userId.isEmpty || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final bookings = await _repository.getEnquiries(
        userId: _userId,
        page: nextPage,
        limit: _limit,
      );
      if (!mounted) return;
      final existingIds = _bookings.map((booking) => booking.id).toSet();
      setState(() {
        _page = nextPage;
        _bookings.addAll(
          bookings.where((booking) => existingIds.add(booking.id)),
        );
        _hasMore = bookings.length == _limit;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _selectedFilter == 'All'
        ? _bookings
        : _bookings
              .where((item) => item.statusLabel == _selectedFilter)
              .toList();
    return Scaffold(
      appBar: const AppPageHeader(title: 'My bookings', showBack: false),
      body: Column(
        children: [
          AppHeroCard(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0x22FFFFFF),
                      child: Icon(
                        Icons.event_note_rounded,
                        color: AppColors.aqua,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your service requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLoading
                                ? 'Syncing latest enquiries...'
                                : '${_bookings.length} bookings synced from server',
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 10.5,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading || _isLoadingMore
                          ? null
                          : _loadBookings,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BookingStat(
                        label: 'Active',
                        value: _bookings
                            .where((item) => !item.isClosed)
                            .length
                            .toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BookingStat(
                        label: 'Media',
                        value: _bookings
                            .where((item) => item.attachments.isNotEmpty)
                            .length
                            .toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BookingStat(
                        label: 'Done',
                        value: _bookings
                            .where((item) => item.statusLabel == 'Completed')
                            .length
                            .toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BookingFilterBar(
            selected: _selectedFilter,
            filters: _filters,
            onChanged: (value) => setState(() => _selectedFilter = value),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(bookings)),
        ],
      ),
    );
  }

  Widget _buildBody(List<EnquiryModel> bookings) {
    if (_isLoading) return const _BookingsSkeleton();
    if (_error != null) {
      return _refreshableEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Bookings unavailable',
        message: _error!,
      );
    }
    if (bookings.isEmpty) {
      return _refreshableEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No bookings found',
        message: _selectedFilter == 'All'
            ? 'Your enquiries will appear here after booking.'
            : 'No $_selectedFilter bookings yet.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: bookings.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (_, index) {
          if (index >= bookings.length) return const _LoadingMoreBookings();
          return _BookingCard(
            booking: bookings[index],
            onReviewSaved: _loadBookings,
          );
        },
      ),
    );
  }

  Widget _refreshableEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
          _EmptyBookings(
            icon: icon,
            title: title,
            message: message,
            onRetry: _loadBookings,
          ),
        ],
      ),
    );
  }
}

class _BookingStat extends StatelessWidget {
  const _BookingStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x1FFFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x18FFFFFF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xCCFFFFFF),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _BookingFilterBar extends StatelessWidget {
  const _BookingFilterBar({
    required this.selected,
    required this.filters,
    required this.onChanged,
  });

  final String selected;
  final List<String> filters;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final dropdownValue = filters.contains(selected) ? selected : 'All';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (selected != 'All') onChanged('All');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected == 'All' ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected == 'All' ? AppColors.primary : AppColors.line,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 17,
                    color: selected == 'All' ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'All',
                    style: TextStyle(
                      color: selected == 'All'
                          ? Colors.white
                          : AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: dropdownValue,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: filters.map((filter) {
                    return DropdownMenuItem(
                      value: filter,
                      child: _FilterDropdownLabel(
                        icon: _iconForFilter(filter),
                        label: filter == 'All' ? 'All bookings' : filter,
                        color: _colorForFilter(filter),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null || value == selected) return;
                    onChanged(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForFilter(String filter) {
    if (filter == 'Awaiting') return Icons.schedule_outlined;
    if (filter == 'Technician Assigned') return Icons.engineering_outlined;
    if (filter == 'Completed') return Icons.verified_outlined;
    if (filter == 'Cancelled') return Icons.cancel_outlined;
    if (filter == 'Expired') return Icons.timer_off_outlined;
    if (filter == 'Reallocated') return Icons.sync_problem_outlined;
    return Icons.dashboard_customize_outlined;
  }

  Color _colorForFilter(String filter) {
    if (filter == 'Awaiting') return const Color(0xFFF59E0B);
    if (filter == 'Technician Assigned') return const Color(0xFF2563EB);
    if (filter == 'Completed') return AppColors.success;
    if (filter == 'Cancelled') return const Color(0xFFE45858);
    if (filter == 'Expired') return const Color(0xFF64748B);
    if (filter == 'Reallocated') return const Color(0xFF805AD5);
    return AppColors.primary;
  }
}

class _FilterDropdownLabel extends StatelessWidget {
  const _FilterDropdownLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _LoadingMoreBookings extends StatelessWidget {
  const _LoadingMoreBookings();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14, top: 4),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: SkeletonBox(width: 16, height: 16, radius: 6),
            ),
            SizedBox(width: 10),
            Text(
              'Loading more bookings',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onReviewSaved});
  final EnquiryModel booking;
  final Future<void> Function() onReviewSaved;

  @override
  Widget build(BuildContext context) {
    final status = booking.statusLabel;
    final statusColor = _statusColor(status);
    final amount = booking.totalPrice > 0
        ? booking.totalPrice
        : booking.serviceFee + booking.tax;
    final slot = booking.dateTimeSlot.isEmpty
        ? booking.createdAt
        : booking.dateTimeSlot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppSurfaceCard(
        padding: EdgeInsets.zero,
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    AppColors.primary,
                    AppColors.aqua.withValues(alpha: .7),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookingIcon(
                        mediaCount: booking.attachments.length,
                        color: statusColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.serviceTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                height: 1.18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    slot,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _AmountBadge(amount: amount),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(label: status, color: statusColor),
                      _Pill(label: booking.bookingCode, color: AppColors.navy),
                      if (booking.attachments.isNotEmpty)
                        _Pill(
                          label: '${booking.attachments.length} media',
                          color: AppColors.aqua,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.line.withValues(alpha: .78),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                booking.address.isEmpty
                                    ? 'Visit address not set'
                                    : booking.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (booking.problemDescription.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.line.withValues(alpha: .65),
                              ),
                            ),
                            child: Text(
                              booking.problemDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobCardView(booking: booking),
                            ),
                          ),
                          icon: const Icon(
                            Icons.receipt_long_rounded,
                            size: 17,
                          ),
                          label: const Text('Job card'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  BookingDetailsView(booking: booking),
                            ),
                          ),
                          icon: const Icon(Icons.visibility_rounded, size: 17),
                          label: const Text('View details'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (status == 'Completed') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          final result = await showServiceReviewSheet(
                            context,
                            booking: booking,
                          );
                          if (result != null) await onReviewSaved();
                        },
                        icon: Icon(
                          booking.rating > 0
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        label: Text(
                          booking.rating > 0
                              ? '${booking.rating}.0 · Edit your review'
                              : 'Rate this completed service',
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF8E7),
                          foregroundColor: AppColors.text,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'Completed') return AppColors.success;
    if (status == 'Cancelled') return const Color(0xFFE45858);
    if (status == 'Expired') return const Color(0xFF64748B);
    if (status == 'Reallocated') return const Color(0xFF805AD5);
    if (status == 'Awaiting') return const Color(0xFFF59E0B);
    if (status == 'Technician Assigned') return const Color(0xFF2563EB);
    return AppColors.primary;
  }
}

class _BookingIcon extends StatelessWidget {
  const _BookingIcon({required this.mediaCount, required this.color});
  final int mediaCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.home_repair_service_rounded, color: color, size: 28),
          if (mediaCount > 0)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: .18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.perm_media_outlined,
                      color: Colors.white,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      mediaCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountBadge extends StatelessWidget {
  const _AmountBadge({required this.amount});
  final num amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
      ),
      child: Text(
        'Rs. $amount',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AppSurfaceCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 38),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingsSkeleton extends StatelessWidget {
  const _BookingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            radius: 24,
            child: Row(
              children: [
                Container(
                  width: 82,
                  height: 86,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skeletonLine(width: double.infinity),
                      const SizedBox(height: 10),
                      _skeletonLine(width: 140),
                      const SizedBox(height: 10),
                      _skeletonLine(width: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _skeletonLine({required double width}) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
