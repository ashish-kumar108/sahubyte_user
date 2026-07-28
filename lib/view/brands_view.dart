import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/response/service_category_model.dart';
import 'package:sahubyte_user/repository/service_catalog_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/report_problem_view.dart';

class BrandsView extends StatefulWidget {
  final String serviceType;
  final String applicationName;
  final String categoryId;
  final String categoryName;
  final String subCategoryId;
  final String subCategoryName;
  const BrandsView({
    super.key,
    this.serviceType = 'Software',
    required this.applicationName,
    required this.categoryId,
    required this.categoryName,
    required this.subCategoryId,
    required this.subCategoryName,
  });

  @override
  State<BrandsView> createState() => _BrandsViewState();
}

class _BrandsViewState extends State<BrandsView> {
  final _serviceCatalogRepository = ServiceCatalogRepository();
  final _searchController = TextEditingController();
  String _query = '';
  late Future<List<ServiceBrandModel>> _brandsFuture;

  @override
  void initState() {
    super.initState();
    _brandsFuture = _fetchBrands();
  }

  Future<List<ServiceBrandModel>> _fetchBrands() =>
      _serviceCatalogRepository.getBrands(
        categoryId: widget.categoryId,
        subCategoryId: widget.subCategoryId,
      );

  Future<void> _refreshBrands() async {
    final future = _fetchBrands();
    setState(() => _brandsFuture = future);
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
      appBar: const AppPageHeader(title: 'Choose a brand', showCart: true),
      body: Column(
        children: [
          AppBookingHero(
            step: 3,
            totalSteps: 8,
            title: 'Choose a brand',
            subtitle:
                'Select the brand for your ${widget.applicationName.toLowerCase()} so we can tailor the next steps.',
            icon: Icons.business_center_outlined,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Search service brands',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<ServiceBrandModel>>(
              future: _brandsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _BrandGridSkeleton();
                }
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _refreshBrands,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        AppSurfaceCard(
                          child: Text(
                            'Brands could not be refreshed. Pull down to try again.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final allBrands = snapshot.data ?? const [];
                final query = _query.trim().toLowerCase();
                final brands = query.isEmpty
                    ? allBrands
                    : allBrands
                          .where(
                            (brand) => brand.name.toLowerCase().contains(query),
                          )
                          .toList();
                if (allBrands.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshBrands,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        AppSurfaceCard(
                          child: Text(
                            'No brands available right now.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (brands.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshBrands,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AppSearchEmptyState(
                          query: _query,
                          label: 'brand',
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
                  onRefresh: _refreshBrands,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _brandColumnCount(
                        MediaQuery.sizeOf(context).width,
                      ),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: brands.length,
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportProblemView(
                                applicationName: widget.applicationName,
                                serviceType: widget.serviceType,
                                categoryId: widget.categoryId,
                                categoryName: widget.categoryName,
                                subCategoryId: widget.subCategoryId,
                                subCategoryName: widget.subCategoryName,
                                brandId: brand.id,
                                brandName: brand.name,
                              ),
                            ),
                          );
                        },
                        child: _BrandTile(brand: brand),
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

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand});

  final ServiceBrandModel brand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.9;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F2740),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _NetworkImageWithFallback(
                    urls: brand.imageCandidates,
                    fallbackIcon: Icons.business_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              brand.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
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
      return Icon(widget.fallbackIcon, color: AppColors.muted, size: 32);
    }

    return Image.network(
      widget.urls[_index],
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _index += 1);
        });
        return Icon(widget.fallbackIcon, color: AppColors.muted, size: 32);
      },
    );
  }
}

class _BrandGridSkeleton extends StatelessWidget {
  const _BrandGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _brandColumnCount(MediaQuery.sizeOf(context).width),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: 70,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
  }
}

int _brandColumnCount(double width) => width >= 600 ? 4 : 3;
