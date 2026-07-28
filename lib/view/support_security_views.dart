import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/response/service_category_model.dart';
import 'package:sahubyte_user/model/response/support_faq_model.dart';
import 'package:sahubyte_user/repository/service_catalog_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterView extends StatefulWidget {
  const HelpCenterView({super.key});

  @override
  State<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends State<HelpCenterView> {
  final _repository = ServiceCatalogRepository();
  final _searchController = TextEditingController();
  List<SupportFaqModel> _faqs = const [];
  ServiceSettingsModel? _settings;
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSupport();
  }

  Future<void> _loadSupport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.getFaqs(),
        _repository.getStoreSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _faqs = results.first as List<SupportFaqModel>;
        _settings = results.last as ServiceSettingsModel;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = professionalErrorMessage(
          error,
          fallback: 'Support information could not be refreshed.',
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SupportFaqModel> get _filteredFaqs {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _faqs;
    return _faqs.where((faq) {
      return '${faq.title} ${faq.description}'.toLowerCase().contains(query);
    }).toList();
  }

  String get _contactNumber => _settings?.contactNumber.trim() ?? '';

  String get _whatsappNumber =>
      _contactNumber.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _launch(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No supported app was found on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;
    return Scaffold(
      appBar: const AppPageHeader(title: 'Help center'),
      body: _loading
          ? const _HelpCenterSkeleton()
          : _error != null
          ? _HelpCenterError(message: _error!, onRetry: _loadSupport)
          : RefreshIndicator(
              onRefresh: _loadSupport,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  AppHeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.aqua,
                          size: 34,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'How can we help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Find quick answers or connect with the support team.',
                          style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            hintText: 'Search bookings, payments, account...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const AppSectionTitle(
                    'Contact support',
                    subtitle: 'Choose the fastest option for your issue',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SupportAction(
                          icon: const Icon(
                            Icons.call_outlined,
                            color: AppColors.success,
                            size: 28,
                          ),
                          label: 'Call support',
                          onTap: () =>
                              _launch(Uri(scheme: 'tel', path: _contactNumber)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SupportAction(
                          icon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Color(0xFF25D366),
                            size: 28,
                          ),
                          label: 'WhatsApp',
                          onTap: () => _launch(
                            Uri.https('wa.me', '/$_whatsappNumber', {
                              'text': 'I need help with my SahuByte booking.',
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppSectionTitle(
                    'Frequently asked questions',
                    subtitle: '${faqs.length} answers found',
                  ),
                  const SizedBox(height: 10),
                  if (faqs.isEmpty)
                    const AppSurfaceCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No matching answer found',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try a shorter search or contact support.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    AppSurfaceCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var index = 0; index < faqs.length; index++) ...[
                            ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.sky,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              title: Text(
                                faqs[index].title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                70,
                                0,
                                18,
                                16,
                              ),
                              children: [
                                Text(
                                  faqs[index].description,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            if (index < faqs.length - 1)
                              const Divider(height: 1),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class PrivacySecurityView extends StatefulWidget {
  const PrivacySecurityView({
    super.key,
    required this.mobile,
    required this.email,
  });

  final String mobile;
  final String email;

  @override
  State<PrivacySecurityView> createState() => _PrivacySecurityViewState();
}

class _PrivacySecurityViewState extends State<PrivacySecurityView> {
  bool _loading = true;
  bool _bookingUpdates = true;
  bool _serviceOffers = false;
  bool _diagnostics = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bookingUpdates = prefs.getBool('privacy_booking_updates') ?? true;
      _serviceOffers = prefs.getBool('privacy_service_offers') ?? false;
      _diagnostics = prefs.getBool('privacy_diagnostics') ?? false;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  String get _maskedMobile {
    final value = widget.mobile.trim();
    if (value.length < 4) return value.isEmpty ? 'Not available' : value;
    return '${'•' * (value.length - 4)}${value.substring(value.length - 4)}';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out securely?'),
        content: const Text(
          'Your local session will be removed from this device. You can sign in again using OTP.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageHeader(title: 'Privacy & security'),
      body: _loading
          ? const _SecuritySkeleton()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppHeroCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 27,
                        backgroundColor: Color(0x22FFFFFF),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.aqua,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your account is protected',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'OTP verified session · $_maskedMobile',
                              style: const TextStyle(color: Color(0xCCFFFFFF)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const AppSectionTitle(
                  'Security',
                  subtitle: 'Login and active device information',
                ),
                const SizedBox(height: 10),
                AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SecurityRow(
                        icon: Icons.sms_outlined,
                        title: 'OTP protected login',
                        subtitle: 'A fresh OTP is required after logout',
                        color: AppColors.success,
                        trailing: const _SecureBadge('Active'),
                      ),
                      const Divider(height: 1),
                      _SecurityRow(
                        icon: Icons.smartphone_outlined,
                        title: 'This device',
                        subtitle: widget.email.trim().isEmpty
                            ? 'Current SahuByte session'
                            : widget.email.trim(),
                        color: AppColors.primary,
                        trailing: const _SecureBadge('Current'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const AppSectionTitle(
                  'Privacy controls',
                  subtitle: 'Choose how SahuByte communicates with you',
                ),
                const SizedBox(height: 10),
                AppSurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _bookingUpdates,
                        title: const Text(
                          'Booking updates',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Status and appointment notifications',
                        ),
                        onChanged: (value) {
                          setState(() => _bookingUpdates = value);
                          _save('privacy_booking_updates', value);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _serviceOffers,
                        title: const Text(
                          'Service offers',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text('Optional promotions and offers'),
                        onChanged: (value) {
                          setState(() => _serviceOffers = value);
                          _save('privacy_service_offers', value);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _diagnostics,
                        title: const Text(
                          'Optional diagnostics',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Share basic app reliability information',
                        ),
                        onChanged: (value) {
                          setState(() => _diagnostics = value);
                          _save('privacy_diagnostics', value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const AppSectionTitle(
                  'Privacy notice',
                  subtitle: 'How service information is used',
                ),
                const SizedBox(height: 10),
                const AppSurfaceCard(
                  child: Text(
                    'SahuByte uses your profile, service address, booking details and uploaded media to arrange and complete requested services. '
                    'Only relevant booking information is shared with the assigned technician. OTPs should never be shared with anyone. '
                    'Billing records remain available in your profile after service completion.',
                    style: TextStyle(color: AppColors.muted, height: 1.55),
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out from this device'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE45858),
                    side: const BorderSide(color: Color(0x44E45858)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HelpCenterSkeleton extends StatelessWidget {
  const _HelpCenterSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      for (var index = 0; index < 4; index++)
        Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
        ),
    ],
  );
}

class _HelpCenterError extends StatelessWidget {
  const _HelpCenterError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    children: [
      const SizedBox(height: 100),
      AppSurfaceCard(
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 46,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Help center could not be loaded',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    ),
  );
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.success,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _SecuritySkeleton extends StatelessWidget {
  const _SecuritySkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (final height in [112.0, 150.0, 230.0, 130.0])
        Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.line),
          ),
        ),
    ],
  );
}
