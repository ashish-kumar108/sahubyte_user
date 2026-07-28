import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/repository/enquiry_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';

class ServiceReviewResult {
  const ServiceReviewResult({required this.rating, required this.review});

  final int rating;
  final String review;
}

final Set<String> _automaticReviewPrompts = <String>{};

bool reserveAutomaticReviewPrompt(EnquiryModel booking) {
  final completed =
      booking.statusLabel == 'Completed' ||
      booking.technicianStatusLabel == 'Completed';
  if (!completed || booking.rating > 0 || booking.id.trim().isEmpty) {
    return false;
  }
  return _automaticReviewPrompts.add(booking.id.trim());
}

Future<ServiceReviewResult?> showServiceReviewSheet(
  BuildContext context, {
  required EnquiryModel booking,
  EnquiryRepository? repository,
}) {
  return showModalBottomSheet<ServiceReviewResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ServiceReviewSheet(
      booking: booking,
      repository: repository ?? EnquiryRepository(),
    ),
  );
}

class _ServiceReviewSheet extends StatefulWidget {
  const _ServiceReviewSheet({required this.booking, required this.repository});

  final EnquiryModel booking;
  final EnquiryRepository repository;

  @override
  State<_ServiceReviewSheet> createState() => _ServiceReviewSheetState();
}

class _ServiceReviewSheetState extends State<_ServiceReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reviewController;
  late int _rating;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.booking.rating.clamp(0, 5);
    _reviewController = TextEditingController(text: widget.booking.review);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String get _ratingLabel => switch (_rating) {
    1 => 'Needs improvement',
    2 => 'Fair experience',
    3 => 'Good service',
    4 => 'Very good',
    5 => 'Excellent service',
    _ => 'Tap a star to rate',
  };

  Future<void> _submit() async {
    if (_rating == 0) {
      _message('Please select a star rating.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.repository.submitJobReview(
        enquiryId: widget.booking.id,
        rating: _rating,
        review: _reviewController.text,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        ServiceReviewResult(
          rating: _rating,
          review: _reviewController.text.trim(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _message(
        'Review could not be saved. Backend must add rating and review columns in enquiries.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.booking.rating > 0
                                ? 'Edit your review'
                                : 'Rate your service',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.booking.serviceTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Center(
                  child: Wrap(
                    spacing: 4,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        tooltip: '$value star${value == 1 ? '' : 's'}',
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _rating = value),
                        iconSize: 38,
                        icon: Icon(
                          value <= _rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      );
                    }),
                  ),
                ),
                Center(
                  child: Text(
                    _ratingLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _reviewController,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your review',
                    hintText:
                        'Tell us about the technician and service experience...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    final review = value?.trim() ?? '';
                    if (review.isEmpty) return 'Please write a short review.';
                    if (review.length < 5) {
                      return 'Please add a little more detail.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: _submitting
                      ? 'Saving review...'
                      : widget.booking.rating > 0
                      ? 'Update review'
                      : 'Submit review',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
