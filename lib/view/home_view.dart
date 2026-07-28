import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sahubyte_user/model/response/enquiry_model.dart';
import 'package:sahubyte_user/model/response/service_category_model.dart';
import 'package:sahubyte_user/model/response/user_address_model.dart';
import 'package:sahubyte_user/repository/enquiry_repository.dart';
import 'package:sahubyte_user/repository/service_catalog_repository.dart';
import 'package:sahubyte_user/res/api_constants.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/utils/indian_states.dart';
import 'package:sahubyte_user/utils/user_session_store.dart';
import 'package:sahubyte_user/view/brand_applications_view.dart';
import 'package:sahubyte_user/view/booking_details_view.dart';
import 'package:sahubyte_user/view/brands_view.dart';
import 'package:sahubyte_user/view/login_view.dart';
import 'package:sahubyte_user/view/invoices_receipts_view.dart';
import 'package:sahubyte_user/view/legal_views.dart';
import 'package:sahubyte_user/view/my_bookings_view.dart';
import 'package:sahubyte_user/view/report_problem_view.dart';
import 'package:sahubyte_user/view/service_review_sheet.dart';
import 'package:sahubyte_user/view/support_security_views.dart';
import 'package:sahubyte_user/view_model/profile_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;
  late final _screens = const [
    _Dashboard(),
    MyBookingsView(),
    _StoreView(),
    _AlertsView(),
    _ProfileView(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _screens[_index],
    bottomNavigationBar: AppBottomNav(
      currentIndex: _index,
      onTap: (value) => setState(() => _index = value),
    ),
  );
}

class _Dashboard extends StatefulWidget {
  const _Dashboard();

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  final _serviceCatalogRepository = ServiceCatalogRepository();
  final _enquiryRepository = EnquiryRepository();
  final _profileViewModel = ProfileViewModel();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _servicesKey = GlobalKey();
  late final Future<List<ServiceCategoryModel>> _categoriesFuture =
      _serviceCatalogRepository.getCategories();
  late final Future<List<ServiceTestimonialModel>> _testimonialsFuture =
      _serviceCatalogRepository.getTestimonials();
  String _displayName = 'User';
  Future<EnquiryModel?>? _recentEnquiryFuture;
  Future<List<_ServiceSearchSuggestion>>? _searchIndexFuture;
  List<_ServiceSearchSuggestion> _searchSuggestions = const [];
  bool _isSearchingService = false;
  bool _showSearchSuggestions = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadHeaderName();
    _recentEnquiryFuture = _loadRecentEnquiry();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHeaderName() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('user_id') ??
        prefs.getString('userId') ??
        prefs.getString('id') ??
        '';
    final cachedName = prefs.getString('name') ?? prefs.getString('user_name');
    if (cachedName?.trim().isNotEmpty == true && mounted) {
      setState(() => _displayName = cachedName!.trim());
    }
    if (userId.isEmpty) return;

    try {
      final user = await _profileViewModel.getUserDetail(userId);
      if (!mounted || user.name.trim().isEmpty) return;
      setState(() => _displayName = user.name.trim());
    } catch (_) {
      // Keep cached/default name if profile fetch fails.
    }
  }

  Future<EnquiryModel?> _loadRecentEnquiry() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString('user_id') ??
        prefs.getString('userId') ??
        prefs.getString('id') ??
        '';
    if (userId.isEmpty) return null;
    final bookings = await _enquiryRepository.getEnquiries(
      userId: userId,
      page: 1,
      limit: 1,
    );
    if (bookings.isEmpty) return null;
    final recent = bookings.first;
    _scheduleAutomaticReview(recent);
    return recent;
  }

  void _scheduleAutomaticReview(EnquiryModel booking) {
    if (!reserveAutomaticReviewPrompt(booking)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await showServiceReviewSheet(context, booking: booking);
      if (!mounted || result == null) return;
      setState(() => _recentEnquiryFuture = _loadRecentEnquiry());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for rating your completed service.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 78,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: CircleAvatar(
          backgroundColor: Color(0x22FFFFFF),
          child: Icon(
            Icons.dashboard_customize_rounded,
            color: AppColors.aqua,
            size: 20,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.asset('assets/sahubyte_logo.png', height: 24),
        ),
      ],
    ),
    body: ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5E52E8), Color(0xFF8C7BFF)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x336D5DFB),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expert care for your\nconnected world.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Book verified technicians for devices, networks, and security setups.',
                style: TextStyle(color: Color(0xDDFFFFFF), height: 1.4),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _scrollToServices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Book a service'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onTap: () => _onSearchChanged(_searchController.text),
              onSubmitted: (_) => _searchService(context),
              decoration: InputDecoration(
                hintText: 'Search for a service',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton.filledTonal(
                  tooltip: 'Search service',
                  onPressed: _isSearchingService
                      ? null
                      : () => _searchService(context),
                  icon: _isSearchingService
                      ? const SkeletonBox(width: 18, height: 18, radius: 6)
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
              ),
            ),
            if (_showSearchSuggestions) ...[
              const SizedBox(height: 8),
              _ServiceSearchDropdown(
                isLoading: _isSearchingService,
                suggestions: _searchSuggestions,
                query: _searchController.text,
                onSelect: (suggestion) =>
                    _openSearchSuggestion(context, suggestion),
              ),
            ],
          ],
        ),
        const SizedBox(height: 15),
        _Heading(
          key: _servicesKey,
          'Our services',
          'Professional help, right when you need it',
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<ServiceCategoryModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ServiceGridSkeleton();
            }
            if (snapshot.hasError) {
              return AppSurfaceCard(
                child: Row(
                  children: const [
                    Icon(Icons.cloud_off_rounded, color: AppColors.coral),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not load services. Please try again later.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              );
            }
            final categories = snapshot.data ?? const [];
            if (categories.isEmpty) {
              return const AppSurfaceCard(
                child: Text(
                  'No services available right now.',
                  style: TextStyle(color: AppColors.muted),
                ),
              );
            }
            return GridView.builder(
              itemCount: categories.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width < 350 ? 1 : 2,
                childAspectRatio: MediaQuery.sizeOf(context).width < 350
                    ? 1.65
                    : .88,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _ServiceCard(
                  category.name,
                  'Tap to choose sub category',
                  category.imageCandidates,
                  () => _open(context, category),
                );
              },
            );
          },
        ),
        const SizedBox(height: 15),
        const Row(
          children: [
            Expanded(
              child: _Trust(
                '4.9',
                'Customer rating',
                Icons.star_rounded,
                AppColors.coral,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _Trust(
                '30 min',
                'Quick response',
                Icons.bolt_rounded,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const _Heading('Active request', 'Stay updated on your next visit'),
        const SizedBox(height: 14),
        FutureBuilder<EnquiryModel?>(
          future: _recentEnquiryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 170, height: 18, radius: 7),
                    SizedBox(height: 12),
                    SkeletonBox(width: double.infinity, height: 54, radius: 14),
                  ],
                ),
              );
            }
            final booking = snapshot.data;
            if (booking == null) {
              return const AppSurfaceCard(
                child: Text(
                  'No active request yet. Book a service to see live updates here.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
              );
            }
            return _ActiveRequestCard(booking: booking);
          },
        ),
        const SizedBox(height: 15),
        const _Heading(
          'Trusted by customers',
          'Real stories from recent service visits',
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<ServiceTestimonialModel>>(
          future: _testimonialsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 196,
                child: Row(
                  children: [
                    Expanded(child: SkeletonBox(height: 196, radius: 22)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBox(height: 196, radius: 22)),
                  ],
                ),
              );
            }
            final testimonials = snapshot.data ?? const [];
            if (testimonials.isEmpty) {
              return const AppSurfaceCard(
                child: Text(
                  'Customer stories will appear here soon.',
                  style: TextStyle(color: AppColors.muted),
                ),
              );
            }
            return SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: testimonials.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final testimonial = testimonials[index];
                  return _Testimonial(
                    testimonial.userName,
                    'Customer review',
                    testimonial.description,
                    _initials(testimonial.userName),
                    testimonial.imageCandidates,
                    _testimonialColor(index),
                    testimonial.rating,
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        const _Heading(
          'Why choose Sahubyte?',
          'Reliable support built around your convenience',
        ),
        const SizedBox(height: 14),
        const Column(
          children: [
            _Benefit(
              Icons.verified_user_outlined,
              'Verified technicians',
              'Every professional is screened and service-ready.',
              AppColors.primary,
            ),
            SizedBox(height: 12),
            _Benefit(
              Icons.price_check_outlined,
              'Transparent pricing',
              'Clear estimates before the work begins.',
              AppColors.success,
            ),
            SizedBox(height: 12),
            _Benefit(
              Icons.update_rounded,
              'Live booking updates',
              'Track every step from request to completion.',
              AppColors.coral,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.navyDark,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help with your tech?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Book a verified technician and get dependable support at your doorstep.',
                style: TextStyle(color: Color(0xCCFFFFFF), height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _scrollToServices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aqua,
                  foregroundColor: AppColors.navyDark,
                  minimumSize: const Size(0, 44),
                ),
                child: const Text('Book a technician'),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _scrollToServices() {
    final context = _servicesKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: .08,
      );
      return;
    }
    _scrollController.animateTo(
      360,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showSearchSuggestions = false;
        _searchSuggestions = const [];
      });
      return;
    }
    setState(() {
      _showSearchSuggestions = true;
      _isSearchingService = true;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 260), () async {
      try {
        final index = await _loadSearchIndex();
        if (!mounted) return;
        final filtered = index
            .where((item) => item.matches(query))
            .take(8)
            .toList();
        setState(() {
          _searchSuggestions = filtered;
          _showSearchSuggestions = _searchController.text.trim().isNotEmpty;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _searchSuggestions = const []);
      } finally {
        if (mounted) setState(() => _isSearchingService = false);
      }
    });
  }

  Future<void> _searchService(BuildContext context) async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _scrollToServices();
      return;
    }
    if (_isSearchingService) return;
    setState(() => _isSearchingService = true);
    try {
      final index = await _loadSearchIndex();
      if (!context.mounted) return;
      _ServiceSearchSuggestion? match;
      for (final item in index) {
        if (item.matches(query)) {
          match = item;
          break;
        }
      }
      if (match != null) {
        _openSearchSuggestion(context, match);
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No service found for "$query".')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not search services right now.')),
      );
    } finally {
      if (mounted) setState(() => _isSearchingService = false);
    }
  }

  Future<List<_ServiceSearchSuggestion>> _loadSearchIndex() {
    return _searchIndexFuture ??= _buildSearchIndex();
  }

  Future<List<_ServiceSearchSuggestion>> _buildSearchIndex() async {
    final categories = await _categoriesFuture;
    final suggestions = <_ServiceSearchSuggestion>[];

    for (final category in categories) {
      suggestions.add(_ServiceSearchSuggestion.category(category));
      final subCategories = await _serviceCatalogRepository.getSubCategories(
        categoryId: category.id,
      );
      for (final subCategory in subCategories) {
        suggestions.add(
          _ServiceSearchSuggestion.subCategory(category, subCategory),
        );
        final brands = await _serviceCatalogRepository.getBrands(
          categoryId: category.id,
          subCategoryId: subCategory.id,
        );
        for (final brand in brands) {
          suggestions.add(
            _ServiceSearchSuggestion.brand(category, subCategory, brand),
          );
        }
      }
    }

    return suggestions;
  }

  void _openSearchSuggestion(
    BuildContext context,
    _ServiceSearchSuggestion suggestion,
  ) {
    FocusScope.of(context).unfocus();
    setState(() => _showSearchSuggestions = false);

    switch (suggestion.type) {
      case _ServiceSearchType.category:
        _open(context, suggestion.category);
        return;
      case _ServiceSearchType.subCategory:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrandsView(
              applicationName: suggestion.subCategory!.name,
              categoryId: suggestion.category.id,
              categoryName: suggestion.category.name,
              subCategoryId: suggestion.subCategory!.id,
              subCategoryName: suggestion.subCategory!.name,
              serviceType: suggestion.category.name,
            ),
          ),
        );
        return;
      case _ServiceSearchType.brand:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportProblemView(
              applicationName: suggestion.subCategory!.name,
              serviceType: suggestion.category.name,
              categoryId: suggestion.category.id,
              categoryName: suggestion.category.name,
              subCategoryId: suggestion.subCategory!.id,
              subCategoryName: suggestion.subCategory!.name,
              brandId: suggestion.brand!.id,
              brandName: suggestion.brand!.name,
            ),
          ),
        );
        return;
    }
  }

  void _open(BuildContext context, ServiceCategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BrandApplicationsView(
          categoryId: category.id,
          serviceType: category.name,
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 13),
      ),
    ],
  );
}

enum _ServiceSearchType { category, subCategory, brand }

class _ServiceSearchSuggestion {
  const _ServiceSearchSuggestion({
    required this.type,
    required this.category,
    this.subCategory,
    this.brand,
  });

  factory _ServiceSearchSuggestion.category(ServiceCategoryModel category) {
    return _ServiceSearchSuggestion(
      type: _ServiceSearchType.category,
      category: category,
    );
  }

  factory _ServiceSearchSuggestion.subCategory(
    ServiceCategoryModel category,
    ServiceSubCategoryModel subCategory,
  ) {
    return _ServiceSearchSuggestion(
      type: _ServiceSearchType.subCategory,
      category: category,
      subCategory: subCategory,
    );
  }

  factory _ServiceSearchSuggestion.brand(
    ServiceCategoryModel category,
    ServiceSubCategoryModel subCategory,
    ServiceBrandModel brand,
  ) {
    return _ServiceSearchSuggestion(
      type: _ServiceSearchType.brand,
      category: category,
      subCategory: subCategory,
      brand: brand,
    );
  }

  final _ServiceSearchType type;
  final ServiceCategoryModel category;
  final ServiceSubCategoryModel? subCategory;
  final ServiceBrandModel? brand;

  String get title => switch (type) {
    _ServiceSearchType.category => category.name,
    _ServiceSearchType.subCategory => subCategory?.name ?? category.name,
    _ServiceSearchType.brand => brand?.name ?? '',
  };

  String get subtitle => switch (type) {
    _ServiceSearchType.category => 'Service category',
    _ServiceSearchType.subCategory => '${category.name} category',
    _ServiceSearchType.brand =>
      '${category.name} / ${subCategory?.name ?? 'Sub category'}',
  };

  String get badge => switch (type) {
    _ServiceSearchType.category => 'Service',
    _ServiceSearchType.subCategory => 'Sub category',
    _ServiceSearchType.brand => 'Brand',
  };

  IconData get icon => switch (type) {
    _ServiceSearchType.category => Icons.grid_view_rounded,
    _ServiceSearchType.subCategory => Icons.devices_other_rounded,
    _ServiceSearchType.brand => Icons.business_center_outlined,
  };

  Color get color => switch (type) {
    _ServiceSearchType.category => AppColors.primary,
    _ServiceSearchType.subCategory => AppColors.success,
    _ServiceSearchType.brand => AppColors.coral,
  };

  bool matches(String query) {
    bool match(String value) {
      final normalized = value.trim().toLowerCase();
      return normalized.isNotEmpty &&
          (normalized == query ||
              normalized.startsWith(query) ||
              normalized.contains(query));
    }

    return match(category.name) ||
        match(subCategory?.name ?? '') ||
        match(brand?.name ?? '');
  }
}

class _ServiceSearchDropdown extends StatelessWidget {
  const _ServiceSearchDropdown({
    required this.isLoading,
    required this.suggestions,
    required this.query,
    required this.onSelect,
  });

  final bool isLoading;
  final List<_ServiceSearchSuggestion> suggestions;
  final String query;
  final ValueChanged<_ServiceSearchSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    if (isLoading && suggestions.isEmpty) {
      return const AppSurfaceCard(
        padding: EdgeInsets.all(14),
        radius: 18,
        child: Row(
          children: [
            SkeletonBox(width: 18, height: 18, radius: 6),
            SizedBox(width: 12),
            Text(
              'Searching services...',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    if (suggestions.isEmpty) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(14),
        radius: 18,
        child: Row(
          children: [
            const Icon(Icons.search_off_rounded, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No result found for "${query.trim()}".',
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: appSurface(radius: 18),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6),
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            dense: true,
            onTap: () => onSelect(suggestion),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: suggestion.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(suggestion.icon, color: suggestion.color, size: 19),
            ),
            title: Text(
              suggestion.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              suggestion.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _MiniBadge(suggestion.badge, suggestion.color),
          );
        },
      ),
    );
  }
}

class _ActiveRequestCard extends StatelessWidget {
  const _ActiveRequestCard({required this.booking});

  final EnquiryModel booking;

  Color get _statusColor {
    switch (booking.statusLabel) {
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
      case 'Expired':
        return AppColors.coral;
      case 'Technician Assigned':
        return AppColors.primary;
      default:
        return AppColors.aqua;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = booking.progressLabel.isNotEmpty
        ? booking.progressLabel
        : booking.statusLabel;
    final problems = booking.problemSummary.trim();
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingDetailsView(booking: booking)),
      ),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(14),
        radius: 24,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _statusColor.withValues(alpha: .16),
                    _statusColor.withValues(alpha: .08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.receipt_long_rounded, color: _statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.serviceTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(subtitle, _statusColor),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    problems.isEmpty ? booking.bookingCode : problems,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.dateTimeSlot.isEmpty
                              ? 'Slot not selected'
                              : booking.dateTimeSlot,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ServiceGridSkeleton extends StatelessWidget {
  const _ServiceGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width < 350 ? 1 : 2,
        childAspectRatio: MediaQuery.sizeOf(context).width < 350 ? 1.65 : .88,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: appSurface(radius: 22),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: 90,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard(this.title, this.subtitle, this.images, this.onTap);
  final String title;
  final String subtitle;
  final List<String> images;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: onTap,
    child: Container(
      decoration: appSurface(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkImageWithFallback(
                    urls: images,
                    fallbackIcon: Icons.miscellaneous_services_rounded,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0x880A1022)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    bottom: 10,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NetworkImageWithFallback extends StatefulWidget {
  const _NetworkImageWithFallback({
    required this.urls,
    required this.fallbackIcon,
  });

  final List<String> urls;
  final IconData fallbackIcon;

  @override
  State<_NetworkImageWithFallback> createState() =>
      _NetworkImageWithFallbackState();
}

class _NetworkImageWithFallbackState extends State<_NetworkImageWithFallback> {
  int _index = 0;

  @override
  void didUpdateWidget(covariant _NetworkImageWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls.join('|') != widget.urls.join('|')) {
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty || _index >= widget.urls.length) {
      return _ImageFallback(icon: widget.fallbackIcon);
    }

    return Image.network(
      widget.urls[_index],
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _index += 1);
        });
        return _ImageFallback(icon: widget.fallbackIcon);
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.sky,
      child: Center(child: Icon(icon, color: AppColors.primary, size: 38)),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(15),
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
      ],
    ),
  );
}

class _Trust extends StatelessWidget {
  const _Trust(this.value, this.label, this.icon, this.color);
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Testimonial extends StatelessWidget {
  const _Testimonial(
    this.name,
    this.service,
    this.review,
    this.initials,
    this.imageCandidates,
    this.color,
    this.rating,
  );
  final String name;
  final String service;
  final String review;
  final String initials;
  final List<String> imageCandidates;
  final Color color;
  final int rating;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 286,
    child: AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: .14),
                child: ClipOval(
                  child: imageCandidates.isEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : _NetworkImageWithFallback(
                          urls: imageCandidates,
                          fallbackIcon: Icons.person_rounded,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.format_quote_rounded, color: AppColors.line),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star_rounded,
                size: 16,
                color: index < rating
                    ? const Color(0xFFFFB74D)
                    : AppColors.line,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            review,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _testimonialColor(int index) {
  const colors = [AppColors.primary, AppColors.success, AppColors.coral];
  return colors[index % colors.length];
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: color),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _StoreView extends StatefulWidget {
  const _StoreView();

  @override
  State<_StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<_StoreView> {
  final _repository = ServiceCatalogRepository();
  late Future<(ServiceSettingsModel, double?)> _storeFuture;

  @override
  void initState() {
    super.initState();
    _storeFuture = _loadStore();
  }

  Future<(ServiceSettingsModel, double?)> _loadStore() async {
    final values = await Future.wait([
      _repository.getStoreSettings(),
      _repository.getStoreAverageRating(),
    ]);
    return (values.first as ServiceSettingsModel, values.last as double?);
  }

  Future<void> _refresh() async {
    setState(() => _storeFuture = _loadStore());
    await _storeFuture;
  }

  Future<void> _openContact(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this contact option.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: FutureBuilder<(ServiceSettingsModel, double?)>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StoreSkeleton();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 100),
                AppSurfaceCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        size: 46,
                        color: AppColors.muted,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Store details unavailable',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pull down or tap refresh to try again.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final settings = snapshot.data!.$1;
        final rating = snapshot.data!.$2;
        final services = settings.availableServices;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              AppHeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0x22FFFFFF),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: AppColors.aqua,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.storeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                settings.location,
                                style: const TextStyle(
                                  color: Color(0xCCFFFFFF),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _StoreMetric(
                            value: rating == null
                                ? '--'
                                : rating.toStringAsFixed(1),
                            label: 'Rating',
                            icon: Icons.star_rounded,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _StoreMetric(
                            value: 'Rs. ${settings.baseServiceFee}',
                            label: 'Base fee',
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _StoreMetric(
                            value: '${settings.taxPercent}%',
                            label: 'GST',
                            icon: Icons.percent_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppSectionTitle(
                'Available services',
                subtitle: 'Services offered by ${settings.storeName}',
              ),
              const SizedBox(height: 10),
              AppSurfaceCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: services
                      .map(
                        (service) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: .18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                service,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              AppSectionTitle(
                'Contact store',
                subtitle: 'Reach ${settings.storeName}',
              ),
              const SizedBox(height: 10),
              AppSurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    _StoreContactRow(
                      icon: Icons.call_outlined,
                      label: 'Phone',
                      value: settings.contactNumber,
                      onTap: () => _openContact(
                        Uri(scheme: 'tel', path: settings.contactNumber),
                      ),
                    ),
                    const Divider(height: 1),
                    _StoreContactRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: settings.contactEmail,
                      onTap: () => _openContact(
                        Uri(scheme: 'mailto', path: settings.contactEmail),
                      ),
                    ),
                    const Divider(height: 1),
                    _StoreContactRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: settings.location,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _StoreMetric extends StatelessWidget {
  const _StoreMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0x18FFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x28FFFFFF)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 17, color: AppColors.aqua),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xBBFFFFFF), fontSize: 10),
        ),
      ],
    ),
  );
}

class _StoreContactRow extends StatelessWidget {
  const _StoreContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    ),
    title: Text(
      label,
      style: const TextStyle(color: AppColors.muted, fontSize: 11),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w800,
      ),
    ),
    trailing: onTap == null
        ? null
        : const Icon(Icons.open_in_new_rounded, size: 18),
  );
}

class _StoreSkeleton extends StatelessWidget {
  const _StoreSkeleton();

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
      for (final height in [120.0, 210.0])
        Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
        ),
    ],
  );
}

class _AlertsView extends StatelessWidget {
  const _AlertsView();
  @override
  Widget build(BuildContext context) => const _Tab(
    title: 'Alerts',
    headline: 'Latest updates',
    subtitle: 'Everything important, without the noise.',
    icon: Icons.notifications_none_rounded,
    items: [
      _Item(
        Icons.check_circle_outline_rounded,
        'Booking confirmed',
        '2 minutes ago',
        AppColors.success,
      ),
      _Item(
        Icons.person_pin_circle_outlined,
        'Technician assigned',
        '1 hour ago',
        AppColors.primary,
      ),
      _Item(
        Icons.tips_and_updates_outlined,
        'Weekly care tip',
        'Yesterday',
        AppColors.coral,
      ),
    ],
  );
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  // ✅ userId is read from SharedPreferences instead of being hardcoded
  String _userId = '';
  bool _isGuest = false;
  bool _isSessionLoading = true;
  bool _isProfileLoading = true;
  final _profileViewModel = ProfileViewModel();
  String _name = '';
  String _mobile = '';
  String _email = '';
  String _dob = '';
  String? _state;
  String? _profileImage;
  final List<_SavedAddress> _addresses = [];
  final List<_PaymentMethod> _payments = [
    const _PaymentMethod(
      label: 'Cash on delivery',
      subtitle: 'Pay after technician visit',
      detail: 'No online payment needed',
      trailing: 'COD',
      icon: Icons.payments_outlined,
      color: AppColors.success,
    ),
    const _PaymentMethod(
      label: 'SB Wallet',
      subtitle: 'Fast checkout for repeat bookings',
      detail: 'Linked with your registered mobile',
      trailing: 'Rs. 0',
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _profileViewModel.addListener(_refresh);
    _loadUserId();
  }

  // ✅ Load the real user ID saved at login, then fetch profile
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('is_guest') ?? false;
    final id =
        prefs.getString('user_id') ??
        prefs.getString('userId') ??
        prefs.getString('id') ??
        '';
    if (!mounted) return;
    setState(() {
      _userId = id;
      _isGuest = isGuest || id.isEmpty;
      _isSessionLoading = false;
      _isProfileLoading = !_isGuest;
    });
    if (id.isNotEmpty && !_isGuest) {
      await _loadUserDetail();
      await _loadUserAddresses();
    } else {
      setState(() => _isProfileLoading = false);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String get _displayName {
    if (_isGuest) return 'Guest user';
    if (_isSessionLoading || _isProfileLoading) return '';
    return _name.isEmpty ? 'Complete your profile' : _name;
  }

  String get _displayMobile {
    if (_isGuest) return 'Login to add mobile number';
    if (_isSessionLoading || _isProfileLoading) return '';
    return _mobile.isEmpty ? 'Add mobile number' : _mobile;
  }

  String get _displayEmail {
    if (_isGuest) return 'Login to add email address';
    if (_isSessionLoading || _isProfileLoading) return '';
    return _email.isEmpty ? 'Add email address' : _email;
  }

  String get _displayDob {
    if (_isGuest) return 'Login to add date of birth';
    if (_isSessionLoading || _isProfileLoading) return '';
    return _dob.isEmpty ? 'Add date of birth' : _dob;
  }

  String get _displayState {
    if (_isGuest) return 'Login to select state';
    if (_isSessionLoading || _isProfileLoading) return '';
    return _state?.isNotEmpty == true ? _state! : 'Select state';
  }

  void _loginRequired([String feature = 'this feature']) {
    _message('Please login to access $feature.');
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  Future<void> _loadUserDetail() async {
    try {
      final user = await _profileViewModel.getUserDetail(_userId);
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final sessionMobile = prefs.getString('mobile')?.trim() ?? '';
      if (sessionMobile.isNotEmpty &&
          user.mobile.trim().isNotEmpty &&
          sessionMobile != user.mobile.trim()) {
        await UserSessionStore.clearUserScopedData(prefs);
        await prefs.setBool('is_logged_in', false);
        await prefs.setBool('is_guest', false);
        if (!mounted) return;
        _message('Session refreshed. Please login again.');
        _goToLogin();
        return;
      }
      setState(() {
        if (user.name.isNotEmpty) _name = user.name;
        if (user.mobile.isNotEmpty) _mobile = user.mobile;
        if (user.email.isNotEmpty) _email = user.email;
        if (user.dob.isNotEmpty) _dob = user.dob;
        _state = matchIndianState(user.state);
        if (user.profileImage?.isNotEmpty == true) {
          _profileImage = user.profileImage;
        }
        _isProfileLoading = false;
      });
    } catch (e) {
      debugPrint('[ProfileView] _loadUserDetail error: $e');
      // Keep the local display values when profile loading is unavailable.
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _loadUserAddresses() async {
    try {
      final addresses = await _profileViewModel.getUserAddresses(_userId);
      if (!mounted) return;
      setState(() {
        _addresses
          ..clear()
          ..addAll(addresses.asMap().entries.map(_savedAddressFromDb));
      });
    } catch (e) {
      debugPrint('[ProfileView] _loadUserAddresses error: $e');
    }
  }

  Future<void> _refreshProfileData() async {
    if (_isGuest) return;
    await Future.wait([_loadUserDetail(), _loadUserAddresses()]);
  }

  _SavedAddress _savedAddressFromDb(MapEntry<int, UserAddressModel> entry) {
    final address = entry.value;
    return _SavedAddress(
      id: address.id,
      createdAt: address.createdAt,
      name: _name,
      phone: _mobile,
      pincode: '',
      city: '',
      state: matchIndianState(address.state),
      house: address.address,
      area: '',
      type: 'Home',
      isDefault: entry.key == 0,
    );
  }

  @override
  void dispose() {
    _profileViewModel.removeListener(_refresh);
    _profileViewModel.dispose();
    super.dispose();
  }

  DateTime? _parseDob(String value) {
    final normalized = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(normalized);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String _formatDob(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickProfileDob(TextEditingController controller) async {
    final now = DateTime.now();
    final parsed = _parseDob(controller.text);
    final initialDate = parsed != null && !parsed.isAfter(now)
        ? parsed
        : DateTime(now.year - 18, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
      cancelText: 'Cancel',
      confirmText: 'Use date',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.surface,
            headerBackgroundColor: AppColors.navyDark,
            headerForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;
    controller.text = _formatDob(date);
  }

  String _nowForApi() {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  Future<void> _syncUserAddress({
    required _SavedAddress address,
    required bool isEdit,
  }) async {
    if (_userId.isEmpty) {
      _message('Please login again to save address.');
      return;
    }

    try {
      final response = await _profileViewModel.saveUserAddress(
        act: isEdit ? 'edit' : 'add',
        id: isEdit ? address.id : null,
        userId: _userId,
        address: address.fullAddress,
        state: address.state,
        createdAt: isEdit ? null : address.createdAt,
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        return _message('Could not save address: ${response.displayMessage}');
      }
      await _loadUserAddresses();
      _message(isEdit ? 'Address updated.' : 'Address added.');
    } catch (error) {
      _message('Could not save address: $error');
    }
  }

  Future<_GpsAddress> _fetchAddressFromGps() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please turn on device location services.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Enable location permission from app settings.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return _reverseGeocode(position.latitude, position.longitude);
  }

  Future<_GpsAddress> _reverseGeocode(double latitude, double longitude) async {
    var nativeHouse = '';
    var nativeCity = '';
    var nativePostalCode = '';
    var nativeState = '';
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          nativeHouse = [place.subThoroughfare, place.name]
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) {
                return value.isNotEmpty;
              })
              .toSet()
              .join(', ');
          nativeCity = place.locality?.trim().isNotEmpty == true
              ? place.locality!.trim()
              : (place.subAdministrativeArea?.trim() ?? '');
          nativePostalCode = place.postalCode?.trim() ?? '';
          nativeState = place.administrativeArea?.trim() ?? '';
        }
      } catch (_) {
        // Nominatim fallback below still provides usable address details.
      }
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'zoom': '18',
      'addressdetails': '1',
      'extratags': '1',
      'namedetails': '1',
    });
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': 'en',
      if (!kIsWeb) 'User-Agent': 'SahubyteUserApp/1.0',
    };
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Could not fetch address from GPS.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final address = Map<String, dynamic>.from(json['address'] as Map? ?? {});

    String pick(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final displayName = json['display_name']?.toString() ?? '';
    final house = [
      nativeHouse,
      pick(['house_name']),
      pick(['house_number']),
      pick([
        'building',
        'amenity',
        'shop',
        'office',
        'residential',
        'block',
        'apartments',
      ]),
    ].where((value) => value.isNotEmpty).join(', ');
    final street = [
      pick(['road', 'pedestrian', 'footway']),
      pick(['neighbourhood', 'suburb', 'quarter', 'locality', 'city_district']),
    ].where((value) => value.isNotEmpty).join(', ');
    final pincode = pick(['postcode']);
    final city = pick(['city', 'town', 'village', 'municipality', 'county']);
    final state = matchIndianState(
      pick(['state', 'region']).isNotEmpty
          ? pick(['state', 'region'])
          : nativeState,
    );

    return _GpsAddress(
      pincode: pincode.isNotEmpty ? pincode : nativePostalCode,
      city: city.isNotEmpty ? city : nativeCity,
      state: state,
      house: house.isNotEmpty ? house : pick(['residential']),
      street: street.isNotEmpty
          ? street
          : displayName.split(',').take(2).join(', '),
    );
  }

  Future<void> _editProfile() async {
    if (_isGuest) return _loginRequired('profile editing');
    final nameController = TextEditingController(text: _name);
    final mobileController = TextEditingController(text: _mobile);
    final emailController = TextEditingController(text: _email);
    final dobController = TextEditingController(text: _dob);
    var selectedProfileState = _state;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
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
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const AppSectionTitle(
                  'Edit personal information',
                  subtitle:
                      'Keep your profile details accurate and up to date.',
                ),
                const SizedBox(height: 18),
                const AppFieldLabel('Full name'),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                const AppFieldLabel('Mobile number'),
                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter your mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                const AppFieldLabel('Email address'),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                const AppFieldLabel('Date of birth'),
                TextField(
                  controller: dobController,
                  readOnly: true,
                  onTap: () => _pickProfileDob(dobController),
                  decoration: InputDecoration(
                    hintText: 'Select date of birth',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton.filledTonal(
                        tooltip: 'Open calendar',
                        onPressed: () => _pickProfileDob(dobController),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const AppFieldLabel('State'),
                StatefulBuilder(
                  builder: (context, setSheetState) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedProfileState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select state',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: indianStates
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(
                                state,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setSheetState(() => selectedProfileState = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(14),
                  radius: 18,
                  child: Row(
                    children: const [
                      _ProfileIcon(
                        Icons.event_available_rounded,
                        AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap the field to open a calendar. Your DOB will be saved as YYYY-MM-DD.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: _profileViewModel.isLoading
                      ? 'Updating profile...'
                      : 'Save changes',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: _profileViewModel.isLoading
                      ? null
                      : () => _saveProfile(
                          sheetContext,
                          nameController.text,
                          mobileController.text,
                          emailController.text,
                          dobController.text,
                          selectedProfileState,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    dobController.dispose();
  }

  Future<void> _saveProfile(
    BuildContext sheetContext,
    String name,
    String mobile,
    String email,
    String dob,
    String? state,
  ) async {
    final trimmedName = name.trim();
    final trimmedMobile = mobile.trim();
    final trimmedEmail = email.trim();
    final trimmedDob = dob.trim();
    if ([
      trimmedName,
      trimmedMobile,
      trimmedEmail,
      trimmedDob,
    ].any((value) => value.isEmpty)) {
      return _message('Please complete all personal information.');
    }
    if (_parseDob(trimmedDob) == null) {
      return _message('Please select a valid date of birth.');
    }

    if (_userId.isEmpty) {
      return _message('Please login again to update profile.');
    }

    try {
      final response = await _profileViewModel.updateProfile(
        id: _userId,
        name: trimmedName,
        mobile: trimmedMobile,
        email: trimmedEmail,
        dob: trimmedDob,
        state: state,
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        return _message('Could not update profile: ${response.displayMessage}');
      }
      setState(() {
        _name = trimmedName;
        _mobile = trimmedMobile;
        _email = trimmedEmail;
        _dob = trimmedDob;
        _state = state;
      });
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', trimmedName);
      await prefs.setString('mobile', trimmedMobile);
      await prefs.setString('email', trimmedEmail);
      await prefs.setString('dob', trimmedDob);
      if (state?.isNotEmpty == true) {
        await prefs.setString('state', state!);
        await prefs.setString('profile_state', state);
      }
      await _loadUserDetail();
      _message(response.message ?? 'Profile updated successfully.');
    } catch (error) {
      _message('Could not update profile: $error');
    }
  }

  Future<void> _pickProfileImage() async {
    if (_isGuest) return _loginRequired('profile photo upload');
    if (_userId.isEmpty) {
      return _message('Login again to update profile photo.');
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      var bytes = file?.bytes;
      if (file != null &&
          (bytes == null || bytes.isEmpty) &&
          !kIsWeb &&
          file.path?.isNotEmpty == true) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (file == null || bytes == null || bytes.isEmpty) {
        return _message('Please select a valid profile image.');
      }

      final extension = (file.extension ?? '').toLowerCase();
      final mimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final rawBase64 = base64Encode(bytes);
      final dataUri = 'data:$mimeType;base64,$rawBase64';
      setState(() => _profileImage = dataUri);

      final response = await _profileViewModel.updateProfile(
        id: _userId,
        name: _name.trim().isEmpty ? 'User' : _name.trim(),
        mobile: _mobile.trim(),
        email: _email.trim(),
        dob: _dob.trim().isEmpty ? null : _dob.trim(),
        state: _state,
        profileImageBase64: rawBase64,
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        return _message(
          'Photo selected, but server sync failed: ${response.displayMessage}',
        );
      }
      await _loadUserDetail();
      _message('Profile photo updated successfully.');
    } catch (error) {
      _message('Could not update profile photo: $error');
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _editAddress({int? index}) async {
    if (_isGuest) return _loginRequired('saved addresses');
    final existing = index == null ? null : _addresses[index];
    final nameController = TextEditingController(text: existing?.name ?? _name);
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final pincodeController = TextEditingController(
      text: existing?.pincode ?? '',
    );
    final cityController = TextEditingController(text: existing?.city ?? '');
    var selectedState = existing?.state;
    final houseController = TextEditingController(text: existing?.house ?? '');
    final areaController = TextEditingController(text: existing?.area ?? '');
    var selectedType = existing?.type ?? 'Home';
    var isDefault = existing?.isDefault ?? false;
    var isFetchingGps = false;
    var gpsStatus = 'Auto-fill pincode, city, house and street.';

    Future<void> fillAddressFromGps(StateSetter? setSheetState) async {
      if (isFetchingGps) return;
      setSheetState?.call(() {
        isFetchingGps = true;
        gpsStatus = 'Fetching your live location...';
      });
      try {
        final fetched = await _fetchAddressFromGps();
        if (fetched.pincode.isNotEmpty) {
          pincodeController.text = fetched.pincode;
        }
        if (fetched.city.isNotEmpty) {
          cityController.text = fetched.city;
        }
        if (fetched.state != null) {
          selectedState = fetched.state;
        }
        if (fetched.house.isNotEmpty) {
          houseController.text = fetched.house;
        }
        if (fetched.street.isNotEmpty) {
          areaController.text = fetched.street;
        }
        gpsStatus = fetched.summary;
        _message('GPS address fetched. Please confirm details.');
      } catch (error) {
        gpsStatus = 'Could not fetch GPS address. Try again.';
        _message(
          professionalErrorMessage(
            error,
            fallback: 'Location could not be detected. Please try again.',
          ),
        );
      } finally {
        setSheetState?.call(() => isFetchingGps = false);
      }
    }

    Widget detectLocationButton(StateSetter setSheetState) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IconButton(
          onPressed: isFetchingGps
              ? null
              : () => fillAddressFromGps(setSheetState),
          icon: isFetchingGps
              ? const SkeletonBox(width: 22, height: 22, radius: 7)
              : const Icon(Icons.my_location_rounded, color: AppColors.primary),
          tooltip: 'Detect Location',
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProfileEditSheet(
        title: index == null ? 'Add service address' : 'Edit service address',
        subtitle: 'Use complete details so technicians can reach faster.',
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navyDark, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x242E245F),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    color: AppColors.aqua,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart service location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pin the exact place and keep visit details ready.',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder: (context, setSheetState) => InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: isFetchingGps
                  ? null
                  : () => fillAddressFromGps(setSheetState),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sky,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .2),
                  ),
                ),
                child: Row(
                  children: [
                    detectLocationButton(setSheetState),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFetchingGps
                                ? 'Fetching live GPS address...'
                                : 'Fetch location with GPS',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            gpsStatus,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          AppSurfaceCard(
            padding: const EdgeInsets.all(14),
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProfileHeading(
                  'Contact person',
                  'Who should the technician call?',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Person name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Contact number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppSurfaceCard(
            padding: const EdgeInsets.all(14),
            radius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProfileHeading(
                  'Address details',
                  'Flat, area and city for accurate doorstep service',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Area pincode',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setSheetState) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        detectLocationButton(setSheetState),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            gpsStatus,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    hintText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setSheetState) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedState,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select state',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      items: indianStates
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(
                                state,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setSheetState(() => selectedState = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: houseController,
                  decoration: const InputDecoration(
                    hintText: 'House no, flat, building',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(
                    hintText: 'Street, area or landmark',
                    prefixIcon: Icon(Icons.signpost_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          StatefulBuilder(
            builder: (context, setSheetState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppFieldLabel('Save address as'),
                Row(
                  children: ['Home', 'Office', 'Other'].map((type) {
                    final selected = selectedType == type;
                    final icon = type == 'Office'
                        ? Icons.business_center_outlined
                        : type == 'Other'
                        ? Icons.add_location_alt_outlined
                        : Icons.home_work_outlined;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: type == 'Other' ? 0 : 8,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => setSheetState(() => selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.sky : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.line,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  icon,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  type,
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDefault,
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Make this my default service address',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'We will preselect it during checkout.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    onChanged: (value) =>
                        setSheetState(() => isDefault = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: index == null ? 'Save address' : 'Update address',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () async {
              final address = _SavedAddress(
                id: existing?.id,
                createdAt: existing?.createdAt ?? _nowForApi(),
                name: nameController.text.trim().isEmpty
                    ? _name
                    : nameController.text.trim(),
                phone: phoneController.text.trim().isEmpty
                    ? _mobile
                    : phoneController.text.trim(),
                pincode: pincodeController.text.trim(),
                city: cityController.text.trim(),
                state: selectedState,
                house: houseController.text.trim(),
                area: areaController.text.trim(),
                type: selectedType,
                isDefault: isDefault,
              );
              Navigator.pop(sheetContext);
              await _syncUserAddress(address: address, isEdit: index != null);
            },
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    pincodeController.dispose();
    cityController.dispose();
    houseController.dispose();
    areaController.dispose();
  }

  Future<void> _deleteAddress(int index) async {
    final removed = _addresses[index];
    setState(() => _addresses.removeAt(index));
    _message('${removed.type} address deleted. Syncing with server...');
    if (_userId.isEmpty || removed.id == null || removed.id!.isEmpty) return;

    try {
      final response = await _profileViewModel.saveUserAddress(
        act: 'delete',
        id: removed.id,
        userId: _userId,
        address: removed.fullAddress,
        state: removed.state,
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        setState(() => _addresses.insert(index, removed));
        return _message('Delete failed on server: ${response.displayMessage}');
      }
      await _loadUserAddresses();
      _message('Address deleted successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _addresses.insert(index, removed));
      _message('Delete failed on server: $error');
    }
  }

  String _paymentSubtitle(String type) {
    switch (type) {
      case 'UPI payment':
        return 'Pay securely with any UPI app';
      case 'Credit / Debit card':
        return 'Save a card reference for quick checkout';
      case 'SB Wallet':
        return 'Use your Sahubyte wallet balance';
      case 'Net banking':
        return 'Pay from your preferred bank';
      default:
        return 'Pay after technician visit';
    }
  }

  String _paymentBadge(String type) {
    switch (type) {
      case 'UPI payment':
        return 'UPI';
      case 'Credit / Debit card':
        return 'CARD';
      case 'SB Wallet':
        return 'WALLET';
      case 'Net banking':
        return 'BANK';
      default:
        return 'COD';
    }
  }

  IconData _paymentIcon(String type) {
    switch (type) {
      case 'UPI payment':
        return Icons.qr_code_2_rounded;
      case 'Credit / Debit card':
        return Icons.credit_card_rounded;
      case 'SB Wallet':
        return Icons.account_balance_wallet_outlined;
      case 'Net banking':
        return Icons.account_balance_rounded;
      default:
        return Icons.payments_outlined;
    }
  }

  Color _paymentColor(String type) {
    switch (type) {
      case 'UPI payment':
        return AppColors.primary;
      case 'Credit / Debit card':
        return AppColors.coral;
      case 'SB Wallet':
        return AppColors.primaryDark;
      case 'Net banking':
        return AppColors.navy;
      default:
        return AppColors.success;
    }
  }

  Future<void> _editPayment({int? index}) async {
    if (_isGuest) return _loginRequired('payment methods');
    const paymentTypes = [
      'Cash on delivery',
      'UPI payment',
      'Credit / Debit card',
      'SB Wallet',
      'Net banking',
    ];
    final existing = index == null ? null : _payments[index];
    var selectedPayment = paymentTypes.contains(existing?.label)
        ? existing!.label
        : paymentTypes.first;
    final subtitleController = TextEditingController(
      text: existing?.subtitle ?? _paymentSubtitle(selectedPayment),
    );
    final upiController = TextEditingController();
    final cardHolderController = TextEditingController();
    final cardLast4Controller = TextEditingController();
    final walletMobileController = TextEditingController();
    final bankController = TextEditingController();
    if (existing != null) {
      if (selectedPayment == 'UPI payment') {
        upiController.text = existing.detail;
      } else if (selectedPayment == 'Credit / Debit card') {
        cardHolderController.text = existing.detail;
      } else if (selectedPayment == 'SB Wallet') {
        walletMobileController.text = existing.detail.replaceFirst(
          'Wallet linked to ',
          '',
        );
      } else if (selectedPayment == 'Net banking') {
        bankController.text = existing.detail;
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProfileEditSheet(
        title: index == null ? 'Add payment method' : 'Edit payment method',
        subtitle: 'Create a clear payment option for your bookings.',
        children: [
          StatefulBuilder(
            builder: (context, setSheetState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppFieldLabel('Payment type'),
                DropdownButtonFormField<String>(
                  initialValue: selectedPayment,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.payment_outlined),
                  ),
                  items: paymentTypes
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() {
                      selectedPayment = value;
                      subtitleController.text = _paymentSubtitle(value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _paymentColor(
                      selectedPayment,
                    ).withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _paymentColor(
                        selectedPayment,
                      ).withValues(alpha: .18),
                    ),
                  ),
                  child: Row(
                    children: [
                      _ProfileIcon(
                        _paymentIcon(selectedPayment),
                        _paymentColor(selectedPayment),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPayment,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _paymentSubtitle(selectedPayment),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _MiniBadge(
                        _paymentBadge(selectedPayment),
                        _paymentColor(selectedPayment),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (selectedPayment == 'UPI payment') ...[
                  const AppFieldLabel('UPI ID'),
                  TextField(
                    controller: upiController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'name@upi',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                ] else if (selectedPayment == 'Credit / Debit card') ...[
                  const AppFieldLabel('Card holder name'),
                  TextField(
                    controller: cardHolderController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Name on card',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const AppFieldLabel('Card last 4 digits'),
                  TextField(
                    controller: cardLast4Controller,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '1234',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                ] else if (selectedPayment == 'SB Wallet') ...[
                  const AppFieldLabel('Wallet mobile number'),
                  TextField(
                    controller: walletMobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Linked mobile number',
                      prefixIcon: Icon(Icons.phone_iphone_rounded),
                    ),
                  ),
                ] else if (selectedPayment == 'Net banking') ...[
                  const AppFieldLabel('Bank name'),
                  TextField(
                    controller: bankController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'HDFC, SBI, ICICI...',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                ] else
                  const AppSurfaceCard(
                    padding: EdgeInsets.all(14),
                    radius: 18,
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No extra details needed. You will pay after service completion.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppFieldLabel('Description'),
          TextField(
            controller: subtitleController,
            decoration: const InputDecoration(
              hintText: 'Short payment note',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: index == null ? 'Save payment' : 'Update payment',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () {
              final detail = switch (selectedPayment) {
                'UPI payment' =>
                  upiController.text.trim().isEmpty
                      ? 'UPI ID not added'
                      : upiController.text.trim(),
                'Credit / Debit card' =>
                  cardLast4Controller.text.trim().isEmpty
                      ? 'Card reference added'
                      : '${cardHolderController.text.trim().isEmpty ? 'Card' : cardHolderController.text.trim()} ending ${cardLast4Controller.text.trim()}',
                'SB Wallet' =>
                  walletMobileController.text.trim().isEmpty
                      ? 'Linked wallet account'
                      : 'Wallet linked to ${walletMobileController.text.trim()}',
                'Net banking' =>
                  bankController.text.trim().isEmpty
                      ? 'Preferred bank not selected'
                      : bankController.text.trim(),
                _ => 'No online payment needed',
              };
              final payment = _PaymentMethod(
                label: selectedPayment,
                subtitle: subtitleController.text.trim().isEmpty
                    ? _paymentSubtitle(selectedPayment)
                    : subtitleController.text.trim(),
                detail: detail,
                trailing: _paymentBadge(selectedPayment),
                icon: _paymentIcon(selectedPayment),
                color: _paymentColor(selectedPayment),
              );
              setState(() {
                if (index == null) {
                  _payments.add(payment);
                } else {
                  _payments[index] = payment;
                }
              });
              Navigator.pop(sheetContext);
              _message(
                index == null ? 'Payment method added.' : 'Payment updated.',
              );
            },
          ),
        ],
      ),
    );

    subtitleController.dispose();
    upiController.dispose();
    cardHolderController.dispose();
    cardLast4Controller.dispose();
    walletMobileController.dispose();
    bankController.dispose();
  }

  void _deletePayment(int index) {
    final removed = _payments[index];
    setState(() => _payments.removeAt(index));
    _message('${removed.label} deleted.');
  }

  void _openAddresses() {
    if (_isGuest) return _loginRequired('saved addresses');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SavedAddressesView(
          addresses: _addresses,
          onAdd: () => _editAddress(),
          onEdit: (index) => _editAddress(index: index),
          onDelete: (index) async => _deleteAddress(index),
        ),
      ),
    );
  }

  void _openPayments() {
    if (_isGuest) return _loginRequired('payment methods');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PaymentMethodsView(
          payments: _payments,
          onAdd: () => _editPayment(),
          onEdit: (index) => _editPayment(index: index),
          onDelete: (index) async => _deletePayment(index),
        ),
      ),
    );
  }

  void _openInvoices() {
    if (_isGuest) return _loginRequired('invoices');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoicesReceiptsView(userId: _userId)),
    );
  }

  void _openHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpCenterView()),
    );
  }

  void _openPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyView()),
    );
  }

  void _openTermsAndConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsAndConditionsView()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageHeader(title: 'My profile', showBack: false),
    body: _isSessionLoading || (_isProfileLoading && !_isGuest)
        ? const _ProfileSkeletonView()
        : RefreshIndicator(
            onRefresh: _refreshProfileData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                AppHeroCard(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: _pickProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _ProfileAvatarImage(
                                    image: _profileImage,
                                    name: _displayName,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    width: 27,
                                    height: 27,
                                    decoration: BoxDecoration(
                                      color: AppColors.aqua,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 14,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 6),
                                Text(
                                  _displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  _isGuest
                                      ? 'Login to unlock your account'
                                      : 'Sahubyte User',
                                  style: TextStyle(color: Color(0xCCFFFFFF)),
                                ),
                                SizedBox(height: 9),
                                _ProfileBadge(isGuest: _isGuest),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _isGuest ? _goToLogin : _editProfile,
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _ProfileHeading(
                  'Personal information',
                  'Your account and contact details',
                ),
                const SizedBox(height: 10),
                AppSurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      _ProfileDetail(
                        Icons.person_outline_rounded,
                        'Full name',
                        _displayName,
                        onTap: _editProfile,
                      ),
                      const _ProfileDivider(),
                      _ProfileDetail(
                        Icons.phone_outlined,
                        'Mobile number',
                        _displayMobile,
                        onTap: _editProfile,
                      ),
                      const _ProfileDivider(),
                      _ProfileDetail(
                        Icons.mail_outline_rounded,
                        'Email address',
                        _displayEmail,
                        onTap: _editProfile,
                      ),
                      const _ProfileDivider(),
                      _ProfileDetail(
                        Icons.calendar_month_outlined,
                        'Date of birth',
                        _displayDob,
                        onTap: _editProfile,
                      ),
                      const _ProfileDivider(),
                      _ProfileDetail(
                        Icons.map_outlined,
                        'State',
                        _displayState,
                        onTap: _editProfile,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _ProfileHeading(
                  'Account essentials',
                  'Manage locations, payments and billing',
                ),
                const SizedBox(height: 10),
                AppSurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      _ProfileAction(
                        _isGuest
                            ? Icons.lock_outline_rounded
                            : Icons.location_on_outlined,
                        'Saved addresses',
                        _isGuest
                            ? 'Login required to manage addresses'
                            : '${_addresses.length} locations ready',
                        AppColors.primary,
                        onTap: _openAddresses,
                      ),
                      const _ProfileDivider(),
                      _ProfileAction(
                        _isGuest
                            ? Icons.lock_outline_rounded
                            : Icons.payment_outlined,
                        'Payment methods',
                        _isGuest
                            ? 'Login required to manage payments'
                            : '${_payments.length} options available',
                        AppColors.success,
                        onTap: _openPayments,
                      ),
                      const _ProfileDivider(),
                      _ProfileAction(
                        Icons.receipt_long_outlined,
                        'Invoices and receipts',
                        _isGuest
                            ? 'Login required to download invoices'
                            : 'Download billing history',
                        AppColors.coral,
                        onTap: _openInvoices,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _ProfileHeading(
                  'Support and settings',
                  'Control your experience and get help',
                ),
                const SizedBox(height: 10),
                AppSurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      _ProfileAction(
                        Icons.support_agent_outlined,
                        'Help center',
                        'FAQs and customer assistance',
                        AppColors.coral,
                        onTap: _openHelpCenter,
                      ),
                      const _ProfileDivider(),
                      _ProfileAction(
                        Icons.policy_outlined,
                        'Privacy policy',
                        'How your information is handled',
                        AppColors.success,
                        onTap: _openPrivacyPolicy,
                      ),
                      const _ProfileDivider(),
                      _ProfileAction(
                        Icons.description_outlined,
                        'Terms and conditions',
                        'Service rules and user responsibilities',
                        AppColors.primary,
                        onTap: _openTermsAndConditions,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_isGuest)
                  ElevatedButton.icon(
                    onPressed: _goToLogin,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Login to unlock all features'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      // ✅ Confirm before logging out
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Log out'),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Log out',
                                style: TextStyle(color: Color(0xFFE45858)),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginView()),
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE45858),
                      side: const BorderSide(color: Color(0x33E45858)),
                    ),
                  ),
              ],
            ),
          ),
  );
}

class _ProfileAvatarImage extends StatelessWidget {
  const _ProfileAvatarImage({required this.image, required this.name});

  final String? image;
  final String name;

  @override
  Widget build(BuildContext context) {
    final value = image?.trim() ?? '';
    if (value.startsWith('data:image')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex != -1) {
        try {
          return CircleAvatar(
            radius: 38,
            backgroundImage: MemoryImage(
              base64Decode(value.substring(commaIndex + 1)),
            ),
          );
        } catch (_) {}
      }
    }

    if (value.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: 76,
          height: 76,
          child: _NetworkImageWithFallback(
            urls: _profileImageCandidates(value),
            fallbackIcon: Icons.person_rounded,
          ),
        ),
      );
    }

    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 38,
      backgroundColor: AppColors.sky,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

List<String> _profileImageCandidates(String value) {
  final path = value.trim();
  if (path.isEmpty) return const [];
  if (path.startsWith('http://') || path.startsWith('https://')) {
    final fixed = path
        .replaceAll(r'\/', '/')
        .replaceFirst('/sahubyte/uploads/', '/sahubyte/public/uploads/');
    return [fixed];
  }

  final root = ApiConstants.userBaseUrl.replaceFirst('/userApi/', '/');
  final normalized = path
      .replaceAll(r'\/', '/')
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/+'), '/')
      .replaceFirst(RegExp(r'^/+'), '');

  var uploadPath = normalized;
  if (uploadPath.startsWith('sahubyte/public/uploads/')) {
    uploadPath = uploadPath.substring('sahubyte/public/uploads/'.length);
  } else if (uploadPath.startsWith('public/uploads/')) {
    uploadPath = uploadPath.substring('public/uploads/'.length);
  } else if (uploadPath.startsWith('uploads/')) {
    uploadPath = uploadPath.substring('uploads/'.length);
  }

  final cleanedUploadPath = uploadPath.replaceFirst(RegExp(r'^/+'), '');
  final fileName = cleanedUploadPath.split('/').last;

  return <String>{
    '${root}public/uploads/$cleanedUploadPath',
    if (!cleanedUploadPath.startsWith('userprofile/'))
      '${root}public/uploads/userprofile/$fileName',
  }.toList();
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.isGuest});
  final bool isGuest;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0x22FFFFFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isGuest ? Icons.lock_outline_rounded : Icons.verified_rounded,
          color: AppColors.aqua,
          size: 14,
        ),
        const SizedBox(width: 5),
        Text(
          isGuest ? 'Guest mode' : 'Verified profile',
          style: const TextStyle(
            color: AppColors.aqua,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ProfileSkeletonView extends StatelessWidget {
  const _ProfileSkeletonView();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    children: const [
      AppHeroCard(
        child: Row(
          children: [
            _SkeletonBox(
              width: 82,
              height: 82,
              radius: 41,
              color: Color(0x33FFFFFF),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(
                    width: 170,
                    height: 18,
                    color: Color(0x44FFFFFF),
                  ),
                  SizedBox(height: 10),
                  _SkeletonBox(
                    width: 118,
                    height: 12,
                    color: Color(0x30FFFFFF),
                  ),
                  SizedBox(height: 14),
                  _SkeletonBox(
                    width: 96,
                    height: 24,
                    radius: 20,
                    color: Color(0x28FFFFFF),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 20),
      _SkeletonSection(lines: 4),
      SizedBox(height: 20),
      _SkeletonSection(lines: 3),
      SizedBox(height: 20),
      _SkeletonSection(lines: 3),
      SizedBox(height: 18),
      _SkeletonBox(width: double.infinity, height: 52, radius: 18),
    ],
  );
}

class _SkeletonSection extends StatelessWidget {
  const _SkeletonSection({required this.lines});
  final int lines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SkeletonBox(width: 165, height: 18),
      const SizedBox(height: 7),
      const _SkeletonBox(width: 230, height: 12),
      const SizedBox(height: 10),
      AppSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: List.generate(lines, (index) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      _SkeletonBox(width: 42, height: 42, radius: 14),
                      SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SkeletonBox(width: 86, height: 11),
                            SizedBox(height: 8),
                            _SkeletonBox(width: 150, height: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != lines - 1) const _ProfileDivider(),
              ],
            );
          }),
        ),
      ),
    ],
  );
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 12,
    this.color = const Color(0xFFE9EAF3),
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _SavedAddress {
  const _SavedAddress({
    this.id,
    this.createdAt,
    required this.name,
    required this.phone,
    required this.pincode,
    required this.city,
    required this.state,
    required this.house,
    required this.area,
    required this.type,
    required this.isDefault,
  });
  final String? id;
  final String? createdAt;
  final String name;
  final String phone;
  final String pincode;
  final String city;
  final String? state;
  final String house;
  final String area;
  final String type;
  final bool isDefault;

  String get fullAddress {
    final parts = [
      house,
      area,
      city,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    if (pincode.trim().isEmpty) return parts;
    return parts.isEmpty ? pincode : '$parts - $pincode';
  }

  IconData get icon {
    if (type == 'Office') return Icons.business_center_outlined;
    if (type == 'Other') return Icons.add_location_alt_outlined;
    return Icons.home_work_outlined;
  }

  Color get color {
    if (type == 'Office') return AppColors.success;
    if (type == 'Other') return AppColors.coral;
    return AppColors.primary;
  }
}

class _GpsAddress {
  const _GpsAddress({
    required this.pincode,
    required this.city,
    required this.state,
    required this.house,
    required this.street,
  });

  final String pincode;
  final String city;
  final String? state;
  final String house;
  final String street;

  String get summary {
    final parts = [
      city,
      state ?? '',
      pincode,
    ].where((value) => value.trim().isNotEmpty).join(', ');
    return parts.isEmpty
        ? 'Location fetched. Please confirm address details.'
        : 'Fetched $parts';
  }
}

class _PaymentMethod {
  const _PaymentMethod({
    required this.label,
    required this.subtitle,
    required this.detail,
    required this.trailing,
    required this.icon,
    required this.color,
  });
  final String label;
  final String subtitle;
  final String detail;
  final String trailing;
  final IconData icon;
  final Color color;
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });
  final _SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _ProfileIcon(address.icon, address.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.type,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniBadge(
                        address.isDefault ? 'Default' : address.type,
                        address.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${address.name}  |  ${address.phone}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          address.fullAddress,
          style: const TextStyle(color: AppColors.text, height: 1.35),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE45858),
                  minimumSize: const Size(0, 42),
                  side: const BorderSide(color: Color(0x33E45858)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onEdit,
    required this.onDelete,
  });
  final _PaymentMethod payment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        _ProfileIcon(payment.icon, payment.color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _MiniBadge(payment.trailing, payment.color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                payment.subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (payment.detail.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: payment.color,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          payment.detail,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE45858),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SavedAddressesView extends StatefulWidget {
  const _SavedAddressesView({
    required this.addresses,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final List<_SavedAddress> addresses;
  final Future<void> Function() onAdd;
  final Future<void> Function(int) onEdit;
  final Future<void> Function(int) onDelete;

  @override
  State<_SavedAddressesView> createState() => _SavedAddressesViewState();
}

class _SavedAddressesViewState extends State<_SavedAddressesView> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageHeader(title: 'Saved addresses'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const AppHeroCard(
          child: AppScreenIntro(
            title: 'Service locations',
            subtitle:
                'Manage every place where Sahubyte technicians can visit.',
            icon: Icons.location_on_outlined,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: _ProfileHeading(
                'Your addresses',
                'Edit or delete saved service locations',
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await widget.onAdd();
                setState(() {});
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.addresses.isEmpty)
          const _EmptyProfileState(
            icon: Icons.add_location_alt_outlined,
            title: 'No saved addresses',
            subtitle: 'Add your first location for faster service booking.',
          )
        else
          ...widget.addresses.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AddressCard(
                address: entry.value,
                onEdit: () async {
                  await widget.onEdit(entry.key);
                  setState(() {});
                },
                onDelete: () async {
                  await widget.onDelete(entry.key);
                  setState(() {});
                },
              ),
            ),
          ),
      ],
    ),
  );
}

class _PaymentMethodsView extends StatefulWidget {
  const _PaymentMethodsView({
    required this.payments,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final List<_PaymentMethod> payments;
  final Future<void> Function() onAdd;
  final Future<void> Function(int) onEdit;
  final Future<void> Function(int) onDelete;

  @override
  State<_PaymentMethodsView> createState() => _PaymentMethodsViewState();
}

class _PaymentMethodsViewState extends State<_PaymentMethodsView> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageHeader(title: 'Payment methods'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const AppHeroCard(
          child: Row(
            children: [
              _PaymentHeroIcon(),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Manage how you prefer to pay for Sahubyte services.',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
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
        Row(
          children: [
            const Expanded(
              child: _ProfileHeading(
                'Your payment options',
                'Edit or delete checkout methods',
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await widget.onAdd();
                setState(() {});
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (widget.payments.isEmpty)
          const _EmptyProfileState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No payment methods',
            subtitle: 'Add a payment option for smoother checkout.',
          )
        else
          ...widget.payments.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaymentCard(
                payment: entry.value,
                onEdit: () async {
                  await widget.onEdit(entry.key);
                  setState(() {});
                },
                onDelete: () async {
                  await widget.onDelete(entry.key);
                  setState(() {});
                },
              ),
            ),
          ),
      ],
    ),
  );
}

class _PaymentHeroIcon extends StatelessWidget {
  const _PaymentHeroIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.payment_outlined, color: AppColors.primary),
  );
}

class _EmptyProfileState extends StatelessWidget {
  const _EmptyProfileState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    child: Column(
      children: [
        _ProfileIcon(icon, AppColors.primary),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _ProfileEditSheet extends StatelessWidget {
  const _ProfileEditSheet({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppSectionTitle(title, subtitle: subtitle),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _ProfileHeading extends StatelessWidget {
  const _ProfileHeading(this.title, this.subtitle);
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    ],
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail(this.icon, this.label, this.value, {this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _ProfileIcon(icon, AppColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: AppColors.muted, size: 17),
        ],
      ),
    ),
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction(
    this.icon,
    this.title,
    this.subtitle,
    this.color, {
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _ProfileIcon(icon, color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.muted,
            size: 15,
          ),
        ],
      ),
    ),
  );
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .11),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 19),
  );
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1);
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.icon,
    required this.items,
  });
  final String title;
  final String headline;
  final String subtitle;
  final IconData icon;
  final List<Widget> items;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageHeader(title: title, showBack: false),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        AppHeroCard(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.aqua, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...items.expand((item) => [item, const SizedBox(height: 10)]),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  @override
  Widget build(BuildContext context) => AppSurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        _IconBox(icon, color),
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
        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ],
    ),
  );
}
