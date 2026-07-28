import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';

class ReportSubmittedView extends StatelessWidget {
  const ReportSubmittedView({super.key, required this.appointmentSlot});

  final String appointmentSlot;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const AppPageHeader(
          title: 'Booking confirmed',
          showBack: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    children: [
                      AppHeroCard(
                        child: Column(
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.success, AppColors.aqua],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.line,
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 66,
                              ),
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Service enquiry submitted',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your enquiry has been created successfully. Payment gateway is not connected yet, so this test flow submits the request directly.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xCCFFFFFF),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x22FFFFFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'CREATE ENQUIRY COMPLETED',
                                style: TextStyle(
                                  color: AppColors.aqua,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      AppSurfaceCard(
                        child: Row(
                          children: [
                            const _IconBox(icon: Icons.calendar_today_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Technician visit',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appointmentSlot.trim().isEmpty
                                        ? 'Selected appointment slot'
                                        : appointmentSlot,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
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

                      const SizedBox(height: 22),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Service flow',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      AppSurfaceCard(
                        child: Column(
                          children: [
                            _buildStatusItem(
                              label: 'Awaiting',
                              subtitle: 'Your service enquiry is submitted.',
                              isCompleted: true,
                            ),
                            _divider(),
                            _buildStatusItem(
                              label: 'Technician Assigned',
                              subtitle:
                                  'A technician will accept and be assigned to your request.',
                              isCompleted: false,
                            ),
                            _divider(),
                            _buildStatusItem(
                              label: 'On The Way',
                              subtitle:
                                  'Assigned technician is travelling to your location.',
                              isCompleted: false,
                            ),
                            _divider(),
                            _buildStatusItem(
                              label: 'Arrived',
                              subtitle:
                                  'Technician has reached your service address.',
                              isCompleted: false,
                            ),
                            _divider(),
                            _buildStatusItem(
                              label: 'Inspection',
                              subtitle:
                                  'Device or service issue will be checked.',
                              isCompleted: false,
                            ),
                            _divider(),
                            _buildStatusItem(
                              label: 'Job Card',
                              subtitle:
                                  'Technician will prepare the job card and cost details.',
                              isCompleted: false,
                            ),
                            _divider(),
                            _buildStatusItem(
                              label: 'Job Started',
                              subtitle:
                                  'Work will begin after required approvals.',
                              isCompleted: false,
                            ),
                            _divider(),
                            _buildStatusItem(
                              label: 'Completed',
                              subtitle:
                                  'Service will be completed and invoice shared.',
                              isCompleted: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home_outlined),
                    label: const Text(
                      'Back to home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStatusItem({
    required String label,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isCompleted ? AppColors.primary : AppColors.line,
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : null,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                softWrap: true,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                softWrap: true,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Divider(color: AppColors.line, height: 1),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}
