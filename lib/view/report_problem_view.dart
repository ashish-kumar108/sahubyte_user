import 'package:flutter/material.dart';
import 'package:sahubyte_user/model/response/service_problem_model.dart';
import 'package:sahubyte_user/repository/service_catalog_repository.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/select_address_view.dart';

class ReportProblemView extends StatefulWidget {
  final String applicationName;
  final String serviceType;
  final String categoryId;
  final String categoryName;
  final String subCategoryId;
  final String subCategoryName;
  final String brandId;
  final String brandName;
  const ReportProblemView({
    super.key,
    required this.applicationName,
    required this.categoryId,
    required this.categoryName,
    required this.subCategoryId,
    required this.subCategoryName,
    required this.brandId,
    required this.brandName,
    this.serviceType = 'Software',
  });

  @override
  State<ReportProblemView> createState() => _ReportProblemViewState();
}

class _ReportProblemViewState extends State<ReportProblemView> {
  final _serviceCatalogRepository = ServiceCatalogRepository();
  final _searchController = TextEditingController();
  String _query = '';
  late Future<List<ServiceProblemModel>> _problemsFuture;

  @override
  void initState() {
    super.initState();
    _problemsFuture = _fetchProblems();
  }

  Future<List<ServiceProblemModel>> _fetchProblems() =>
      _serviceCatalogRepository.getProblems(
        categoryId: widget.categoryId,
        subCategoryId: widget.subCategoryId,
      );

  Future<void> _refreshProblems() async {
    final future = _fetchProblems();
    setState(() => _problemsFuture = future);
    await future;
  }

  final Set<String> _selectedProblemIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageHeader(title: '${widget.serviceType} support'),
      body: Column(
        children: [
          AppBookingHero(
            step: 4,
            totalSteps: 8,
            title: 'What went wrong?',
            subtitle:
                'Choose the issue that best matches your ${widget.applicationName.toLowerCase()}. Its charge will be payable after the job card is created.',
            icon: Icons.support_agent_rounded,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSearchField(
              hint: 'Search for your issue',
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<List<ServiceProblemModel>>(
              future: _problemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ProblemGridSkeleton();
                }
                if (snapshot.hasError) {
                  return RefreshIndicator(
                    onRefresh: _refreshProblems,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        AppSurfaceCard(
                          child: Text(
                            'Issues could not be refreshed. Pull down to try again.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final allProblems = snapshot.data ?? const [];
                final query = _query.trim().toLowerCase();
                final problems = query.isEmpty
                    ? allProblems
                    : allProblems.where((problem) {
                        return '${problem.name} ${problem.description}'
                            .toLowerCase()
                            .contains(query);
                      }).toList();
                if (allProblems.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshProblems,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: const [
                        AppSurfaceCard(
                          child: Text(
                            'No problems are mapped for this category yet.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (problems.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refreshProblems,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AppSearchEmptyState(
                          query: _query,
                          label: 'issue',
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
                  onRefresh: _refreshProblems,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width < 350
                          ? 1
                          : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: MediaQuery.sizeOf(context).width < 350
                          ? 92
                          : 108,
                    ),
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      final problem = problems[index];
                      final isSelected = _selectedProblemIds.contains(
                        problem.id,
                      );
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedProblemIds.remove(problem.id);
                            } else {
                              _selectedProblemIds.add(problem.id);
                            }
                          });
                        },
                        child: _ProblemTile(
                          problem: problem,
                          isSelected: isSelected,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          FutureBuilder<List<ServiceProblemModel>>(
            future: _problemsFuture,
            builder: (context, snapshot) {
              final problems = snapshot.data ?? const [];
              return AppBottomAction(
                label: 'Continue',
                onPressed: problems.isEmpty
                    ? null
                    : () {
                        if (_selectedProblemIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one problem',
                              ),
                            ),
                          );
                          return;
                        }
                        final selectedProblems =
                            problems
                                .where(
                                  (problem) =>
                                      _selectedProblemIds.contains(problem.id),
                                )
                                .toList()
                              ..sort((a, b) => a.name.compareTo(b.name));
                        final problemTitle = selectedProblems
                            .map((problem) => problem.name)
                            .join(', ');
                        final problemDetails = selectedProblems.map((problem) {
                          return {
                            'problemId': problem.id,
                            'problemName': problem.name,
                            'price': problem.price,
                            'problemDescription': problem.description,
                          };
                        }).toList();
                        final problemCharge = selectedProblems.fold<int>(
                          0,
                          (sum, problem) => sum + problem.price,
                        );
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
                              problemIds: selectedProblems
                                  .map((problem) => problem.id)
                                  .toList(),
                              problemDetails: problemDetails,
                              problemTitle: problemTitle,
                              problemCharge: problemCharge,
                              serviceType: widget.serviceType,
                            ),
                          ),
                        );
                      },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProblemTile extends StatelessWidget {
  const _ProblemTile({required this.problem, required this.isSelected});

  final ServiceProblemModel problem;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.line,
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
        color: isSelected ? AppColors.sky : AppColors.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: .12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _NetworkImageWithFallback(
                    urls: problem.imageCandidates,
                    color: isSelected ? AppColors.primary : AppColors.navy,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rs. ${problem.price}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              problem.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkImageWithFallback extends StatefulWidget {
  const _NetworkImageWithFallback({required this.urls, required this.color});

  final List<String> urls;
  final Color color;

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
      return Icon(Icons.build_circle_outlined, size: 18, color: widget.color);
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Image.network(
        widget.urls[_index],
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _index += 1);
          });
          return Icon(
            Icons.build_circle_outlined,
            size: 18,
            color: widget.color,
          );
        },
      ),
    );
  }
}

class _ProblemGridSkeleton extends StatelessWidget {
  const _ProblemGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width < 350 ? 1 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: MediaQuery.sizeOf(context).width < 350 ? 92 : 108,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: appSurface(radius: 18),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Spacer(),
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 7),
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
