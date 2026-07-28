import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/response/service_category_model.dart';
import 'package:sahubyte_user/repository/service_catalog_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/brands_view.dart';

class BrandApplicationsView extends StatefulWidget {
  final String categoryId;
  final String serviceType;
  const BrandApplicationsView({
    super.key,
    required this.categoryId,
    this.serviceType = 'Software',
  });

  @override
  State<BrandApplicationsView> createState() => _BrandApplicationsViewState();
}

class _BrandApplicationsViewState extends State<BrandApplicationsView> {
  final _serviceCatalogRepository = ServiceCatalogRepository();
  final _searchController = TextEditingController();
  String _query = '';
  late Future<List<ServiceSubCategoryModel>> _subCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _subCategoriesFuture = _fetchSubCategories();
  }

  Future<List<ServiceSubCategoryModel>> _fetchSubCategories() =>
      _serviceCatalogRepository.getSubCategories(categoryId: widget.categoryId);

  Future<void> _refreshSubCategories() async {
    final future = _fetchSubCategories();
    setState(() => _subCategoriesFuture = future);
    await future;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageHeader(title: 'Choose sub category', showCart: true),
      body: Column(
        children: [
          AppBookingHero(
            step: 2,
            totalSteps: 8,
            title: 'Choose sub category',
            subtitle:
                'Select the device or service type first. Brand selection comes next.',
            icon: Icons.devices_other_rounded,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Search sub category',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<ServiceSubCategoryModel>>(
              future: _subCategoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SubCategoryGridSkeleton();
                }
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _refreshSubCategories,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        AppSurfaceCard(
                          child: Text(
                            'Sub categories could not be refreshed. Pull down to try again.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final allSubCategories = snapshot.data ?? const [];
                final query = _query.trim().toLowerCase();
                final subCategories = query.isEmpty
                    ? allSubCategories
                    : allSubCategories
                          .where(
                            (item) => item.name.toLowerCase().contains(query),
                          )
                          .toList();
                if (allSubCategories.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshSubCategories,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        AppSurfaceCard(
                          child: Text(
                            'No sub categories available for this service.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (subCategories.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshSubCategories,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AppSearchEmptyState(
                          query: _query,
                          label: 'sub category',
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refreshSubCategories,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width < 350
                          ? 1
                          : 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                      childAspectRatio: MediaQuery.sizeOf(context).width < 350
                          ? 1.8
                          : 0.88,
                    ),
                    itemCount: subCategories.length,
                    itemBuilder: (context, index) {
                      final subCategory = subCategories[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BrandsView(
                                applicationName: subCategory.name,
                                categoryId: widget.categoryId,
                                categoryName: widget.serviceType,
                                subCategoryId: subCategory.id,
                                subCategoryName: subCategory.name,
                                serviceType: widget.serviceType,
                              ),
                            ),
                          );
                        },
                        child: _SubCategoryCard(subCategory: subCategory),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCategoryCard extends StatelessWidget {
  const _SubCategoryCard({required this.subCategory});

  final ServiceSubCategoryModel subCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appSurface(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _NetworkImageWithFallback(
                    urls: subCategory.imageCandidates,
                    fallbackIcon: Icons.devices_other_rounded,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0x770A1022)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subCategory.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      child: Center(child: Icon(icon, color: AppColors.primary, size: 42)),
    );
  }
}

class _SubCategoryGridSkeleton extends StatelessWidget {
  const _SubCategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width < 350 ? 1 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: MediaQuery.sizeOf(context).width < 350 ? 1.8 : 0.88,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: appSurface(radius: 20),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 13,
                width: double.infinity,
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
