import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/technician_supplies_view.dart';

class SelectDateTimeView extends StatefulWidget {
  const SelectDateTimeView({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.brandId,
    required this.brandName,
    required this.problemIds,
    this.problemDetails = const [],
    required this.address,
    this.problemTitle = 'Service diagnosis',
    this.problemCharge = 0,
    this.serviceType = 'Software',
  });

  final String categoryId;
  final String categoryName;
  final String subCategoryId;
  final String subCategoryName;
  final String brandId;
  final String brandName;
  final List<String> problemIds;
  final List<Map<String, dynamic>> problemDetails;
  final String address;
  final String problemTitle;
  final int problemCharge;
  final String serviceType;

  @override
  State<SelectDateTimeView> createState() => _SelectDateTimeViewState();
}

class _SelectDateTimeViewState extends State<SelectDateTimeView> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;

  final List<String> _timeSlots = [
    '09:00AM - 11:00AM',
    '11:00AM - 1:00PM',
    '01:00PM - 03:00PM',
    '03:00PM - 05:00PM',
  ];

  @override
  Widget build(BuildContext context) {
    final availableSlots = _timeSlots
        .where((slot) => !_isSlotDisabled(slot))
        .toList(growable: false);
    return Scaffold(
      appBar: const AppPageHeader(title: 'Select date and time'),
      body: Column(
        children: [
          const AppBookingHero(
            step: 6,
            totalSteps: 8,
            title: 'Pick a convenient slot',
            subtitle:
                'Choose a visit date and time. You can review the appointment before confirming.',
            icon: Icons.calendar_month_outlined,
          ),
          _buildDateSelector(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AppScreenIntro(
                      title: 'Available slots',
                      subtitle:
                          availableSlots.isEmpty && _isToday(_selectedDate)
                          ? 'Slots are not available today. Please choose another date.'
                          : 'Choose a time that works best for you.',
                      icon: Icons.schedule_rounded,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final oneColumn = constraints.maxWidth < 330;
                        final slotWidth = oneColumn
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _timeSlots.map((time) {
                            final isSelected = _selectedTime == time;
                            final isDisabled = _isSlotDisabled(time);

                            return SizedBox(
                              width: slotWidth,
                              height: 50,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedTime = time;
                                        });
                                      },
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDisabled
                                        ? AppColors.line.withValues(alpha: .35)
                                        : isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDisabled
                                          ? AppColors.line
                                          : isSelected
                                          ? Colors.transparent
                                          : AppColors.line,
                                    ),
                                  ),
                                  child: Text(
                                    time,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDisabled
                                          ? AppColors.muted.withValues(
                                              alpha: .55,
                                            )
                                          : isSelected
                                          ? Colors.white
                                          : AppColors.text,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: AppSurfaceCard(
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.success,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your selected technician will receive the visit details after confirmation.',
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.3,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppBottomAction(
            label: 'Continue',
            onPressed: _selectedTime == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TechnicianSuppliesView(
                          categoryId: widget.categoryId,
                          categoryName: widget.categoryName,
                          subCategoryId: widget.subCategoryId,
                          subCategoryName: widget.subCategoryName,
                          brandId: widget.brandId,
                          brandName: widget.brandName,
                          problemIds: widget.problemIds,
                          problemDetails: widget.problemDetails,
                          address: widget.address,
                          appointmentSlot:
                              '${_formatFullDate(_selectedDate)}, $_selectedTime',
                          problemTitle: widget.problemTitle,
                          problemCharge: widget.problemCharge,
                          serviceType: widget.serviceType,
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: InkWell(
        onTap: _openDateSheet,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF7F5FF), Color(0xFFEFFBFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120A1022),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '${_selectedDate.day}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visit date',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFullDate(_selectedDate),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDateSheet() async {
    var tempDate = _selectedDate;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                boxShadow: [
                  BoxShadow(
                    color: Color(0x260A1022),
                    blurRadius: 24,
                    offset: Offset(0, -10),
                  ),
                ],
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
                  const SizedBox(height: 16),
                  const AppScreenIntro(
                    title: 'Select visit date',
                    subtitle: 'Pick any available date from the calendar.',
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: AppColors.background,
                          onSurface: AppColors.text,
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: tempDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        onDateChanged: (date) {
                          setSheetState(() => tempDate = date);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, tempDate),
                          icon: const Text('Use this date'),
                          label: const Icon(Icons.check_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      if (_selectedTime != null && _isSlotDisabled(_selectedTime!)) {
        _selectedTime = null;
      }
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSlotDisabled(String slot) {
    if (_isToday(_selectedDate)) return true;
    return false;
  }

  String _monthName(int month) {
    return const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
  }

  String _formatFullDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${_monthName(date.month)} ${date.year}';
  }
}
