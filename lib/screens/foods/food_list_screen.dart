import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/meal_model.dart';
import '../../providers/food_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/common_widgets.dart';

/// Food List Screen - Danh sách thực phẩm (Blue theme - giữ UI cũ)
class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final langProvider = context.read<LanguageProvider>();
      final foodProvider = context.read<FoodProvider>();
      foodProvider.loadFoods(
        languageId: langProvider.languageId,
        refresh: true,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final foodProvider = context.watch<FoodProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Custom App Bar with gradient - BLUE
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary, // Blue
                    AppColors.primaryLight, // Light Blue
                    AppColors.secondary, // Cyan
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                title: Text(
                  langProvider.getText(
                    en: '🥗 Food Database',
                    vi: '🥗 Dữ liệu thực phẩm',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: 20,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 120,
                        color: Colors.white.withAlpha(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 20,
                      ),
                      if (foodProvider.filter.categories.isNotEmpty)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                onPressed: () => _showFilterBottomSheet(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => foodProvider.updateSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: langProvider.getText(
                      en: 'Search foods...',
                      vi: 'Tìm thực phẩm...',
                    ),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                foodProvider.updateSearchQuery('');
                              },
                            )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Active Filter Chips
          if (foodProvider.filter.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildActiveFilters(context, foodProvider, langProvider),
            ),

          // Results count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                langProvider.getText(
                  en: '${foodProvider.totalFilteredCount} foods found',
                  vi: 'Tìm thấy ${foodProvider.totalFilteredCount} món',
                ),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ),

          // Food List
          _buildFoodList(context, foodProvider, langProvider),

          // Pagination
          if (foodProvider.totalPages > 1)
            SliverToBoxAdapter(
              child: _buildPaginationControls(
                foodProvider,
                langProvider,
                isDark,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(
    BuildContext context,
    FoodProvider provider,
    LanguageProvider lang,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...provider.filter.categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(category),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  provider.setFilter(
                    provider.filter.toggleCategory(category),
                    languageId: lang.languageId,
                  );
                },
                backgroundColor: AppColors.primarySoft,
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
                deleteIconColor: AppColors.primary,
              ),
            ),
          ),
          // Clear all button
          if (provider.filter.categories.length > 1)
            TextButton.icon(
              onPressed: () => provider.clearFilter(),
              icon: const Icon(Icons.clear_all, size: 16),
              label: Text(lang.getText(en: 'Clear all', vi: 'Xóa tất cả')),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodList(
    BuildContext context,
    FoodProvider provider,
    LanguageProvider lang,
  ) {
    if (provider.isLoading && provider.foods.isEmpty) {
      return const SliverFillRemaining(child: LoadingWidget());
    }

    if (provider.errorMessage != null && provider.foods.isEmpty) {
      return SliverFillRemaining(
        child: ErrorDisplayWidget(
          message: provider.errorMessage!,
          onRetry:
              () => provider.loadFoods(
                languageId: lang.languageId,
                refresh: true,
              ),
        ),
      );
    }

    final paginatedFoods = provider.paginatedFoods;

    if (paginatedFoods.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateWidget(
          title: lang.getText(
            en: 'No foods found',
            vi: 'Không tìm thấy thực phẩm',
          ),
          subtitle: lang.getText(
            en: 'Try adjusting your filters',
            vi: 'Thử điều chỉnh bộ lọc',
          ),
          icon: Icons.restaurant,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final food = paginatedFoods[index];
        return _FoodCard(
          food: food,
          lang: lang,
          index: index,
          onTap: () => _showFoodDetail(food, lang),
        );
      }, childCount: paginatedFoods.length),
    );
  }

  Widget _buildPaginationControls(
    FoodProvider provider,
    LanguageProvider lang,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                provider.hasPreviousPage
                    ? () {
                      provider.goToPage(provider.currentPage - 1);
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                    : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.currentPage} / ${provider.totalPages}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed:
                provider.hasNextPage
                    ? () {
                      provider.goToPage(provider.currentPage + 1);
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                    : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();
    final foodProvider = context.read<FoodProvider>();

    // Load categories on-demand
    foodProvider.loadCategories(languageId: langProvider.languageId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ChangeNotifierProvider.value(
            value: foodProvider,
            child: Consumer<FoodProvider>(
              builder:
                  (context, provider, _) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.9,
                    expand: false,
                    builder:
                        (context, scrollController) => _FilterBottomSheet(
                          langProvider: langProvider,
                          foodProvider: provider,
                          scrollController: scrollController,
                        ),
                  ),
            ),
          ),
    );
  }

  void _showFoodDetail(Food food, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FoodDetailSheet(food: food, lang: lang),
    );
  }
}

/// Food Card Widget - BLUE theme
class _FoodCard extends StatelessWidget {
  final Food food;
  final LanguageProvider lang;
  final int index;
  final VoidCallback onTap;

  const _FoodCard({
    required this.food,
    required this.lang,
    required this.index,
    required this.onTap,
  });

  IconData _getFoodIcon() {
    final name = food.name.toLowerCase();
    final category = (food.categoryName ?? '').toLowerCase();

    if (category.contains('rau') ||
        name.contains('rau') ||
        name.contains('salad')) {
      return Icons.eco;
    } else if (category.contains('protein') ||
        category.contains('thịt') ||
        name.contains('thịt')) {
      return Icons.lunch_dining;
    } else if (category.contains('cá') ||
        name.contains('cá') ||
        name.contains('tôm')) {
      return Icons.set_meal;
    } else if (category.contains('trái') || name.contains('trái cây')) {
      return Icons.apple;
    } else if (category.contains('ngũ cốc') ||
        name.contains('cơm') ||
        name.contains('gạo')) {
      return Icons.rice_bowl;
    } else if (category.contains('sữa') || name.contains('sữa')) {
      return Icons.egg;
    } else if (category.contains('đồ uống')) {
      return Icons.local_drink;
    }
    return Icons.restaurant;
  }

  Color _getAccentColor() {
    final colors = [
      AppColors.primary, // Blue
      AppColors.secondary, // Cyan
      AppColors.accent, // Teal
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Row(
              children: [
                // Food Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_getFoodIcon(), color: accentColor, size: 26),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _NutrientPill(
                            value: '${food.calories?.toInt() ?? 0}',
                            unit: 'kcal',
                            color: AppColors.caloriesColor,
                          ),
                          _NutrientPill(
                            value: '${food.protein?.toInt() ?? 0}g',
                            unit: 'P',
                            color: AppColors.proteinColor,
                          ),
                          _NutrientPill(
                            value: '${food.carbs?.toInt() ?? 0}g',
                            unit: 'C',
                            color: AppColors.carbsColor,
                          ),
                          _NutrientPill(
                            value: '${food.fat?.toInt() ?? 0}g',
                            unit: 'F',
                            color: AppColors.fatColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nutrient Pill
class _NutrientPill extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;

  const _NutrientPill({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value $unit',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Filter Bottom Sheet - BLUE theme
class _FilterBottomSheet extends StatefulWidget {
  final LanguageProvider langProvider;
  final FoodProvider foodProvider;
  final ScrollController scrollController;

  const _FilterBottomSheet({
    required this.langProvider,
    required this.foodProvider,
    required this.scrollController,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late FoodFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.foodProvider.filter;
  }

  // Get main categories (without subcategories)
  List<String> get _mainCategories {
    final allCategories = widget.foodProvider.categories;
    final mainCats = <String>{};

    for (final cat in allCategories) {
      final parts = cat.split('/');
      mainCats.add(parts[0]);
    }

    return mainCats.toList()..sort();
  }

  int get _resultCount {
    final foods = widget.foodProvider.foods;
    if (!_tempFilter.hasFilters) return foods.length;

    return foods.where((food) {
      if (_tempFilter.categories.isNotEmpty) {
        final foodCategory = food.categoryName ?? '';
        return _tempFilter.categories.any(
          (category) =>
              foodCategory == category ||
              foodCategory.startsWith('$category/') ||
              category.startsWith('$foodCategory/'),
        );
      }
      return true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.langProvider.getText(
                        en: 'Filter Foods',
                        vi: 'Lọc thực phẩm',
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (_tempFilter.hasFilters)
                      Text(
                        widget.langProvider.getText(
                          en: '$_resultCount results',
                          vi: '$_resultCount kết quả',
                        ),
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Categories
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.langProvider.getText(en: 'Categories', vi: 'Danh mục'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _mainCategories.map((category) {
                        final isSelected = _tempFilter.categories.contains(
                          category,
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _tempFilter = _tempFilter.toggleCategory(
                                category,
                              );
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  isSelected
                                      ? null
                                      : Border.all(color: Colors.grey[300]!),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: AppColors.primary.withAlpha(
                                            40,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                Text(
                                  category,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[800],
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tempFilter = const FoodFilter();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.primary),
                    ),
                    child: Text(
                      widget.langProvider.getText(en: 'Clear', vi: 'Xóa'),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.foodProvider.setFilter(
                        _tempFilter,
                        languageId: widget.langProvider.languageId,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.langProvider.getText(
                        en: 'Show $_resultCount results',
                        vi: 'Xem $_resultCount kết quả',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Food Detail Sheet - BLUE theme
class _FoodDetailSheet extends StatelessWidget {
  final Food food;
  final LanguageProvider lang;

  const _FoodDetailSheet({required this.food, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isVi = lang.currentLanguage == 'vi';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (food.categoryName != null)
                        Text(
                          food.categoryName!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nutrition
            Text(
              isVi ? '📊 Dinh dưỡng mỗi 100g' : '📊 Nutrition per 100g',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _MacroCard(
                    label: isVi ? 'Calo' : 'Calories',
                    value: '${food.calories?.toInt() ?? 0}',
                    unit: 'kcal',
                    color: AppColors.caloriesColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroCard(
                    label: 'Protein',
                    value: '${food.protein?.toStringAsFixed(1) ?? 0}',
                    unit: 'g',
                    color: AppColors.proteinColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MacroCard(
                    label: 'Carbs',
                    value: '${food.carbs?.toStringAsFixed(1) ?? 0}',
                    unit: 'g',
                    color: AppColors.carbsColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MacroCard(
                    label: isVi ? 'Chất béo' : 'Fat',
                    value: '${food.fat?.toStringAsFixed(1) ?? 0}',
                    unit: 'g',
                    color: AppColors.fatColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Other nutrients
            if (food.fiber != null || food.cholesterol != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVi ? '💊 Thông tin khác' : '💊 Other Info',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (food.fiber != null)
                        _InfoChip(
                          label: isVi ? 'Chất xơ' : 'Fiber',
                          value: '${food.fiber!.toStringAsFixed(1)}g',
                        ),
                      if (food.cholesterol != null)
                        _InfoChip(
                          label: 'Cholesterol',
                          value: '${food.cholesterol!.toStringAsFixed(0)}mg',
                        ),
                      if (food.sodium != null)
                        _InfoChip(
                          label: 'Sodium',
                          value: '${food.sodium!.toStringAsFixed(0)}mg',
                        ),
                      if (food.calcium != null)
                        _InfoChip(
                          label: isVi ? 'Canxi' : 'Calcium',
                          value: '${food.calcium!.toStringAsFixed(0)}mg',
                        ),
                      if (food.potassium != null)
                        _InfoChip(
                          label: isVi ? 'Kali' : 'Potassium',
                          value: '${food.potassium!.toStringAsFixed(0)}mg',
                        ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(color: color.withAlpha(150), fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: Colors.grey[700], fontSize: 13),
      ),
    );
  }
}
