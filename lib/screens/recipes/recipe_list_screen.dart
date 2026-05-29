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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          lang.getText(en: 'Recipe Library', vi: 'Thư viện công thức'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.primary),
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

          // Category quick-filter chips (Stitch design)
          _buildCategoryChips(context, recipeProvider, lang),

          // Active Filter Chips
          if (_hasActiveFilters(recipeProvider))
            _buildActiveFilters(context, recipeProvider, lang),

          // Recipe Grid
          Expanded(child: _buildRecipeList(recipeProvider, lang)),
        ],
      ),
    );
  }

  bool _hasActiveFilters(RecipeProvider provider) {
    return provider.filter.categories.isNotEmpty ||
        provider.filter.areas.isNotEmpty;
  }

  Widget _buildCategoryChips(
    BuildContext context,
    RecipeProvider provider,
    LanguageProvider lang,
  ) {
    final categories = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final labels = {
      'Breakfast': lang.getText(en: 'Breakfast', vi: 'Bữa sáng'),
      'Lunch': lang.getText(en: 'Lunch', vi: 'Bữa trưa'),
      'Dinner': lang.getText(en: 'Dinner', vi: 'Bữa tối'),
      'Snack': lang.getText(en: 'Snack', vi: 'Snack'),
    };
    final selectedCategories = provider.filter.categories;
    final isNoneSelected = selectedCategories.isEmpty;

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSizes.paddingHorizontalMd,
        children: [
          // "Tất cả"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (!isNoneSelected) {
                  provider.setFilter(
                    provider.filter.copyWith(categories: []),
                    languageId: lang.languageId,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isNoneSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isNoneSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  lang.getText(en: 'All', vi: 'Tất cả'),
                  style: TextStyle(
                    color: isNoneSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          ...categories.map((cat) {
            final isSelected = selectedCategories.contains(cat);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  provider.setFilter(
                    provider.filter.toggleCategory(cat),
                    languageId: lang.languageId,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    labels[cat] ?? cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
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

    return RefreshIndicator(
      onRefresh: () async => _loadInitialData(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 2-column grid (Stitch design)
          SliverPadding(
            padding: AppSizes.paddingMd,
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final recipe = paginatedRecipes[index];
                return RepaintBoundary(
                  child: RecipeCard(
                    key: ValueKey(recipe.recipeId),
                    recipe: recipe,
                    onTap: () => _navigateToDetail(context, recipe),
                  ),
                );
              }, childCount: paginatedRecipes.length),
            ),
          ),
          // Pagination controls
          SliverToBoxAdapter(child: _buildPaginationControls(provider, lang)),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(
    RecipeProvider provider,
    LanguageProvider lang,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalItems = provider.filteredRecipes.length;
    final startItem =
        totalItems == 0
            ? 0
            : (provider.currentPage - 1) * RecipeProvider.itemsPerPage + 1;
    final endItem = (provider.currentPage * RecipeProvider.itemsPerPage).clamp(
      0,
      totalItems,
    );

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.md, bottom: AppSizes.lg),
      padding: const EdgeInsets.symmetric(
        vertical: 24,
        horizontal: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavButton(
                icon: Icons.chevron_left,
                onTap: provider.hasPreviousPage
                    ? () => _goToPageAndScrollTop(provider, provider.currentPage - 1)
                    : null,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              // Page numbers
              ..._buildPageNumbers(provider),
              const SizedBox(width: 8),
              _buildNavButton(
                icon: Icons.chevron_right,
                onTap: provider.hasNextPage
                    ? () => _goToPageAndScrollTop(provider, provider.currentPage + 1)
                    : null,
                isDark: isDark,
                isNext: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lang.getText(
              en: 'SHOWING $startItem-$endItem OF $totalItems RECIPES',
              vi:
                  'HI\u1EC2N TH\u1ECA $startItem-$endItem TR\u00caN $totalItems C\u00d4NG TH\u1EE8C',
            ),
            style: TextStyle(
              color: isDark ? Colors.grey[400] : const Color(0xFF78909C),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
    bool isNext = false,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDisabled
              ? (isDark ? Colors.grey[700] : Colors.grey[400])
              : isNext
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : Colors.grey[600]),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _goToPageAndScrollTop(provider, page),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentPage ? AppColors.primary : null,
            boxShadow:
                isCurrentPage
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 14,
              color:
                  isCurrentPage
                      ? Colors.white
                      : isDark
                      ? Colors.white
                      : AppColors.textPrimary,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.w600,
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
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDeleted,
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ],
        ),
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
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _tempFilter = const RecipeFilter();
                    });
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Center(
                      child: Text(
                        widget.lang.getText(en: 'Clear', vi: 'Xóa'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final langProvider = context.read<LanguageProvider>();
                    widget.provider.setFilter(
                      _tempFilter,
                      languageId: langProvider.languageId,
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.lang.getText(en: 'Apply', vi: 'Áp dụng'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return FilterChip(
                  label: Text(translateOption(option)),
                  selected: isSelected,
                  onSelected:
                      isAvailable || isSelected
                          ? (_) => onToggle(option)
                          : null,
                  selectedColor: selectedColor.withValues(alpha: 0.2),
                  checkmarkColor: selectedColor,
                  backgroundColor: isDark ? AppColors.darkCard : null,
                  disabledColor:
                      isDark
                          ? AppColors.darkCard.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.1),
                  side: BorderSide(
                    color:
                        isSelected
                            ? selectedColor
                            : (isDark
                                ? AppColors.darkBorder
                                : Colors.grey.shade300),
                  ),
                  labelStyle: TextStyle(
                    color:
                        !isAvailable && !isSelected
                            ? AppColors.textHint
                            : isSelected
                            ? selectedColor
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
