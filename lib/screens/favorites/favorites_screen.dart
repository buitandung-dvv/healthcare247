import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/language_provider.dart';
import '../../data/models/favorite_model.dart';

/// Favorites Screen — Stitch Design
/// 3 tabs: Bài tập / Công thức / Thực phẩm
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favProvider = context.read<FavoritesProvider>();
      favProvider.loadFavoriteExercises();
      favProvider.loadFavoriteFoods();
      favProvider.loadFavoriteRecipes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final favProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          lang.getText(en: 'Favorites', vi: 'Yêu thích'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: const Color(0xFF94A3B8),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lang.getText(en: 'Exercises', vi: 'Bài tập')),
                      const SizedBox(width: 6),
                      _badge('${favProvider.favoriteExercises.length}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lang.getText(en: 'Recipes', vi: 'Công thức')),
                      const SizedBox(width: 6),
                      _badge('${favProvider.favoriteRecipes.length}'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(lang.getText(en: 'Foods', vi: 'Thực phẩm')),
                      const SizedBox(width: 6),
                      _badge('${favProvider.favoriteFoods.length}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExercisesTab(favProvider, lang),
          _buildRecipesTab(favProvider, lang),
          _buildFoodsTab(favProvider, lang),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExercisesTab(
    FavoritesProvider favProvider,
    LanguageProvider lang,
  ) {
    if (favProvider.isLoadingExercises) {
      return const Center(child: CircularProgressIndicator());
    }
    if (favProvider.favoriteExercises.isEmpty) {
      return _buildEmptyState(
        icon: Icons.fitness_center_rounded,
        title: lang.getText(
          en: 'No favorite exercises',
          vi: 'Chưa có bài tập yêu thích',
        ),
        subtitle: lang.getText(
          en: 'Tap the heart on exercises to save them',
          vi: 'Nhấn biểu tượng tim để lưu bài tập',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => favProvider.loadFavoriteExercises(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favProvider.favoriteExercises.length,
        itemBuilder: (context, index) {
          return _buildExerciseCard(
            favProvider.favoriteExercises[index],
            favProvider,
          );
        },
      ),
    );
  }

  Widget _buildRecipesTab(
    FavoritesProvider favProvider,
    LanguageProvider lang,
  ) {
    if (favProvider.isLoadingRecipes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (favProvider.favoriteRecipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_menu_rounded,
        title: lang.getText(
          en: 'No favorite recipes',
          vi: 'Chưa có công thức yêu thích',
        ),
        subtitle: lang.getText(
          en: 'Tap the heart on recipes to save them',
          vi: 'Nhấn biểu tượng tim để lưu công thức',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => favProvider.loadFavoriteRecipes(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favProvider.favoriteRecipes.length,
        itemBuilder: (context, index) {
          return _buildRecipeCard(
            favProvider.favoriteRecipes[index],
            favProvider,
          );
        },
      ),
    );
  }

  Widget _buildFoodsTab(FavoritesProvider favProvider, LanguageProvider lang) {
    if (favProvider.isLoadingFoods) {
      return const Center(child: CircularProgressIndicator());
    }
    if (favProvider.favoriteFoods.isEmpty) {
      return _buildEmptyState(
        icon: Icons.fastfood_rounded,
        title: lang.getText(
          en: 'No favorite foods',
          vi: 'Chưa có thực phẩm yêu thích',
        ),
        subtitle: lang.getText(
          en: 'Tap the heart on foods to save them',
          vi: 'Nhấn biểu tượng tim để lưu thực phẩm',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => favProvider.loadFavoriteFoods(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favProvider.favoriteFoods.length,
        itemBuilder: (context, index) {
          return _buildFoodCard(favProvider.favoriteFoods[index], favProvider);
        },
      ),
    );
  }

  Widget _buildRecipeCard(FavoriteRecipe favRecipe, FavoritesProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipe = favRecipe.recipe;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: recipe?.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: recipe!.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _placeholderBox(Icons.restaurant),
                      errorWidget: (_, _, _) =>
                          _placeholderBox(Icons.restaurant),
                    )
                  : _placeholderBox(Icons.restaurant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe?.name ?? 'Công thức #${favRecipe.recipeId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe?.overview ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => prov.removeFavoriteRecipe(favRecipe.recipeId),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.favorite, color: Color(0xFFEF4444), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(FavoriteFood favFood, FavoritesProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final food = favFood.food;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fastfood_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food?.name ?? 'Thực phẩm #${favFood.foodId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food?.categoryName ?? ''} · ${food?.calories?.toStringAsFixed(0) ?? '0'} kcal',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => prov.removeFavoriteFood(favFood.foodId),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.favorite, color: Color(0xFFEF4444), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    FavoriteExercise favExercise,
    FavoritesProvider prov,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: favExercise.gifUrl != null
                  ? CachedNetworkImage(
                      imageUrl: favExercise.gifUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          _placeholderBox(Icons.fitness_center),
                      errorWidget: (_, _, _) =>
                          _placeholderBox(Icons.fitness_center),
                    )
                  : _placeholderBox(Icons.fitness_center),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favExercise.name ?? 'Bài tập #${favExercise.exerciseId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${favExercise.bodyPart ?? ''} · ${favExercise.equipment ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => prov.removeFavoriteExercise(favExercise.exerciseId),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.favorite, color: Color(0xFFEF4444), size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBox(IconData icon) {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFF1F5F9),
      child: Icon(icon, color: const Color(0xFF94A3B8), size: 32),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
