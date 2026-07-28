import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/request/create_enquiry_request.dart';
import 'package:sahubyte_user/repository/enquiry_repository.dart';
import 'package:sahubyte_user/repository/service_catalog_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/login_view.dart';
import 'package:sahubyte_user/view/report_submitted_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({
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
    required this.appointmentSlot,
    required this.details,
    this.document1,
    this.document1Type,
    this.document2,
    this.document2Type,
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
  final String appointmentSlot;
  final String details;
  final String? document1;
  final String? document1Type;
  final String? document2;
  final String? document2Type;
  final String problemTitle;
  final int problemCharge;
  final String serviceType;

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _serviceCatalogRepository = ServiceCatalogRepository();
  final _enquiryRepository = EnquiryRepository();
  String _selectedPaymentMethod = 'UPI';
  int _serviceFee = 199;
  int _taxPercent = 18;
  bool _isServiceFeeLoading = true;
  bool _isSubmitting = false;

  int get _tax => (_serviceFee * (_taxPercent / 100)).round();

  int get _payNowTotal => _serviceFee + _tax;

  String get _taxTitle =>
      _isServiceFeeLoading ? 'Tax syncing' : 'Tax ($_taxPercent%)';

  @override
  void initState() {
    super.initState();
    _loadServiceFee();
  }

  Future<void> _loadServiceFee() async {
    try {
      final settings = await _serviceCatalogRepository.getServiceSettings(
        fallbackServiceFee: _serviceFee,
        fallbackTaxPercent: _taxPercent,
      );
      if (!mounted) return;
      setState(() {
        _serviceFee = settings.baseServiceFee;
        _taxPercent = settings.taxPercent;
        _isServiceFeeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isServiceFeeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageHeader(title: 'Review booking'),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadServiceFee,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: 118 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  children: [
                    const AppBookingHero(
                      step: 8,
                      totalSteps: 8,
                      title: 'Review & submit',
                      subtitle:
                          'Confirm your service details, address and payment method before submitting your enquiry.',
                      icon: Icons.receipt_long_outlined,
                    ),

                    const SizedBox(height: 14),

                    _buildServiceSummary(),

                    const SizedBox(height: 14),

                    _buildAddressCard(),

                    const SizedBox(height: 14),

                    _buildScheduleCard(),

                    const SizedBox(height: 14),

                    _buildPriceBreakdown(),

                    const SizedBox(height: 14),

                    _buildPaymentSection(),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          AppBottomAction(
            label: _isSubmitting
                ? 'Creating enquiry...'
                : _isServiceFeeLoading
                ? 'Syncing price...'
                : 'Pay Rs. $_payNowTotal',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isSubmitting || _isServiceFeeLoading
                ? null
                : _submitEnquiry,
          ),
        ],
      ),
    );
  }

  Future<void> _submitEnquiry() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('user_id') ??
        prefs.getString('userId') ??
        prefs.getString('id') ??
        '';
    if (userId.isEmpty) {
      if (!mounted) return;
      final loggedIn = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: AppColors.navyDark.withValues(alpha: .42),
        builder: (_) => const FractionallySizedBox(
          heightFactor: .92,
          child: LoginView(returnOnSuccess: true, asSheet: true),
        ),
      );
      if (!mounted || loggedIn != true) return;
      await _submitEnquiry();
      return;
    }
    if (widget.categoryId.isEmpty ||
        widget.subCategoryId.isEmpty ||
        widget.brandId.isEmpty) {
      _message('Booking selection is incomplete. Please start again.');
      return;
    }
    if (widget.problemIds.isEmpty) {
      _message('Please select at least one problem.');
      return;
    }
    if (widget.address.trim().isEmpty) {
      _message('Please select a visit address.');
      return;
    }

    setState(() => _isSubmitting = true);
    final problemDescription = widget.details.isEmpty
        ? widget.problemTitle.replaceAll('\n', ' ')
        : widget.details;
    try {
      await _enquiryRepository.createEnquiry(
        CreateEnquiryRequest(
          userId: userId,
          categoryId: widget.categoryId,
          subCategoryId: widget.subCategoryId,
          brandId: widget.brandId,
          categoryName: widget.categoryName,
          subCategoryName: widget.subCategoryName,
          brandName: widget.brandName,
          dateTimeSlot: widget.appointmentSlot,
          address: widget.address,
          serviceFee: _serviceFee,
          tax: _tax,
          totalPrice: _payNowTotal,
          details: problemDescription,
          problemIds: widget.problemIds,
          problemDescription: problemDescription,
          problemDetails: widget.problemDetails,
          document1: widget.document1,
          document1Type: widget.document1Type,
          document2: widget.document2,
          document2Type: widget.document2Type,
        ),
      );
      if (!mounted) return;
      _openSuccessScreen();
    } catch (error) {
      if (!mounted) return;
      if (_isLikelyCreateTimeout(error)) {
        final saved = await _verifyEnquiryCreated(
          userId: userId,
          problemDescription: problemDescription,
        );
        if (!mounted) return;
        if (saved) {
          _openSuccessScreen();
          return;
        }
      }
      _message(
        professionalErrorMessage(
          error,
          fallback: 'Your booking could not be submitted. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _isLikelyCreateTimeout(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('timeoutexception') ||
        text.contains('timed out') ||
        text.contains('communication error');
  }

  Future<bool> _verifyEnquiryCreated({
    required String userId,
    required String problemDescription,
  }) async {
    try {
      final enquiries = await _enquiryRepository.getEnquiries(
        userId: userId,
        page: 1,
        limit: 10,
      );
      return enquiries.any((enquiry) {
        final sameCategory = enquiry.categoryId == widget.categoryId;
        final sameSubCategory = enquiry.subCategoryId == widget.subCategoryId;
        final sameBrand = enquiry.brandId == widget.brandId;
        final sameAddress = enquiry.address.trim() == widget.address.trim();
        final sameSlot =
            widget.appointmentSlot.trim().isEmpty ||
            enquiry.dateTimeSlot.trim() == widget.appointmentSlot.trim();
        final sameDetails =
            problemDescription.trim().isEmpty ||
            enquiry.problemDescription.trim() == problemDescription.trim();
        return sameCategory &&
            sameSubCategory &&
            sameBrand &&
            sameAddress &&
            sameSlot &&
            sameDetails;
      });
    } catch (_) {
      return false;
    }
  }

  void _openSuccessScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            ReportSubmittedView(appointmentSlot: widget.appointmentSlot),
      ),
      (route) => route.isFirst,
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _buildServiceSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.serviceType,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.problemTitle.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Issue charge after job card',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _buildAddressCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Row(
          children: [
            _iconBox(Icons.location_on_outlined),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service address',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Row(
          children: [
            _iconBox(Icons.event_available_rounded),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appointment slot',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.appointmentSlot,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppScreenIntro(
              title: 'Payment summary',
              subtitle: 'Only enquiry amount is payable now.',
              icon: Icons.payments_outlined,
            ),

            const SizedBox(height: 14),

            if (_isServiceFeeLoading)
              const Column(
                children: [
                  SkeletonBox(width: double.infinity, height: 18, radius: 6),
                  SizedBox(height: 14),
                  SkeletonBox(width: double.infinity, height: 18, radius: 6),
                ],
              )
            else ...[
              _billRow('Service fee', 'Rs. $_serviceFee'),
              _billRow(_taxTitle, 'Rs. $_tax'),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.line),
            ),

            _billRow('Pay now', 'Rs. $_payNowTotal', isTotal: true),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  _pendingRow(
                    'Selected problem charge',
                    widget.problemCharge > 0
                        ? 'Rs. ${widget.problemCharge} after job card'
                        : 'After job card',
                  ),
                  _pendingRow('Parts / spare charge', 'After approval'),
                  _pendingRow('Extra service charge', 'Approval required'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppScreenIntro(
              title: 'Payment method',
              subtitle: 'Choose how you want to pay the enquiry fee.',
              icon: Icons.account_balance_wallet_outlined,
            ),

            const SizedBox(height: 12),

            _paymentOption(
              title: 'UPI',
              method: 'UPI',
              subtitle: 'Fast and secure payment',
              icon: Icons.qr_code_2_rounded,
            ),

            _paymentOption(
              title: 'Credit / Debit Card',
              method: 'Card',
              subtitle: 'Pay securely using your card',
              icon: Icons.credit_card_rounded,
            ),

            _paymentOption(
              title: 'Wallet',
              method: 'SB Wallet',
              subtitle: 'Use your wallet balance',
              icon: Icons.account_balance_wallet_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required String title,
    required String method,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == method;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: .08)
                : AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.line,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              _iconBox(icon),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.line,
                    width: isSelected ? 6 : 2,
                  ),
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _billRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.text : AppColors.muted,
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppColors.primary : AppColors.text,
              fontSize: isTotal ? 17 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.coral,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}
