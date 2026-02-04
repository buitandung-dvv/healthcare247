import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/translation_helper.dart';
import '../../data/models/recipe_model.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/cards/recipe_card.dart';
import 'recipe_detail_screen.dart';

/// Recipe List Screen - Danh sách công thức nấu ăn
class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final provider = context.read<RecipeProvider>();
    final lang = context.read<LanguageProvider>();
    provider.loadInitialData(languageId: lang.languageId);
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
      final provider = context.read<RecipeProvider>();
      final lang = context.read<LanguageProvider>();
      provider.loadRecipes(languageId: lang.languageId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: lang.getText(en: 'Recipe Library', vi: 'Thư viện công thức'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: AppSizes.paddingHorizontalMd,
            child: CustomSearchBar(
              hint: lang.getText(
                en: 'Search recipes...',
                vi: 'Tìm công thức...',
              ),
              controller: _searchController,
              onChanged: (value) {
                recipeProvider.updateSearchQuery(value);
              },
              showFilter: false,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Active Filter Chips
          if (_hasActiveFilters(recipeProvider))
            _buildActiveFilters(context, recipeProvider, lang),

          // Recipe List
          Expanded(child: _buildRecipeList(recipeProvider, lang)),
        ],
      ),
    );
  }

  bool _hasActiveFilters(RecipeProvider provider) {
    return provider.filter.categories.isNotEmpty ||
        provider.filter.areas.isNotEmpty;
  }

  Widget _buildActiveFilters(
    BuildContext context,
    RecipeProvider provider,
    LanguageProvider lang,
  ) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSizes.paddingHorizontalMd,
        children: [
          // Category chips
          ...provider.filter.categories.map(
            (category) => _FilterChip(
              label: category,
              onDeleted: () {
                provider.setFilter(
                  provider.filter.toggleCategory(category),
                  languageId: lang.languageId,
                );
              },
            ),
          ),
          // Area chips
          ...provider.filter.areas.map(
            (area) => _FilterChip(
              label: area,
              onDeleted: () {
                provider.setFilter(
                  provider.filter.toggleArea(area),
                  languageId: lang.languageId,
                );
              },
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearFilter();
              // Reload all recipes
              provider.loadRecipes(languageId: lang.languageId, refresh: true);
            },
            child: Text(lang.getText(en: 'Clear all', vi: 'Xóa tất cả')),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList(RecipeProvider provider, LanguageProvider lang) {
    if (provider.isLoading && provider.recipes.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.errorMessage != null && provider.recipes.isEmpty) {
      return ErrorDisplayWidget(
        message: provider.errorMessage!,
        onRetry: _loadInitialData,
      );
    }

    final allRecipes = provider.filteredRecipes;

    if (allRecipes.isEmpty) {
      return EmptyStateWidget(
        title: lang.getText(
          en: 'No recipes found',
          vi: 'Không tìm thấy công thức',
        ),
        subtitle: lang.getText(
          en: 'Try adjusting your search or filters',
          vi: 'Thử điều chỉnh tìm kiếm hoặc bộ lọc',
        ),
        icon: Icons.restaurant_menu,
      );
    }

    // Lấy recipes cho trang hiện tại
    final paginatedRecipes = provider.paginatedRecipes;

    // Total items: paginated recipes + pagination widget (if needed)
    final hasPagination = provider.totalPages > 1;
    final itemCount = paginatedRecipes.length + (hasPagination ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async => _loadInitialData(),
      child: ListView.builder(
        controller: _scrollController,
        padding: AppSizes.paddingMd,
        itemCount: itemCount,
        cacheExtent: 500,
        addAutomaticKeepAlives: true,
        itemBuilder: (context, index) {
          // Last item is pagination controls
          if (hasPagination && index == paginatedRecipes.length) {
            return _buildPaginationControls(provider, lang);
          }

          final recipe = paginatedRecipes[index];
          return RepaintBoundary(
            child: RecipeCard(
              key: ValueKey(recipe.recipeId),
              recipe: recipe,
              onTap: () => _navigateToDetail(context, recipe),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(
    RecipeProvider provider,
    LanguageProvider lang,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.md, bottom: AppSizes.lg),
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.sm,
        horizontal: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
  List<Widget> _buildPageNumbers(RecipeProvider provider) {
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

  Widget _buildPageButton(int page, int currentPage, RecipeProvider provider) {
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
            color: isCurrentPage ? AppColors.secondary : null,
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

  void _goToPageAndScrollTop(RecipeProvider provider, int page) {
    provider.goToPage(page);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _navigateToDetail(BuildContext context, Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final provider = context.read<RecipeProvider>();

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
            value: provider,
            child: Consumer<RecipeProvider>(
              builder:
                  (context, recipeProvider, _) => DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    expand: false,
                    builder:
                        (context, scrollController) => _RecipeFilterSheet(
                          lang: lang,
                          provider: recipeProvider,
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
        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: AppColors.secondary),
      ),
    );
  }
}

/// Recipe Filter Sheet với multi-select và cascading filter
class _RecipeFilterSheet extends StatefulWidget {
  final LanguageProvider lang;
  final RecipeProvider provider;
  final ScrollController scrollController;

  const _RecipeFilterSheet({
    required this.lang,
    required this.provider,
    required this.scrollController,
  });

  @override
  State<_RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class _RecipeFilterSheetState extends State<_RecipeFilterSheet> {
  late RecipeFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.provider.filter;
  }

  /// Lấy danh sách recipes đã được filter theo _tempFilter
  List<Recipe> get _filteredRecipes {
    final recipes = widget.provider.recipes;
    if (!_tempFilter.hasFilters) return recipes;

    return recipes.where((recipe) {
      // Category filter
      if (_tempFilter.categories.isNotEmpty &&
          !_tempFilter.categories.contains(recipe.category)) {
        return false;
      }
      // Area filter
      if (_tempFilter.areas.isNotEmpty &&
          !_tempFilter.areas.contains(recipe.area)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Lấy các options có sẵn - luôn cho phép chọn TẤT CẢ options
  Set<String> get _availableCategories {
    // Luôn trả về tất cả categories để user có thể chọn
    final allCategories =
        widget.provider.categories.isNotEmpty
            ? widget.provider.categories.toSet()
            : _extractCategoriesFromRecipes().toSet();
    return allCategories;
  }

  Set<String> get _availableAreas {
    // Luôn trả về tất cả areas để user có thể chọn
    final allAreas =
        widget.provider.areas.isNotEmpty
            ? widget.provider.areas.toSet()
            : _extractAreasFromRecipes().toSet();
    return allAreas;
  }

  /// Lấy tất cả categories cho UI (không bị filter)
  List<String> get _allCategories {
    if (widget.provider.categories.isNotEmpty) {
      return widget.provider.categories;
    }
    return _extractCategoriesFromRecipes();
  }

  /// Lấy tất cả areas cho UI (không bị filter)
  List<String> get _allAreas {
    if (widget.provider.areas.isNotEmpty) {
      return widget.provider.areas;
    }
    return _extractAreasFromRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final resultCount = _filteredRecipes.length;

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
                    widget.lang.getText(en: 'Filters', vi: 'Bộ lọc'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (_tempFilter.hasFilters)
                    Text(
                      widget.lang.getText(
                        en: '$resultCount recipes found',
                        vi: 'Tìm thấy $resultCount công thức',
                      ),
                      style: TextStyle(
                        color:
                            resultCount > 0
                                ? AppColors.success
                                : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
                // Category - Multi-select
                _buildMultiFilterSection(
                  title: widget.lang.getText(en: 'Category', vi: 'Danh mục'),
                  allOptions: _allCategories,
                  availableOptions: _availableCategories,
                  selectedValues: _tempFilter.categories,
                  selectedColor: AppColors.secondary,
                  filterType: 'category',
                  onToggle: (value) {
                    setState(() {
                      _tempFilter = _tempFilter.toggleCategory(value);
                    });
                  },
                ),

                // Area - Multi-select
                _buildMultiFilterSection(
                  title: widget.lang.getText(en: 'Area', vi: 'Quốc gia'),
                  allOptions: _allAreas,
                  availableOptions: _availableAreas,
                  selectedValues: _tempFilter.areas,
                  selectedColor: AppColors.primary,
                  filterType: 'area',
                  onToggle: (value) {
                    setState(() {
                      _tempFilter = _tempFilter.toggleArea(value);
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
                  text: widget.lang.getText(en: 'Clear', vi: 'Xóa'),
                  onPressed: () {
                    setState(() {
                      _tempFilter = const RecipeFilter();
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: PrimaryButton(
                  text: widget.lang.getText(en: 'Apply', vi: 'Áp dụng'),
                  onPressed: () {
                    // Lấy languageId từ context
                    final langProvider = context.read<LanguageProvider>();
                    widget.provider.setFilter(
                      _tempFilter,
                      languageId: langProvider.languageId,
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

  List<String> _extractCategoriesFromRecipes() {
    return widget.provider.recipes
        .map((r) => r.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _extractAreasFromRecipes() {
    return widget.provider.recipes
        .map((r) => r.area)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  Widget _buildMultiFilterSection({
    required String title,
    required List<String> allOptions,
    required Set<String> availableOptions,
    required List<String> selectedValues,
    required Color selectedColor,
    required ValueChanged<String> onToggle,
    String? filterType, // 'category' or 'area'
  }) {
    final availableCount = availableOptions.length;

    // Helper function to translate option based on filter type
    String translateOption(String option) {
      if (filterType == null) return option;
      switch (filterType) {
        case 'category':
          return TranslationHelper.translateRecipeCategory(context, option);
        case 'area':
          return TranslationHelper.translateRecipeArea(context, option);
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
                  color: selectedColor,
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

                return FilterChip(
                  label: Text(translateOption(option)),
                  selected: isSelected,
                  onSelected:
                      isAvailable || isSelected
                          ? (_) => onToggle(option)
                          : null,
                  selectedColor: selectedColor.withValues(alpha: 0.2),
                  checkmarkColor: selectedColor,
                  disabledColor: Colors.grey.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color:
                        !isAvailable && !isSelected
                            ? AppColors.textHint
                            : isSelected
                            ? selectedColor
                            : AppColors.textPrimary,
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
