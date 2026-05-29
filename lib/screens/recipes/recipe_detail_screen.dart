import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/recipe_model.dart';
import '../../providers/language_provider.dart';
import 'youtube_player_screen.dart';

/// Recipe Detail Screen - Chi tiết công thức nấu ăn
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isFavorite = false;

  void _toggleFavorite(BuildContext context) {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? lang.getText(
                en: 'Added to favorites!',
                vi: 'Đã thêm vào yêu thích!',
              )
              : lang.getText(
                en: 'Removed from favorites',
                vi: 'Đã xóa khỏi yêu thích',
              ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareRecipe(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.getText(
            en: 'Sharing: ${widget.recipe.name}',
            vi: 'Chia sẻ: ${widget.recipe.name}',
          ),
        ),
        action: SnackBarAction(
          label: lang.getText(en: 'Copy Link', vi: 'Sao chép'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lang.getText(en: 'Link copied!', vi: 'Đã sao chép!'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _saveRecipe(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.getText(
            en: 'Recipe saved to your collection!',
            vi: 'Đã lưu công thức vào bộ sưu tập!',
          ),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addToMeal(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText(en: 'Add to Meal', vi: 'Thêm vào bữa ăn'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.free_breakfast,
                    color: Colors.orange,
                  ),
                  title: Text(lang.getText(en: 'Breakfast', vi: 'Bữa sáng')),
                  onTap: () => _confirmAddToMeal(context, 'breakfast'),
                ),
                ListTile(
                  leading: const Icon(Icons.lunch_dining, color: Colors.green),
                  title: Text(lang.getText(en: 'Lunch', vi: 'Bữa trưa')),
                  onTap: () => _confirmAddToMeal(context, 'lunch'),
                ),
                ListTile(
                  leading: const Icon(Icons.dinner_dining, color: Colors.blue),
                  title: Text(lang.getText(en: 'Dinner', vi: 'Bữa tối')),
                  onTap: () => _confirmAddToMeal(context, 'dinner'),
                ),
                ListTile(
                  leading: const Icon(Icons.icecream, color: Colors.pink),
                  title: Text(lang.getText(en: 'Snack', vi: 'Ăn vặt')),
                  onTap: () => _confirmAddToMeal(context, 'snack'),
                ),
              ],
            ),
          ),
    );
  }

  void _confirmAddToMeal(BuildContext context, String mealType) {
    Navigator.pop(context);
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.getText(
            en: 'Added "${widget.recipe.name}" to $mealType!',
            vi: 'Đã thêm "${widget.recipe.name}" vào $mealType!',
          ),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _playVideo() {
    final youtubeUrl = widget.recipe.youtubeUrl;
    if (youtubeUrl == null || youtubeUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getText(
              en: 'No video available for this recipe',
              vi: 'Không có video cho công thức này',
            ),
          ),
        ),
      );
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().getText(
              en: 'Invalid video URL',
              vi: 'Đường dẫn video không hợp lệ',
            ),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => YouTubePlayerScreen(
              videoId: videoId,
              title: widget.recipe.name,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final recipe = widget.recipe;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Video Playback
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: _playVideo,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Recipe Image
                    recipe.imageUrl != null
                        ? Image.network(
                          recipe.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.restaurant,
                                size: 64,
                                color: AppColors.secondary,
                              ),
                            );
                          },
                        )
                        : Container(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.restaurant,
                            size: 64,
                            color: AppColors.secondary,
                          ),
                        ),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),

                    // Play button overlay
                    if (recipe.youtubeUrl != null &&
                        recipe.youtubeUrl!.isNotEmpty)
                      Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 45,
                          ),
                        ),
                      ),

                    // "Watch Video" text
                    if (recipe.youtubeUrl != null &&
                        recipe.youtubeUrl!.isNotEmpty)
                      Positioned(
                        bottom: AppSizes.md,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.md,
                                vertical: AppSizes.xs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.ondemand_video,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: AppSizes.xs),
                                  Text(
                                    lang.getText(
                                      en: 'Watch Video',
                                      vi: 'Xem Video',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _toggleFavorite(context),
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
              ),
              IconButton(
                onPressed: () => _shareRecipe(context),
                icon: const Icon(Icons.share),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSizes.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Info
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: Text(
                          recipe.category ?? 'N/A',
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: AppSizes.fontSm,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      if (recipe.area != null) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: AppSizes.iconSm,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          recipe.area!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Nutrition Info
                  if (recipe.nutritionInfo != null) ...[
                    _buildNutritionCard(context, lang),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  // Ingredients
                  Text(
                    lang.getText(en: 'Ingredients', vi: 'Nguyên liệu'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ...recipe.ingredients.map(
                    (ing) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: AppSizes.iconSm,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              '${ing.ingredient} - ${ing.measure}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Instructions
                  Text(
                    lang.getText(en: 'Instructions', vi: 'Hướng dẫn'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    recipe.instructionsText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _saveRecipe(context),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  lang.getText(en: 'Save', vi: 'Lưu'),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _addToMeal(context),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(9999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  lang.getText(en: 'Add', vi: 'Thêm'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(BuildContext context, LanguageProvider lang) {
    final nutrition = widget.recipe.nutritionInfo!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: AppSizes.paddingMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NutritionItem(
            label: lang.getText(en: 'Calories', vi: 'Calories'),
            value: '${nutrition.calories?.toInt() ?? 0}',
            unit: 'kcal',
            color: AppColors.caloriesColor,
          ),
          _NutritionItem(
            label: lang.getText(en: 'Protein', vi: 'Protein'),
            value: '${nutrition.protein?.toInt() ?? 0}',
            unit: 'g',
            color: AppColors.proteinColor,
          ),
          _NutritionItem(
            label: lang.getText(en: 'Carbs', vi: 'Carbs'),
            value: '${nutrition.carbs?.toInt() ?? 0}',
            unit: 'g',
            color: AppColors.carbsColor,
          ),
          _NutritionItem(
            label: lang.getText(en: 'Fat', vi: 'Fat'),
            value: '${nutrition.fat?.toInt() ?? 0}',
            unit: 'g',
            color: AppColors.fatColor,
          ),
        ],
      ),
    );
  }
}

/// Nutrition Item Widget for displaying macro values
class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutritionItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
