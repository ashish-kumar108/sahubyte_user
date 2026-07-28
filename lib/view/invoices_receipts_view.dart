import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/model/response/service_category_model.dart';
import 'package:sahubyte_user/model/response/user_model.dart';
import 'package:sahubyte_user/repository/enquiry_repository.dart';
import 'package:sahubyte_user/repository/profile_repository.dart';
import 'package:sahubyte_user/repository/service_catalog_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';

class InvoicesReceiptsView extends StatefulWidget {
  const InvoicesReceiptsView({super.key, required this.userId});

  final String userId;

  @override
  State<InvoicesReceiptsView> createState() => _InvoicesReceiptsViewState();
}

class _InvoicesReceiptsViewState extends State<InvoicesReceiptsView> {
  final _repository = EnquiryRepository();
  final _profileRepository = ProfileRepository();
  final _serviceCatalogRepository = ServiceCatalogRepository();
  List<EnquiryModel> _bookings = const [];
  ServiceSettingsModel? _storeSettings;
  String _customerName = '';
  bool _loading = true;
  String? _error;
  String? _creatingInvoiceId;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await _repository.getEnquiries(
        userId: widget.userId,
        page: 1,
        limit: 100,
      );
      UserModel? profile;
      try {
        profile = await _profileRepository.getUserDetail(widget.userId);
      } catch (_) {
        // Booking data remains sufficient when profile lookup is unavailable.
      }
      ServiceSettingsModel? storeSettings;
      try {
        storeSettings = await _serviceCatalogRepository.getStoreSettings();
      } catch (_) {
        // Invoice still downloads with booking data if settings are unavailable.
      }
      if (!mounted) return;
      setState(() {
        _customerName = profile?.name ?? '';
        _storeSettings = storeSettings;
        _bookings = bookings.where(_isInvoiceReady).toList()
          ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = professionalErrorMessage(
          error,
          fallback: 'Invoices could not be refreshed. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isInvoiceReady(EnquiryModel booking) {
    return booking.statusLabel == 'Completed' ||
        booking.technicianStatusLabel == 'Completed';
  }

  DateTime _dateOf(EnquiryModel booking) {
    return DateTime.tryParse(booking.createdAt.trim()) ?? DateTime(2000);
  }

  int _problemTotal(EnquiryModel booking) {
    return booking.problemItems.fold<int>(0, (total, item) {
      final raw = item['price'] ?? item['amount'];
      return total + (num.tryParse(raw?.toString() ?? '')?.round() ?? 0);
    });
  }

  int _invoiceTotal(EnquiryModel booking) {
    if (booking.totalPrice > 0) return booking.totalPrice;
    return booking.serviceFee +
        _problemTotal(booking) +
        booking.partTotalPrice +
        booking.tax;
  }

  String _customerNameFor(EnquiryModel booking) {
    final bookingName = booking.userName.trim();
    if (bookingName.isNotEmpty) return bookingName;
    final profileName = _customerName.trim();
    return profileName.isEmpty ? 'Customer' : profileName;
  }

  String _gstLabel(EnquiryModel booking) {
    final taxable =
        booking.serviceFee + _problemTotal(booking) + booking.partTotalPrice;
    if (booking.tax <= 0 || taxable <= 0) return 'GST';
    final rate = (booking.tax * 100 / taxable);
    final formatted = rate == rate.roundToDouble()
        ? rate.round().toString()
        : rate.toStringAsFixed(1);
    return 'GST ($formatted%)';
  }

  String _dateLabel(EnquiryModel booking) {
    final date = _dateOf(booking);
    if (date.year == 2000) return 'Date unavailable';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _paymentMode(EnquiryModel booking) {
    if (booking.workConfirmation.trim() == '1') {
      return 'Confirmed after customer approval';
    }
    return 'As per booking';
  }

  Future<void> _downloadInvoice(EnquiryModel booking) async {
    if (_creatingInvoiceId != null) return;
    setState(() => _creatingInvoiceId = booking.id);
    try {
      final logoBytes = await rootBundle.load('assets/sahubyte_logo.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final document = pw.Document(
        title: 'SahuByte Invoice ${booking.bookingCode}',
        author: 'SahuByte',
      );
      final problems = booking.problemItems;
      final problemTotal = _problemTotal(booking);
      final total = _invoiceTotal(booking);
      final store = _storeSettings;
      final storeName = store?.storeName.trim().isNotEmpty == true
          ? store!.storeName
          : 'SahuByte Store';
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 28),
            theme: pw.ThemeData.withFont(),
          ),
          build: (context) => [
            pw.Container(height: 5, color: PdfColors.indigo700),
            pw.SizedBox(height: 18),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 52,
                      height: 52,
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(7),
                      ),
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          storeName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 23,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo800,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('Professional technology services'),
                      ],
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'SERVICE COMPLETED',
                    style: pw.TextStyle(
                      color: PdfColors.green800,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(7),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 19,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Invoice INV-${booking.id.padLeft(6, '0')}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice date'),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _dateLabel(booking),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
                bottom: const pw.BorderSide(color: PdfColors.grey300),
              ),
              children: [
                _pdfRow('Booking ID', booking.bookingCode),
                _pdfRow('Customer name', _customerNameFor(booking)),
                _pdfRow('Payment mode', _paymentMode(booking)),
                _pdfRow('Service address', booking.address),
                _pdfRow('Service', booking.serviceTitle),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Store details',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: const pw.BorderSide(color: PdfColors.grey300),
                bottom: const pw.BorderSide(color: PdfColors.grey300),
              ),
              children: [
                _pdfRow('Store', storeName),
                _pdfRow('Location', store?.location ?? ''),
                _pdfRow('Contact number', store?.contactNumber ?? ''),
                _pdfRow('Contact email', store?.contactEmail ?? ''),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Price summary',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _pdfAmountHeader(),
            _pdfAmountRow('Service fee', booking.serviceFee),
            ...problems.map((item) {
              final name =
                  item['problemName']?.toString() ??
                  item['name']?.toString() ??
                  'Problem charge';
              final amount =
                  num.tryParse(
                    (item['price'] ?? item['amount'])?.toString() ?? '',
                  )?.round() ??
                  0;
              return _pdfAmountRow(name, amount);
            }),
            if (problems.isEmpty && problemTotal > 0)
              _pdfAmountRow('Problem charges', problemTotal),
            if (booking.partTotalPrice > 0)
              _pdfAmountRow('Parts and materials', booking.partTotalPrice),
            _pdfAmountRow(_gstLabel(booking), booking.tax),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grand total',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'INR $total',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'This computer-generated service receipt is linked to '
                '${booking.bookingCode}. Please keep it for your records.',
              ),
            ),
          ],
        ),
      );

      final root = await getDownloadsDirectory();
      final fallback = await getApplicationDocumentsDirectory();
      final directory = Directory('${(root ?? fallback).path}/SahuByte');
      if (!await directory.exists()) await directory.create(recursive: true);
      final file = File(
        '${directory.path}/SahuByte_Invoice_${booking.bookingCode}.pdf',
      );
      await file.writeAsBytes(await document.save(), flush: true);
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        _message('Invoice downloaded to ${file.path}');
      } else {
        _message('Invoice downloaded successfully.');
      }
    } catch (error) {
      if (mounted) {
        _message(
          professionalErrorMessage(
            error,
            fallback: 'Invoice could not be created. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingInvoiceId = null);
    }
  }

  pw.TableRow _pdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value.trim().isEmpty ? 'Not available' : value),
        ),
      ],
    );
  }

  pw.Widget _pdfAmountRow(String label, int amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(label)),
          pw.Text('INR $amount'),
        ],
      ),
    );
  }

  pw.Widget _pdfAmountHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Description',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Amount',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageHeader(title: 'Invoices & receipts'),
      body: _loading
          ? const _InvoiceSkeleton()
          : RefreshIndicator(
              onRefresh: _loadInvoices,
              child: _error != null || _bookings.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 90),
                        _InvoiceEmptyState(
                          isError: _error != null,
                          message:
                              _error ??
                              'Invoices appear here after a service is completed.',
                          onRefresh: _loadInvoices,
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppHeroCard(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 25,
                                backgroundColor: Color(0x22FFFFFF),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.aqua,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_bookings.length} billing record${_bookings.length == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Completed service invoices, ready when you need them.',
                                      style: TextStyle(
                                        color: Color(0xCCFFFFFF),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ..._bookings.map(_invoiceCard),
                      ],
                    ),
            ),
    );
  }

  Widget _invoiceCard(EnquiryModel booking) {
    final busy = _creatingInvoiceId == booking.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.bookingCode} · ${_dateLabel(booking)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs. ${_invoiceTotal(booking)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Billed to',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _customerNameFor(booking),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'GST invoice',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _downloadInvoice(booking),
                icon: Icon(
                  busy ? Icons.hourglass_top_rounded : Icons.download_rounded,
                ),
                label: Text(
                  busy ? 'Downloading invoice...' : 'Download invoice',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSkeleton extends StatelessWidget {
  const _InvoiceSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: List.generate(
      5,
      (index) => Container(
        height: index == 0 ? 112 : 150,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: index == 0 ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
        ),
      ),
    ),
  );
}

class _InvoiceEmptyState extends StatelessWidget {
  const _InvoiceEmptyState({
    required this.isError,
    required this.message,
    required this.onRefresh,
  });

  final bool isError;
  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      children: [
        Icon(
          isError ? Icons.cloud_off_outlined : Icons.receipt_long_outlined,
          size: 46,
          color: AppColors.muted,
        ),
        const SizedBox(height: 14),
        Text(
          isError ? 'Could not load billing history' : 'No invoices yet',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    ),
  );
}
