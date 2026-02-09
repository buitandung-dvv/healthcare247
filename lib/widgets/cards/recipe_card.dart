import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/translation_helper.dart';
import '../../data/models/recipe_model.dart';
import '../common/common_widgets.dart';

/// Recipe Card Widget - Modern design
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onAddToMealPlan;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onAddToMealPlan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image with gradient overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child:
                        recipe.imageUrl != null
                            ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.secondary.withValues(
                                            alpha: 0.2,
                                          ),
                                          AppColors.accent.withValues(
                                            alpha: 0.1,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.secondary.withValues(
                                            alpha: 0.2,
                                          ),
                                          AppColors.accent.withValues(
                                            alpha: 0.1,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.restaurant,
                                      size: 48,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                            )
                            : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.secondary.withValues(alpha: 0.2),
                                    AppColors.accent.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                size: 48,
                                color: AppColors.secondary,
                              ),
                            ),
                  ),
                ),

                // Category Badge - Modern gradient style
                if (recipe.category != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.secondaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        TranslationHelper.translateRecipeCategory(
                          context,
                          recipe.category!,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Area Badge - Modern glass style
                if (recipe.area != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.darkCard.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public,
                            size: 12,
                            color:
                                isDark
                                    ? AppColors.textWhite
                                    : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TranslationHelper.translateRecipeArea(
                              context,
                              recipe.area!,
                            ),
                            style: TextStyle(
                              color:
                                  isDark
                                      ? AppColors.textWhite
                                      : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Add to meal plan button
                if (onAddToMealPlan != null)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onAddToMealPlan,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Recipe Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Nutrition Info
                  if (recipe.nutritionInfo != null) ...[
                    Row(
                      children: [
                        _NutritionBadge(
                          icon: Icons.local_fire_department,
                          value:
                              '${recipe.nutritionInfo!.calories?.toInt() ?? 0}',
                          unit: 'cal',
                          color: AppColors.caloriesColor,
                        ),
                        const SizedBox(width: AppSizes.md),
                        _NutritionBadge(
                          icon: Icons.egg_alt,
                          value:
                              '${recipe.nutritionInfo!.protein?.toInt() ?? 0}',
                          unit: 'g',
                          color: AppColors.proteinColor,
                        ),
                        const SizedBox(width: AppSizes.md),
                        _NutritionBadge(
                          icon: Icons.grain,
                          value: '${recipe.nutritionInfo!.carbs?.toInt() ?? 0}',
                          unit: 'g',
                          color: AppColors.carbsColor,
                        ),
                      ],
                    ),
                  ],

                  // Tags
                  if (recipe.tagList.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: AppSizes.xs,
                      runSpacing: AppSizes.xs,
                      children:
                          recipe.tagList
                              .take(3)
                              .map((tag) => _TagChip(tag: tag))
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Recipe Card (for lists)
class RecipeListTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RecipeListTile({
    super.key,
    required this.recipe,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: SizedBox(
              width: 70,
              height: 70,
              child:
                  recipe.imageUrl != null
                      ? CachedNetworkImage(
                        imageUrl: recipe.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Container(color: AppColors.background),
                        errorWidget:
                            (context, url, error) => Container(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.restaurant,
                                color: AppColors.secondary,
                              ),
                            ),
                      )
                      : Container(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppColors.secondary,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    if (recipe.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: Text(
                          TranslationHelper.translateRecipeCategory(
                            context,
                            recipe.category!,
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                    ],
                    if (recipe.area != null)
                      Text(
                        TranslationHelper.translateRecipeArea(
                          context,
                          recipe.area!,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                if (recipe.nutritionInfo?.calories != null) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '${recipe.nutritionInfo!.calories!.toInt()} calories',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                  ),
                ],
              ],
            ),
          ),

          // Trailing
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _NutritionBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color color;

  const _NutritionBadge({
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: color),
        const SizedBox(width: 2),
        Text(
          '$value$unit',
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '#$tag',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
