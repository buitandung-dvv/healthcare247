import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_config.dart';
import '../../data/models/meal_model.dart';
import '../../data/models/recipe_model.dart';
import '../../providers/food_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/buttons/gradient_button.dart';
import '../recipes/recipe_detail_screen.dart';
import '../meals/add_meal_screen.dart';

/// Nutrition & Recipes Screen — "Dinh dưỡng & Công thức" (Stitch redesign)
class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _foodScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = context.read<LanguageProvider>();
      context.read<RecipeProvider>().loadIfNeeded(languageId: lang.languageId);
      final fp = context.read<FoodProvider>();
      fp.loadFoods(languageId: lang.languageId, refresh: true);
      fp.loadCategories(languageId: lang.languageId);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _searchController.clear();
      if (_tabController.index == 0) {
        context.read<RecipeProvider>().updateSearchQuery('');
      } else {
        context.read<FoodProvider>().updateSearchQuery('');
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _foodScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : null,
      appBar: CustomAppBar(
        title: lang.getText(
          en: 'Nutrition & Recipes',
          vi: 'Dinh dưỡng & Công thức',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar — same style as Exercise screen
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomSearchBar(
              hint: _tabController.index == 0
                  ? lang.getText(
                      en: 'Search recipes...',
                      vi: 'Tìm công thức...',
                    )
                  : lang.getText(en: 'Search foods...', vi: 'Tìm thực phẩm...'),
              controller: _searchController,
              onChanged: (v) {
                if (_tabController.index == 0) {
                  context.read<RecipeProvider>().updateSearchQuery(v);
                } else {
                  context.read<FoodProvider>().updateSearchQuery(v);
                }
                setState(() {});
              },
              showFilter: false,
            ),
          ),
          const SizedBox(height: 8),

          // Tab Bar
          _buildTabBar(lang, isDark),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RecipesTab(isDark: isDark, lang: lang),
                _FoodsTab(
                  isDark: isDark,
                  lang: lang,
                  scrollController: _foodScrollController,
                  onShowDetail: (food) => _showFoodDetail(food, lang, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(LanguageProvider lang, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? Colors.grey[400]
            : const Color(0xFF78909C),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            text: lang.getText(en: 'Recipes', vi: 'Công thức'),
          ),
          Tab(
            text: lang.getText(en: 'Foods', vi: 'Thực phẩm'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_tabController.index == 1) {
      final fp = context.read<FoodProvider>();
      fp.loadCategories(languageId: lang.languageId);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChangeNotifierProvider.value(
          value: fp,
          child: Consumer<FoodProvider>(
            builder: (_, provider, _) => DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, sc) => _FoodFilterSheet(
                langProvider: lang,
                foodProvider: provider,
                scrollController: sc,
                isDark: isDark,
              ),
            ),
          ),
        ),
      );
    } else {
      final rp = context.read<RecipeProvider>();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ChangeNotifierProvider.value(
          value: rp,
          child: Consumer<RecipeProvider>(
            builder: (_, provider, _) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, sc) => _RecipeFilterSheet(
                langProvider: lang,
                recipeProvider: provider,
                scrollController: sc,
                isDark: isDark,
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showFoodDetail(Food food, LanguageProvider lang, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodDetailSheet(food: food, lang: lang, isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0: Recipes — 2-column grid (Stitch style)
// ─────────────────────────────────────────────────────────────────────────────

class _RecipesTab extends StatelessWidget {
  final bool isDark;
  final LanguageProvider lang;
  const _RecipesTab({required this.isDark, required this.lang});

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RecipeProvider>();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _RecipeCategoryChips(provider: rp, lang: lang, isDark: isDark),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              lang.getText(
                en: '${rp.filteredRecipes.length} recipes found',
                vi: 'Tìm thấy ${rp.filteredRecipes.length} công thức',
              ),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (rp.isLoading && rp.recipes.isEmpty)
          const SliverFillRemaining(child: LoadingWidget())
        else if (rp.errorMessage != null && rp.recipes.isEmpty)
          SliverFillRemaining(
            child: ErrorDisplayWidget(
              message: rp.errorMessage!,
              onRetry: () => rp.loadInitialData(languageId: lang.languageId),
            ),
          )
        else if (rp.paginatedRecipes.isEmpty)
          SliverFillRemaining(
            child: EmptyStateWidget(
              title: lang.getText(
                en: 'No recipes found',
                vi: 'Không tìm thấy công thức',
              ),
              subtitle: lang.getText(
                en: 'Try adjusting your filters',
                vi: 'Thử điều chỉnh bộ lọc',
              ),
              icon: Icons.restaurant_menu,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final recipe = rp.paginatedRecipes[i];
                return _RecipeGridCard(
                  recipe: recipe,
                  lang: lang,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipe: recipe),
                    ),
                  ),
                );
              }, childCount: rp.paginatedRecipes.length),
            ),
          ),
        if (rp.totalPages > 1)
          SliverToBoxAdapter(
            child: _RecipePaginationWidget(
              provider: rp,
              lang: lang,
              isDark: isDark,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _RecipeCategoryChips extends StatelessWidget {
  final RecipeProvider provider;
  final LanguageProvider lang;
  final bool isDark;
  const _RecipeCategoryChips({
    required this.provider,
    required this.lang,
    required this.isDark,
  });

  static const _cats = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];
  static const _vi = {
    'Breakfast': 'Bữa sáng',
    'Lunch': 'Bữa trưa',
    'Dinner': 'Bữa tối',
    'Snack': 'Snack',
    'Dessert': 'Tráng miệng',
  };

  @override
  Widget build(BuildContext context) {
    final selected = provider.filter.categories;
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _StitchChip(
            label: lang.getText(en: 'All', vi: 'Tất cả'),
            selected: selected.isEmpty,
            isDark: isDark,
            onTap: () => provider.setFilter(
              provider.filter.copyWith(categories: []),
              languageId: lang.languageId,
            ),
          ),
          const SizedBox(width: 8),
          ..._cats.map((c) {
            final label = lang.currentLanguage == 'vi' ? (_vi[c] ?? c) : c;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StitchChip(
                label: label,
                selected: selected.contains(c),
                isDark: isDark,
                onTap: () => provider.setFilter(
                  provider.filter.toggleCategory(c),
                  languageId: lang.languageId,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RecipeGridCard extends StatelessWidget {
  final Recipe recipe;
  final LanguageProvider lang;
  final bool isDark;
  final VoidCallback onTap;
  const _RecipeGridCard({
    required this.recipe,
    required this.lang,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cal = recipe.nutritionInfo?.calories?.toInt();
    final protein = recipe.nutritionInfo?.protein?.toStringAsFixed(0);
    final imgUrl = recipe.thumbnailUrl ?? recipe.imageUrl;
    final hasImg = imgUrl != null && imgUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImg)
                    Image.network(
                      ApiConfig.getImageUrl(imgUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _RecipePlaceholder(isDark: isDark),
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : _RecipePlaceholder(isDark: isDark),
                    )
                  else
                    _RecipePlaceholder(isDark: isDark),
                  // bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0x55000000), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // favourite btn
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 15,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (cal != null) '$cal kcal',
                        if (protein != null) '${protein}g protein',
                      ].join(' · '),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipePlaceholder extends StatelessWidget {
  final bool isDark;
  const _RecipePlaceholder({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.primarySoft,
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          color: AppColors.primary.withValues(alpha: 0.4),
          size: 36,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Foods — vertical list
// ─────────────────────────────────────────────────────────────────────────────

class _FoodsTab extends StatelessWidget {
  final bool isDark;
  final LanguageProvider lang;
  final ScrollController scrollController;
  final void Function(Food) onShowDetail;
  const _FoodsTab({
    required this.isDark,
    required this.lang,
    required this.scrollController,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FoodProvider>();
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: _FoodCategoryChips(
            foodProvider: fp,
            lang: lang,
            isDark: isDark,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              lang.getText(
                en: '${fp.totalFilteredCount} foods found',
                vi: 'Tìm thấy ${fp.totalFilteredCount} thực phẩm',
              ),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (fp.isLoading && fp.foods.isEmpty)
          const SliverFillRemaining(child: LoadingWidget())
        else if (fp.errorMessage != null && fp.foods.isEmpty)
          SliverFillRemaining(
            child: ErrorDisplayWidget(
              message: fp.errorMessage!,
              onRetry: () =>
                  fp.loadFoods(languageId: lang.languageId, refresh: true),
            ),
          )
        else if (fp.paginatedFoods.isEmpty)
          SliverFillRemaining(
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
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((_, i) {
              final food = fp.paginatedFoods[i];
              return _FoodCard(
                food: food,
                lang: lang,
                index: i,
                isDark: isDark,
                onTap: () => onShowDetail(food),
              );
            }, childCount: fp.paginatedFoods.length),
          ),
        SliverToBoxAdapter(
          child: _FoodPaginationWidget(
            provider: fp,
            lang: lang,
            isDark: isDark,
            scrollController: scrollController,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _FoodCategoryChips extends StatelessWidget {
  final FoodProvider foodProvider;
  final LanguageProvider lang;
  final bool isDark;
  const _FoodCategoryChips({
    required this.foodProvider,
    required this.lang,
    required this.isDark,
  });

  List<String> get _mainCats {
    final set = <String>{};
    for (final c in foodProvider.categories) {
      set.add(c.split('/')[0]);
    }
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final selected = foodProvider.filter.categories;
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _StitchChip(
            label: lang.getText(en: 'All', vi: 'Tất cả'),
            selected: selected.isEmpty,
            isDark: isDark,
            onTap: () => foodProvider.clearFilter(),
          ),
          const SizedBox(width: 8),
          ..._mainCats.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StitchChip(
                label: cat,
                selected: selected.contains(cat),
                isDark: isDark,
                onTap: () => foodProvider.setFilter(
                  foodProvider.filter.toggleCategory(cat),
                  languageId: lang.languageId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Stitch Chip
// ─────────────────────────────────────────────────────────────────────────────

class _StitchChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _StitchChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : Colors.grey.shade700),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Card
// ─────────────────────────────────────────────────────────────────────────────

class _FoodCard extends StatelessWidget {
  final Food food;
  final LanguageProvider lang;
  final int index;
  final bool isDark;
  final VoidCallback onTap;
  const _FoodCard({
    required this.food,
    required this.lang,
    required this.index,
    required this.isDark,
    required this.onTap,
  });

  static const _iconColors = [
    Color(0xFFF97316),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFEAB308),
    Color(0xFFEF4444),
  ];
  static const _icons = [
    Icons.egg_alt,
    Icons.eco,
    Icons.rice_bowl,
    Icons.lunch_dining,
    Icons.set_meal,
    Icons.apple,
    Icons.local_drink,
    Icons.bakery_dining,
  ];

  Color get _accent => _iconColors[index % _iconColors.length];
  IconData get _icon => _icons[index % _icons.length];

  @override
  Widget build(BuildContext context) {
    final cal = food.calories?.toInt() ?? 0;
    final protein = food.protein?.toStringAsFixed(1) ?? '0';
    final carbs = food.carbs?.toStringAsFixed(1) ?? '0';
    final fat = food.fat?.toStringAsFixed(1) ?? '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: _accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (food.categoryName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          food.categoryName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        'P: ${protein}g · C: ${carbs}g · F: ${fat}g',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF78909C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$cal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe Pagination Widget — giống Exercise pagination
// ─────────────────────────────────────────────────────────────────────────────

class _RecipePaginationWidget extends StatelessWidget {
  final RecipeProvider provider;
  final LanguageProvider lang;
  final bool isDark;
  const _RecipePaginationWidget({
    required this.provider,
    required this.lang,
    required this.isDark,
  });

  void _goToPage(int page) {
    provider.goToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final total = provider.filteredRecipes.length;
    final start = total == 0
        ? 0
        : (provider.currentPage - 1) * RecipeProvider.itemsPerPage + 1;
    final end = (provider.currentPage * RecipeProvider.itemsPerPage).clamp(
      0,
      total,
    );

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
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
                Icons.chevron_left,
                provider.hasPreviousPage
                    ? () => _goToPage(provider.currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(),
              const SizedBox(width: 8),
              _buildNavButton(
                Icons.chevron_right,
                provider.hasNextPage
                    ? () => _goToPage(provider.currentPage + 1)
                    : null,
                isNext: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lang.getText(
              en: 'SHOWING $start–$end OF $total RECIPES',
              vi: 'HIỂN THỊ $start–$end TRÊN $total CÔNG THỨC',
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

  Widget _buildNavButton(
    IconData icon,
    VoidCallback? onTap, {
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

  List<Widget> _buildPageNumbers() {
    final currentPage = provider.currentPage;
    final totalPages = provider.totalPages;
    final List<Widget> widgets = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(_buildPageButton(i, currentPage));
      }
    } else if (currentPage <= 3) {
      widgets.add(_buildPageButton(1, currentPage));
      widgets.add(_buildPageButton(2, currentPage));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages - 1, currentPage));
      widgets.add(_buildPageButton(totalPages, currentPage));
    } else if (currentPage >= totalPages - 2) {
      widgets.add(_buildPageButton(1, currentPage));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages - 2, currentPage));
      widgets.add(_buildPageButton(totalPages - 1, currentPage));
      widgets.add(_buildPageButton(totalPages, currentPage));
    } else {
      widgets.add(_buildPageButton(currentPage, currentPage));
      widgets.add(_buildPageButton(currentPage + 1, currentPage));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages - 1, currentPage));
      widgets.add(_buildPageButton(totalPages, currentPage));
    }
    return widgets;
  }

  Widget _buildEllipsis() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      '...',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildPageButton(int page, int currentPage) {
    final isCurrentPage = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _goToPage(page),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentPage ? AppColors.primary : null,
            boxShadow: isCurrentPage
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
              color: isCurrentPage
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Pagination Widget — giống Exercise pagination
// ─────────────────────────────────────────────────────────────────────────────

class _FoodPaginationWidget extends StatelessWidget {
  final FoodProvider provider;
  final LanguageProvider lang;
  final bool isDark;
  final ScrollController scrollController;
  const _FoodPaginationWidget({
    required this.provider,
    required this.lang,
    required this.isDark,
    required this.scrollController,
  });

  void _goToPage(int page) {
    provider.goToPage(page);
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (provider.totalPages <= 1 && provider.totalFilteredCount == 0) {
      return const SizedBox.shrink();
    }
    final total = provider.totalFilteredCount;
    final start = total == 0
        ? 0
        : (provider.currentPage - 1) * FoodProvider.itemsPerPage + 1;
    final end = (provider.currentPage * FoodProvider.itemsPerPage).clamp(
      0,
      total,
    );

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
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
                Icons.chevron_left,
                provider.hasPreviousPage
                    ? () => _goToPage(provider.currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(),
              const SizedBox(width: 8),
              _buildNavButton(
                Icons.chevron_right,
                provider.hasNextPage
                    ? () => _goToPage(provider.currentPage + 1)
                    : null,
                isNext: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lang.getText(
              en: 'SHOWING $start–$end OF $total FOODS',
              vi: 'HIỂN THỊ $start–$end TRÊN $total THỰC PHẨM',
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

  Widget _buildNavButton(
    IconData icon,
    VoidCallback? onTap, {
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

  List<Widget> _buildPageNumbers() {
    final currentPage = provider.currentPage;
    final totalPages = provider.totalPages;
    final List<Widget> widgets = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(_buildPageButton(i, currentPage));
      }
    } else if (currentPage <= 3) {
      widgets.add(_buildPageButton(1, currentPage));
      widgets.add(_buildPageButton(2, currentPage));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages - 1, currentPage));
      widgets.add(_buildPageButton(totalPages, currentPage));
    } else if (currentPage >= totalPages - 2) {
      widgets.add(_buildPageButton(1, currentPage));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages - 2, currentPage));
      widgets.add(_buildPageButton(totalPages - 1, currentPage));
      widgets.add(_buildPageButton(totalPages, currentPage));
    } else {
      widgets.add(_buildPageButton(currentPage, currentPage));
      widgets.add(_buildPageButton(currentPage + 1, currentPage));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages - 1, currentPage));
      widgets.add(_buildPageButton(totalPages, currentPage));
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

  Widget _buildPageButton(int page, int currentPage) {
    final isCurrentPage = page == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => _goToPage(page),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrentPage ? AppColors.primary : null,
            boxShadow: isCurrentPage
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
              color: isCurrentPage
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Filter Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FoodFilterSheet extends StatefulWidget {
  final LanguageProvider langProvider;
  final FoodProvider foodProvider;
  final ScrollController scrollController;
  final bool isDark;
  const _FoodFilterSheet({
    required this.langProvider,
    required this.foodProvider,
    required this.scrollController,
    required this.isDark,
  });
  @override
  State<_FoodFilterSheet> createState() => _FoodFilterSheetState();
}

class _FoodFilterSheetState extends State<_FoodFilterSheet> {
  late FoodFilter _tmp;
  @override
  void initState() {
    super.initState();
    _tmp = widget.foodProvider.filter;
  }

  List<String> get _cats {
    final set = <String>{};
    for (final c in widget.foodProvider.categories) {
      set.add(c.split('/')[0]);
    }
    return set.toList()..sort();
  }

  int get _count {
    final foods = widget.foodProvider.foods;
    if (!_tmp.hasFilters) return foods.length;
    return foods.where((f) {
      if (_tmp.categories.isEmpty) return true;
      final fc = f.categoryName ?? '';
      return _tmp.categories.any(
        (cat) => fc == cat || fc.startsWith('$cat/') || cat.startsWith('$fc/'),
      );
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return _FilterSheetScaffold(
      isDark: isDark,
      title: widget.langProvider.getText(
        en: 'Filter Foods',
        vi: 'Lọc thực phẩm',
      ),
      subtitle: _tmp.hasFilters
          ? widget.langProvider.getText(
              en: '$_count results',
              vi: '$_count kết quả',
            )
          : null,
      scrollController: widget.scrollController,
      clearLabel: widget.langProvider.getText(en: 'Clear', vi: 'Xóa'),
      applyLabel: widget.langProvider.getText(
        en: 'Show $_count results',
        vi: 'Xem $_count kết quả',
      ),
      onClear: () => setState(() => _tmp = const FoodFilter()),
      onApply: () {
        widget.foodProvider.setFilter(
          _tmp,
          languageId: widget.langProvider.languageId,
        );
        Navigator.pop(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            label: widget.langProvider.getText(
              en: 'CATEGORIES',
              vi: 'DANH MỤC',
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _cats.map((cat) {
              final sel = _tmp.categories.contains(cat);
              return GestureDetector(
                onTap: () => setState(() => _tmp = _tmp.toggleCategory(cat)),
                child: _FilterChip(label: cat, selected: sel, isDark: isDark),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recipe Filter Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RecipeFilterSheet extends StatefulWidget {
  final LanguageProvider langProvider;
  final RecipeProvider recipeProvider;
  final ScrollController scrollController;
  final bool isDark;
  const _RecipeFilterSheet({
    required this.langProvider,
    required this.recipeProvider,
    required this.scrollController,
    required this.isDark,
  });
  @override
  State<_RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class _RecipeFilterSheetState extends State<_RecipeFilterSheet> {
  late RecipeFilter _tmp;
  static const _cats = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];
  static const _vi = {
    'Breakfast': 'Bữa sáng',
    'Lunch': 'Bữa trưa',
    'Dinner': 'Bữa tối',
    'Snack': 'Snack',
    'Dessert': 'Tráng miệng',
  };

  @override
  void initState() {
    super.initState();
    _tmp = widget.recipeProvider.filter;
  }

  int get _count {
    final rs = widget.recipeProvider.recipes;
    if (!_tmp.hasFilters) return rs.length;
    return rs.where((r) {
      if (_tmp.categories.isEmpty) return true;
      return _tmp.categories.any((c) => (r.category ?? '').contains(c));
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isVi = widget.langProvider.currentLanguage == 'vi';
    return _FilterSheetScaffold(
      isDark: isDark,
      title: widget.langProvider.getText(
        en: 'Filter Recipes',
        vi: 'Lọc công thức',
      ),
      scrollController: widget.scrollController,
      clearLabel: widget.langProvider.getText(en: 'Clear', vi: 'Xóa'),
      applyLabel: widget.langProvider.getText(
        en: 'Show $_count results',
        vi: 'Xem $_count kết quả',
      ),
      onClear: () => setState(() => _tmp = const RecipeFilter()),
      onApply: () {
        widget.recipeProvider.setFilter(
          _tmp,
          languageId: widget.langProvider.languageId,
        );
        Navigator.pop(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            label: widget.langProvider.getText(
              en: 'MEAL TYPE',
              vi: 'LOẠI BỮA ĂN',
            ),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _cats.map((cat) {
              final sel = _tmp.categories.contains(cat);
              final label = isVi ? (_vi[cat] ?? cat) : cat;
              return GestureDetector(
                onTap: () => setState(() => _tmp = _tmp.toggleCategory(cat)),
                child: _FilterChip(label: label, selected: sel, isDark: isDark),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Sheet Scaffold (shared)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheetScaffold extends StatelessWidget {
  final bool isDark;
  final String title;
  final String? subtitle;
  final ScrollController scrollController;
  final String clearLabel;
  final String applyLabel;
  final VoidCallback onClear;
  final VoidCallback onApply;
  final Widget child;
  const _FilterSheetScaffold({
    required this.isDark,
    required this.title,
    this.subtitle,
    required this.scrollController,
    required this.clearLabel,
    required this.applyLabel,
    required this.onClear,
    required this.onApply,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey[100],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey[200],
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [child],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClear,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: Text(
                      clearLabel,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GradientButton(text: applyLabel, onPressed: onApply),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFEEF2FF)),
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.check, size: 14, color: Colors.white),
            ),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.grey[300] : const Color(0xFF455A64)),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food Detail Bottom Sheet — Stitch style
// ─────────────────────────────────────────────────────────────────────────────

class _FoodDetailSheet extends StatelessWidget {
  final Food food;
  final LanguageProvider lang;
  final bool isDark;
  const _FoodDetailSheet({
    required this.food,
    required this.lang,
    required this.isDark,
  });

  void _showMealTypePicker(
    BuildContext context,
    Food food,
    LanguageProvider lang,
  ) {
    final isVi = lang.currentLanguage == 'vi';
    final mealTypes = [
      {
        'type': 'breakfast',
        'label': isVi ? 'Bữa sáng' : 'Breakfast',
        'icon': Icons.light_mode,
        'color': Colors.orange,
      },
      {
        'type': 'lunch',
        'label': isVi ? 'Bữa trưa' : 'Lunch',
        'icon': Icons.wb_sunny,
        'color': Colors.green,
      },
      {
        'type': 'dinner',
        'label': isVi ? 'Bữa tối' : 'Dinner',
        'icon': Icons.dark_mode,
        'color': Colors.blue,
      },
      {
        'type': 'snack',
        'label': 'Snack',
        'icon': Icons.icecream,
        'color': Colors.pink,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              isVi ? 'Chọn bữa ăn' : 'Select meal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            ...mealTypes.map((m) {
              final color = m['color'] as Color;
              final icon = m['icon'] as IconData;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                title: Text(
                  m['label'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  Navigator.pop(context); // close meal picker
                  Navigator.pop(context); // close food detail sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddMealScreen(
                        mealType: m['type'] as String,
                        date: DateTime.now(),
                        initialFood: food,
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = lang.currentLanguage == 'vi';
    final cal = food.calories?.toDouble() ?? 0;
    final protein = food.protein?.toDouble() ?? 0;
    final carbs = food.carbs?.toDouble() ?? 0;
    final fat = food.fat?.toDouble() ?? 0;

    const maxCal = 400.0;
    const maxPro = 50.0;
    const maxCarb = 80.0;
    const maxFat = 40.0;

    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final surfaceColor = isDark
        ? const Color(0xFF1E1E2E)
        : const Color(0xFFF5F7FA);
    final tp = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final ts = isDark ? Colors.grey[400]! : const Color(0xFF78909C);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tp,
                          ),
                        ),
                        if (food.categoryName != null)
                          Text(
                            food.categoryName!,
                            style: TextStyle(fontSize: 12, color: ts),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '100g',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Rings card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  _CalRing(cal: cal, maxCal: maxCal, isDark: isDark),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MiniRing(
                        label: 'Protein',
                        value: protein,
                        max: maxPro,
                        unit: 'g',
                        color: AppColors.proteinColor,
                        isDark: isDark,
                      ),
                      _MiniRing(
                        label: 'Carbs',
                        value: carbs,
                        max: maxCarb,
                        unit: 'g',
                        color: AppColors.carbsColor,
                        isDark: isDark,
                      ),
                      _MiniRing(
                        label: isVi ? 'Chất béo' : 'Fat',
                        value: fat,
                        max: maxFat,
                        unit: 'g',
                        color: AppColors.fatColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Nutrition table
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey[200]!,
                ),
              ),
              child: Column(
                children: [
                  _NRow(
                    label: isVi ? 'Chất xơ' : 'Fiber',
                    value: food.fiber != null
                        ? '${food.fiber!.toStringAsFixed(1)}g'
                        : '—',
                    isDark: isDark,
                    isFirst: true,
                  ),
                  _NRow(
                    label: isVi ? 'Đường' : 'Sugar',
                    value: food.sugars != null
                        ? '${food.sugars!.toStringAsFixed(1)}g'
                        : '—',
                    isDark: isDark,
                  ),
                  _NRow(
                    label: 'Cholesterol',
                    value: food.cholesterol != null
                        ? '${food.cholesterol!.toStringAsFixed(0)}mg'
                        : '—',
                    isDark: isDark,
                  ),
                  _NRow(
                    label: isVi ? 'Natri' : 'Sodium',
                    value: food.sodium != null
                        ? '${food.sodium!.toStringAsFixed(0)}mg'
                        : '—',
                    isDark: isDark,
                  ),
                  _NRow(
                    label: isVi ? 'Canxi' : 'Calcium',
                    value: food.calcium != null
                        ? '${food.calcium!.toStringAsFixed(0)}mg'
                        : '—',
                    isDark: isDark,
                  ),
                  _NRow(
                    label: isVi ? 'Sắt' : 'Iron',
                    value: food.iron != null
                        ? '${food.iron!.toStringAsFixed(1)}mg'
                        : '—',
                    isDark: isDark,
                  ),
                  _NRow(
                    label: isVi ? 'Kali' : 'Potassium',
                    value: food.potassium != null
                        ? '${food.potassium!.toStringAsFixed(0)}mg'
                        : '—',
                    isDark: isDark,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: () =>
                            _showMealTypePicker(context, food, lang),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          isVi ? 'Thêm vào bữa ăn' : 'Add to meal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.favorite_border,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      label: Text(
                        isVi ? 'Thêm yêu thích' : 'Add to favourites',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring Painter helpers
// ─────────────────────────────────────────────────────────────────────────────

class _CalRing extends StatelessWidget {
  final double cal;
  final double maxCal;
  final bool isDark;
  const _CalRing({
    required this.cal,
    required this.maxCal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (cal / maxCal).clamp(0.0, 1.0);
    const size = 120.0, sw = 10.0, r = (size - sw) / 2;
    final circ = 2 * math.pi * r;
    final off = circ * (1 - ratio);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -math.pi / 2,
            child: CustomPaint(
              size: const Size(size, size),
              painter: _RingPainter(
                track: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
                progress: AppColors.primary,
                sw: sw,
                off: off,
                circ: circ,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${cal.toInt()}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'kcal',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[400],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String unit;
  final Color color;
  final bool isDark;
  const _MiniRing({
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    const size = 56.0, sw = 5.0, r = (size - sw) / 2;
    final circ = 2 * math.pi * r;
    final off = circ * (1 - ratio);
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -math.pi / 2,
                child: CustomPaint(
                  size: const Size(size, size),
                  painter: _RingPainter(
                    track: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                    progress: color,
                    sw: sw,
                    off: off,
                    circ: circ,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}$unit',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color track;
  final Color progress;
  final double sw;
  final double off;
  final double circ;
  _RingPainter({
    required this.track,
    required this.progress,
    required this.sw,
    required this.off,
    required this.circ,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - sw) / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      0,
      2 * math.pi * (1 - off / circ),
      false,
      Paint()
        ..color = progress
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.off != off || old.progress != progress;
}

class _NRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isFirst;
  final bool isLast;
  const _NRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final tp = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final ts = isDark ? Colors.grey[400]! : const Color(0xFF78909C);
    final div = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey[200]!;
    return Column(
      children: [
        if (!isFirst) Divider(height: 1, color: div),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: ts,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: tp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
