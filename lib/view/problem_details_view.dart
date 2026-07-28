import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/select_address_view.dart';

class ProblemDetailsView extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String subCategoryId;
  final String subCategoryName;
  final String brandId;
  final String brandName;
  final List<String> problemIds;
  final String problemTitle;
  final int problemCharge;
  final String serviceType;
  const ProblemDetailsView({
    super.key,
    this.categoryId = '',
    this.categoryName = '',
    this.subCategoryId = '',
    this.subCategoryName = '',
    this.brandId = '',
    this.brandName = '',
    this.problemIds = const [],
    required this.problemTitle,
    required this.problemCharge,
    required this.serviceType,
  });

  @override
  State<ProblemDetailsView> createState() => _ProblemDetailsViewState();
}

class _ProblemDetailsViewState extends State<ProblemDetailsView> {
  String? _selectedIssue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageHeader(title: 'Tell us more'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBookingHero(
                    step: 5,
                    totalSteps: 9,
                    title: 'Tell us a little more',
                    subtitle:
                        'Selected issue estimate Rs. ${widget.problemCharge}. This will be payable after the technician creates the job card.',
                    icon: Icons.fact_check_outlined,
                  ),
                  const SizedBox(height: 18),
                  _buildSectionHeader('When does it happen?'),
                  _buildIssueItem('Issue appears immediately'),
                  _buildIssueItem('Issue happens after some usage'),
                  _buildIssueItem('Issue happens only for one user/device'),
                  _buildIssueItem('Issue happens for everyone'),
                  const SizedBox(height: 18),
                  _buildSectionHeader('Impact level'),
                  _buildIssueItem('Work stopped completely'),
                  _buildIssueItem('Work is slow but possible'),
                  _buildIssueItem('Intermittent issue'),
                  _buildIssueItem('Need diagnosis during visit'),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppSurfaceCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Only the service fee and its tax are paid while booking. The selected problem charge, parts and extra work are payable after the job card is created and approved.',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
          AppBottomAction(
            label: 'Continue',
            onPressed: () {
              if (_selectedIssue == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an issue first')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectAddressView(
                    categoryId: widget.categoryId,
                    categoryName: widget.categoryName,
                    subCategoryId: widget.subCategoryId,
                    subCategoryName: widget.subCategoryName,
                    brandId: widget.brandId,
                    brandName: widget.brandName,
                    problemIds: widget.problemIds,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildIssueItem(String title) {
    bool isSelected = _selectedIssue == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIssue = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(17),
          color: isSelected ? AppColors.sky : AppColors.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.line,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
