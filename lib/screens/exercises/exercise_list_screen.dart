import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/translation_helper.dart';
import '../../data/models/exercise_model.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/exercise_card.dart';
import 'exercise_detail_screen.dart';

/// Exercise List Screen - Danh sách bài tập
class ExerciseListScreen extends StatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final langProvider = context.read<LanguageProvider>();
      final exerciseProvider = context.read<ExerciseProvider>();
      exerciseProvider.loadExercises(
        languageId: langProvider.languageId,
        refresh: true,
      );
      // NOTE: loadFilterOptions is now deferred to when filter panel is opened
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final langProvider = context.read<LanguageProvider>();
      context.read<ExerciseProvider>().loadExercises(
        languageId: langProvider.languageId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : null,
      appBar: CustomAppBar(
        title: langProvider.getText(
          en: 'Exercise Library',
          vi: 'Thư viện bài tập',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: AppSizes.paddingHorizontalMd,
            child: CustomSearchBar(
              hint: langProvider.getText(
                en: 'Search exercises...',
                vi: 'Tìm kiếm bài tập...',
              ),
              controller: _searchController,
              onChanged: (value) {
                exerciseProvider.updateSearchQuery(value);
              },
              showFilter: false,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Filter Chips
          if (_hasActiveFilters(exerciseProvider))
            _buildActiveFilters(context, exerciseProvider),

          // Exercise List
          Expanded(
            child: _buildExerciseList(context, exerciseProvider, langProvider),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters(ExerciseProvider provider) {
    return provider.filter.levels.isNotEmpty ||
        provider.filter.categories.isNotEmpty ||
        provider.filter.equipments.isNotEmpty ||
        provider.filter.muscles.isNotEmpty;
  }

  Widget _buildActiveFilters(BuildContext context, ExerciseProvider provider) {
    final langProvider = context.read<LanguageProvider>();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSizes.paddingHorizontalMd,
        children: [
          // Level chips
          ...provider.filter.levels.map(
            (level) => _FilterChip(
              label: level,
              onDeleted: () {
                provider.setFilter(
                  provider.filter.toggleLevel(level),
                  languageId: langProvider.languageId,
                );
              },
            ),
          ),
          // Category chips
          ...provider.filter.categories.map(
            (category) => _FilterChip(
              label: category,
              onDeleted: () {
                provider.setFilter(
                  provider.filter.toggleCategory(category),
                  languageId: langProvider.languageId,
                );
              },
            ),
          ),
          // Equipment chips
          ...provider.filter.equipments.map(
            (equipment) => _FilterChip(
              label: equipment,
              onDeleted: () {
                provider.setFilter(
                  provider.filter.toggleEquipment(equipment),
                  languageId: langProvider.languageId,
                );
              },
            ),
          ),
          // Muscle chips
          ...provider.filter.muscles.map(
            (muscle) => _FilterChip(
              label: muscle,
              onDeleted: () {
                provider.setFilter(
                  provider.filter.toggleMuscle(muscle),
                  languageId: langProvider.languageId,
                );
              },
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearFilter();
              provider.loadExercises(
                languageId: langProvider.languageId,
                refresh: true,
              );
            },
            child: Text(
              langProvider.getText(en: 'Clear all', vi: 'Xóa tất cả'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    ExerciseProvider provider,
    LanguageProvider langProvider,
  ) {
    if (provider.isLoading && provider.exercises.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.errorMessage != null && provider.exercises.isEmpty) {
      return ErrorDisplayWidget(
        message: provider.errorMessage!,
        onRetry:
            () => provider.loadExercises(
              languageId: langProvider.languageId,
              refresh: true,
            ),
      );
    }

    final allExercises = provider.filteredExercises;

    if (allExercises.isEmpty) {
      return EmptyStateWidget(
        title: langProvider.getText(
          en: 'No exercises found',
          vi: 'Không tìm thấy bài tập',
        ),
        subtitle: langProvider.getText(
          en: 'Try adjusting your filters',
          vi: 'Thử điều chỉnh bộ lọc',
        ),
        icon: Icons.fitness_center,
      );
    }

    // Lấy exercises cho trang hiện tại
    final paginatedExercises = provider.paginatedExercises;

    // Total items: paginated exercises + pagination widget (if needed)
    final hasPagination = provider.totalPages > 1;
    final itemCount = paginatedExercises.length + (hasPagination ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadExercises(
          languageId: langProvider.languageId,
          refresh: true,
        );
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: AppSizes.paddingMd,
        itemCount: itemCount,
        cacheExtent: 500,
        addAutomaticKeepAlives: true,
        itemBuilder: (context, index) {
          // Last item is pagination controls
          if (hasPagination && index == paginatedExercises.length) {
            return _buildPaginationControls(provider, langProvider);
          }

          final exercise = paginatedExercises[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: RepaintBoundary(
              child: ExerciseCard(
                key: ValueKey(exercise.exerciseId),
                exercise: exercise,
                onTap: () => _navigateToDetail(context, exercise),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(
    ExerciseProvider provider,
    LanguageProvider lang,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.md, bottom: AppSizes.lg),
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.sm,
        horizontal: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous button
          IconButton(
            onPressed:
                provider.hasPreviousPage
                    ? () => _goToPageAndScrollTop(
                      provider,
                      provider.currentPage - 1,
                    )
                    : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 24,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),

          // Page numbers (limited to 5)
          ..._buildPageNumbers(provider),

          // Next button
          IconButton(
            onPressed:
                provider.hasNextPage
                    ? () => _goToPageAndScrollTop(
                      provider,
                      provider.currentPage + 1,
                    )
                    : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 24,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  /// Tạo danh sách các widget số trang với format: 1 2 ... 77 78
  List<Widget> _buildPageNumbers(ExerciseProvider provider) {
    final currentPage = provider.currentPage;
    final totalPages = provider.totalPages;
    final List<Widget> widgets = [];

    if (totalPages <= 5) {
      // Show all pages if total is 5 or less
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(_buildPageButton(i, currentPage, provider));
      }
    } else {
      // Determine which pattern to use based on current page position
      if (currentPage <= 3) {
        // Near start: 1 2 ... (totalPages-1) totalPages
        widgets.add(_buildPageButton(1, currentPage, provider));
        widgets.add(_buildPageButton(2, currentPage, provider));
        widgets.add(_buildEllipsis());
        widgets.add(_buildPageButton(totalPages - 1, currentPage, provider));
        widgets.add(_buildPageButton(totalPages, currentPage, provider));
      } else if (currentPage >= totalPages - 2) {
        // Near end: 1 ... (totalPages-2) (totalPages-1) totalPages
        widgets.add(_buildPageButton(1, currentPage, provider));
        widgets.add(_buildEllipsis());
        widgets.add(_buildPageButton(totalPages - 2, currentPage, provider));
        widgets.add(_buildPageButton(totalPages - 1, currentPage, provider));
        widgets.add(_buildPageButton(totalPages, currentPage, provider));
      } else {
        // Middle: currentPage (currentPage+1) ... (totalPages-1) totalPages
        widgets.add(_buildPageButton(currentPage, currentPage, provider));
        widgets.add(_buildPageButton(currentPage + 1, currentPage, provider));
        widgets.add(_buildEllipsis());
        widgets.add(_buildPageButton(totalPages - 1, currentPage, provider));
        widgets.add(_buildPageButton(totalPages, currentPage, provider));
      }
    }

    return widgets;
  }

  Widget _buildEllipsis() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPageButton(
    int page,
    int currentPage,
    ExerciseProvider provider,
  ) {
    final isCurrentPage = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: InkWell(
        onTap: () => _goToPageAndScrollTop(provider, page),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrentPage ? AppColors.primary : null,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              color: isCurrentPage ? Colors.white : AppColors.textPrimary,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _goToPageAndScrollTop(ExerciseProvider provider, int page) {
    provider.goToPage(page);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _navigateToDetail(BuildContext context, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(exercise: exercise),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    // Load filter options on-demand
    exerciseProvider.loadFilterOptions(languageId: langProvider.languageId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder:
          (context) => ChangeNotifierProvider.value(
            value: exerciseProvider,
            child: Consumer<ExerciseProvider>(
              builder:
                  (context, provider, _) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.9,
                    expand: false,
                    builder:
                        (context, scrollController) => _FilterBottomSheet(
                          langProvider: langProvider,
                          exerciseProvider: provider,
                          scrollController: scrollController,
                        ),
                  ),
            ),
          ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _FilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDeleted,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: AppColors.primary),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final LanguageProvider langProvider;
  final ExerciseProvider exerciseProvider;
  final ScrollController scrollController;

  const _FilterBottomSheet({
    required this.langProvider,
    required this.exerciseProvider,
    required this.scrollController,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late ExerciseFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.exerciseProvider.filter;
  }

  /// Lấy danh sách exercises đã được filter theo _tempFilter
  List<Exercise> get _filteredExercises {
    final exercises = widget.exerciseProvider.exercises;
    if (!_tempFilter.hasFilters) return exercises;

    return exercises.where((exercise) {
      // Level filter
      if (_tempFilter.levels.isNotEmpty &&
          !_tempFilter.levels.contains(exercise.level)) {
        return false;
      }
      // Category filter
      if (_tempFilter.categories.isNotEmpty &&
          !_tempFilter.categories.contains(exercise.category)) {
        return false;
      }
      // Equipment filter
      if (_tempFilter.equipments.isNotEmpty &&
          !_tempFilter.equipments.contains(exercise.equipment)) {
        return false;
      }
      // Muscle filter
      if (_tempFilter.muscles.isNotEmpty) {
        final hasMatchingMuscle = _tempFilter.muscles.any(
          (muscle) =>
              exercise.primaryMuscles.contains(muscle) ||
              exercise.secondaryMuscles.contains(muscle),
        );
        if (!hasMatchingMuscle) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Lấy các options có sẵn dựa trên kết quả filter hiện tại
  Set<String> get _availableLevels {
    // Nếu chưa chọn gì hoặc chỉ chọn level, hiển thị tất cả levels
    if (_tempFilter.categories.isEmpty &&
        _tempFilter.equipments.isEmpty &&
        _tempFilter.muscles.isEmpty) {
      return widget.exerciseProvider.levels.toSet();
    }
    // Lọc ra các levels có trong kết quả
    return _filteredExercises.map((e) => e.level).toSet();
  }

  Set<String> get _availableCategories {
    // Nếu chưa chọn gì hoặc chỉ chọn category, hiển thị tất cả
    if (_tempFilter.levels.isEmpty &&
        _tempFilter.equipments.isEmpty &&
        _tempFilter.muscles.isEmpty) {
      return widget.exerciseProvider.categories.toSet();
    }
    return _filteredExercises.map((e) => e.category).toSet();
  }

  Set<String> get _availableEquipments {
    if (_tempFilter.levels.isEmpty &&
        _tempFilter.categories.isEmpty &&
        _tempFilter.muscles.isEmpty) {
      return widget.exerciseProvider.equipments.toSet();
    }
    return _filteredExercises
        .where((e) => e.equipment != null)
        .map((e) => e.equipment!)
        .toSet();
  }

  Set<String> get _availableMuscles {
    if (_tempFilter.levels.isEmpty &&
        _tempFilter.categories.isEmpty &&
        _tempFilter.equipments.isEmpty) {
      return widget.exerciseProvider.muscles
          .map((m) => m['name']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toSet();
    }
    final muscles = <String>{};
    for (final e in _filteredExercises) {
      muscles.addAll(e.primaryMuscles);
      muscles.addAll(e.secondaryMuscles);
    }
    return muscles;
  }

  @override
  Widget build(BuildContext context) {
    // Lấy số lượng kết quả để hiển thị
    final resultCount = _filteredExercises.length;

    return Container(
      padding: AppSizes.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.langProvider.getText(en: 'Filters', vi: 'Bộ lọc'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (_tempFilter.hasFilters)
                    Text(
                      widget.langProvider.getText(
                        en: '$resultCount exercises found',
                        vi: 'Tìm thấy $resultCount bài tập',
                      ),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Filter content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                // Level - Multi-select
                _buildMultiFilterSection(
                  title: widget.langProvider.getText(en: 'Level', vi: 'Cấp độ'),
                  allOptions: widget.exerciseProvider.levels,
                  availableOptions: _availableLevels,
                  selectedValues: _tempFilter.levels,
                  filterType: 'level',
                  onToggle: (value) {
                    setState(() {
                      _tempFilter = _tempFilter.toggleLevel(value);
                    });
                  },
                ),

                // Category - Multi-select
                _buildMultiFilterSection(
                  title: widget.langProvider.getText(
                    en: 'Category',
                    vi: 'Loại',
                  ),
                  allOptions: widget.exerciseProvider.categories,
                  availableOptions: _availableCategories,
                  selectedValues: _tempFilter.categories,
                  filterType: 'category',
                  onToggle: (value) {
                    setState(() {
                      _tempFilter = _tempFilter.toggleCategory(value);
                    });
                  },
                ),

                // Equipment - Multi-select
                _buildMultiFilterSection(
                  title: widget.langProvider.getText(
                    en: 'Equipment',
                    vi: 'Thiết bị',
                  ),
                  allOptions: widget.exerciseProvider.equipments,
                  availableOptions: _availableEquipments,
                  selectedValues: _tempFilter.equipments,
                  filterType: 'equipment',
                  onToggle: (value) {
                    setState(() {
                      _tempFilter = _tempFilter.toggleEquipment(value);
                    });
                  },
                ),

                // Muscle - Multi-select
                _buildMultiFilterSection(
                  title: widget.langProvider.getText(
                    en: 'Muscle',
                    vi: 'Nhóm cơ',
                  ),
                  allOptions:
                      widget.exerciseProvider.muscles
                          .map((m) => m['name']?.toString() ?? '')
                          .where((m) => m.isNotEmpty)
                          .toList(),
                  availableOptions: _availableMuscles,
                  selectedValues: _tempFilter.muscles,
                  filterType: 'muscle',
                  onToggle: (value) {
                    setState(() {
                      _tempFilter = _tempFilter.toggleMuscle(value);
                    });
                  },
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: widget.langProvider.getText(en: 'Clear', vi: 'Xóa'),
                  onPressed: () {
                    setState(() {
                      _tempFilter = const ExerciseFilter();
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: PrimaryButton(
                  text: widget.langProvider.getText(en: 'Apply', vi: 'Áp dụng'),
                  onPressed: () {
                    widget.exerciseProvider.setFilter(
                      _tempFilter,
                      languageId: widget.langProvider.languageId,
                    );
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiFilterSection({
    required String title,
    required List<String> allOptions,
    required Set<String> availableOptions,
    required List<String> selectedValues,
    required ValueChanged<String> onToggle,
    String? filterType, // 'level', 'category', 'equipment', 'muscle'
  }) {
    // Đếm số options khả dụng
    final availableCount = availableOptions.length;

    // Helper function to translate option based on filter type
    String translateOption(String option) {
      if (filterType == null) return option;
      switch (filterType) {
        case 'level':
          return TranslationHelper.translateLevel(context, option);
        case 'category':
          return TranslationHelper.translateCategory(context, option);
        case 'equipment':
          return TranslationHelper.translateEquipment(context, option);
        case 'muscle':
          return option; // Muscles already translated from database
        default:
          return option;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (selectedValues.isNotEmpty) ...[
              const SizedBox(width: AppSizes.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedValues.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Hiển thị số lượng options khả dụng
            Text(
              '$availableCount/${allOptions.length}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children:
              allOptions.map((option) {
                final isSelected = selectedValues.contains(option);
                final isAvailable = availableOptions.contains(option);
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return FilterChip(
                  label: Text(translateOption(option)),
                  selected: isSelected,
                  onSelected:
                      isAvailable || isSelected
                          ? (_) => onToggle(option)
                          : null,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: isDark ? AppColors.darkCard : null,
                  disabledColor:
                      isDark
                          ? AppColors.darkCard.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.1),
                  side: BorderSide(
                    color:
                        isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkBorder
                                : Colors.grey.shade300),
                  ),
                  labelStyle: TextStyle(
                    color:
                        !isAvailable && !isSelected
                            ? AppColors.textHint
                            : isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textWhite
                                : AppColors.textPrimary),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }
}
