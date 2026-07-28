import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/checkout_view.dart';

class TechnicianSuppliesView extends StatefulWidget {
  const TechnicianSuppliesView({
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
  final String problemTitle;
  final int problemCharge;
  final String serviceType;

  @override
  State<TechnicianSuppliesView> createState() => _TechnicianSuppliesViewState();
}

class _TechnicianSuppliesViewState extends State<TechnicianSuppliesView> {
  final TextEditingController _taskController = TextEditingController();
  int _charCount = 0;
  bool _isPickingAttachment = false;
  final List<_EnquiryAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _taskController.addListener(() {
      setState(() {
        _charCount = _taskController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const AppPageHeader(title: 'Describe the task', showCart: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: keyboard > 0 ? 20 : 0),
              child: Column(
                children: [
                  const AppBookingHero(
                    step: 7,
                    totalSteps: 8,
                    title: 'Tell us what’s needed',
                    subtitle:
                        'Add a short note so the technician can prepare the right tools before arrival.',
                    icon: Icons.edit_note_rounded,
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppScreenIntro(
                            title: 'Task details',
                            subtitle:
                                'Mention the issue, model, error message, or anything important.',
                            icon: Icons.description_outlined,
                          ),

                          const SizedBox(height: 18),

                          Container(
                            height: 140,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _taskController,
                                    maxLength: 150,
                                    maxLines: null,
                                    expands: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Example: Laptop is not turning on, screen is blank, or Wi-Fi is not working...',
                                      hintStyle: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      counterText: '',
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '$_charCount/150',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          const AppFieldLabel('Attachment'),

                          const SizedBox(height: 12),

                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _isPickingAttachment
                                ? null
                                : _pickAttachments,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: .12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.cloud_upload_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _attachments.isEmpty
                                              ? 'Upload photo or video'
                                              : '${_attachments.length} attachment selected',
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _isPickingAttachment
                                              ? 'Preparing file...'
                                              : 'Optional, max 2 image/video files',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _isPickingAttachment
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: SkeletonBox(
                                            width: 18,
                                            height: 18,
                                            radius: 6,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: AppColors.muted,
                                        ),
                                ],
                              ),
                            ),
                          ),

                          if (_attachments.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ..._attachments.asMap().entries.map((entry) {
                              final attachment = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.sky,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        attachment.type == 'video'
                                            ? Icons.videocam_outlined
                                            : Icons.image_outlined,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          attachment.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => setState(
                                          () =>
                                              _attachments.removeAt(entry.key),
                                        ),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: AppColors.muted,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 16),

                          const Text(
                            'Clear details help the technician prepare better.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          AppBottomAction(
            label: 'Review booking',
            secondaryLabel: 'Back',
            onSecondaryPressed: () => Navigator.pop(context),
            onPressed: () {
              FocusScope.of(context).unfocus();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutView(
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryName,
                    subCategoryId: widget.subCategoryId,
                    subCategoryName: widget.subCategoryName,
                    brandId: widget.brandId,
                    brandName: widget.brandName,
                    problemIds: widget.problemIds,
                    problemDetails: widget.problemDetails,
                    address: widget.address,
                    appointmentSlot: widget.appointmentSlot,
                    details: _taskController.text.trim(),
                    document1: _attachments.isNotEmpty
                        ? _attachments[0].dataUri
                        : null,
                    document1Type: _attachments.isNotEmpty
                        ? _attachments[0].type
                        : null,
                    document2: _attachments.length > 1
                        ? _attachments[1].dataUri
                        : null,
                    document2Type: _attachments.length > 1
                        ? _attachments[1].type
                        : null,
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

  Future<void> _pickAttachments() async {
    if (_attachments.length >= 2) {
      _message('Maximum 2 attachments allowed.');
      return;
    }
    setState(() => _isPickingAttachment = true);
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov'],
      );
      if (result == null || !mounted) return;

      final remainingSlots = 2 - _attachments.length;
      final picked = <_EnquiryAttachment>[];
      for (final file in result.files.take(remainingSlots)) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        final attachment = _EnquiryAttachment.fromBytes(
          name: file.name,
          extension: file.extension,
          bytes: bytes,
        );
        if (attachment == null) continue;
        picked.add(attachment);
      }

      if (picked.isEmpty) {
        _message('Please choose a valid image or video file.');
        return;
      }
      setState(() => _attachments.addAll(picked));
    } catch (error) {
      if (!mounted) return;
      _message(
        professionalErrorMessage(
          error,
          fallback: 'Attachment could not be added. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingAttachment = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _EnquiryAttachment {
  const _EnquiryAttachment({
    required this.name,
    required this.type,
    required this.dataUri,
  });

  final String name;
  final String type;
  final String dataUri;

  static _EnquiryAttachment? fromBytes({
    required String name,
    required String? extension,
    required Uint8List bytes,
  }) {
    final ext = (extension ?? name.split('.').last).toLowerCase();
    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      _ => '',
    };
    if (mimeType.isEmpty) return null;

    return _EnquiryAttachment(
      name: name,
      type: mimeType.startsWith('video/') ? 'video' : 'image',
      dataUri: 'data:$mimeType;base64,${base64Encode(bytes)}',
    );
  }
}
