import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'Privacy policy',
    icon: Icons.policy_outlined,
    intro:
        'This policy explains how Sahubyte uses information needed to provide and improve your service experience.',
    sections: [
      _LegalSection(
        'Information we collect',
        'We may collect your name, mobile number, email address, service address, booking details, uploaded media and support communications.',
      ),
      _LegalSection(
        'How information is used',
        'Your information is used to create bookings, assign technicians, share service updates, process support requests and maintain account security.',
      ),
      _LegalSection(
        'Information sharing',
        'Relevant booking details may be shared with the assigned technician and trusted service providers only when required to deliver your requested service.',
      ),
      _LegalSection(
        'Data protection',
        'Reasonable technical and operational safeguards are used to protect account and booking information from unauthorised access.',
      ),
      _LegalSection(
        'Your choices',
        'You can review and update profile or address information in the app and contact support for account or privacy-related requests.',
      ),
    ],
  );
}

class TermsAndConditionsView extends StatelessWidget {
  const TermsAndConditionsView({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
    title: 'Terms and conditions',
    icon: Icons.description_outlined,
    intro:
        'These terms describe the basic rules for using Sahubyte services and managing service bookings.',
    sections: [
      _LegalSection(
        'Using the service',
        'Provide accurate account, address and problem information so the appropriate technician can review and complete your request.',
      ),
      _LegalSection(
        'Bookings and estimates',
        'Availability, visit times and estimates may depend on service location, inspection findings, required parts and customer approval.',
      ),
      _LegalSection(
        'Customer approval',
        'Review job-card details and charges carefully before approval. Additional work should only proceed after the required approval is recorded.',
      ),
      _LegalSection(
        'Cancellations and reallocation',
        'A booking may be cancelled, rescheduled or assigned to another technician when service delivery cannot continue as planned.',
      ),
      _LegalSection(
        'Responsible use',
        'Do not misuse the platform, submit unlawful content, impersonate another person or interfere with service and account security.',
      ),
    ],
  );
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({
    required this.title,
    required this.icon,
    required this.intro,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final String intro;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageHeader(title: title),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppHeroCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.aqua),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      intro,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < sections.length; index++) ...[
          AppSurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sections[index].title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sections[index].body,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (index != sections.length - 1) const SizedBox(height: 10),
        ],
      ],
    ),
  );
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}
