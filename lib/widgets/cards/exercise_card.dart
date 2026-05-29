import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/exercise_model.dart';
import '../common/common_widgets.dart';

/// Exercise Card Widget - Grid/Square style (similar to RecipeCard)
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onAddToPlan;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.onAddToPlan,
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
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exercise Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.3,
                      child: exercise.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: exercise.images.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      AppColors.primary.withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.2),
                                      AppColors.primary.withValues(alpha: 0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.2),
                                    AppColors.primary.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                  // Favourite icon overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  // Level badge overlay (bottom-left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _StitchLevelChip(level: exercise.level),
                  ),
                ],
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Build up to 4 tags: primary (blue) + secondary (orange)
                    Builder(builder: (context) {
                      const maxTags = 4;
                      final tags = <Widget>[];
                      for (final m in exercise.primaryMuscles) {
                        if (tags.length >= maxTags) break;
                        tags.add(_StitchOutlineChip(
                          label: m.toUpperCase(),
                          color: AppColors.primary,
                        ));
                      }
                      for (final m in exercise.secondaryMuscles) {
                        if (tags.length >= maxTags) break;
                        tags.add(_StitchOutlineChip(
                          label: m.toUpperCase(),
                          color: const Color(0xFFF59E0B),
                        ));
                      }
                      if (tags.isEmpty) return const SizedBox.shrink();
                      return Wrap(
                        spacing: 4,
                        runSpacing: 3,
                        children: tags,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Exercise Card (for lists)
class ExerciseListTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ExerciseListTile({
    super.key,
    required this.exercise,
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
              width: 60,
              height: 60,
              child: exercise.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: exercise.images.first,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      placeholder: (context, url) =>
                          Container(color: AppColors.background),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
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
                  exercise.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    LevelBadge(level: exercise.level),
                    const SizedBox(width: AppSizes.sm),
                    if (exercise.primaryMuscles.isNotEmpty)
                      Text(
                        exercise.primaryMuscles.first,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
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

class _StitchOutlineChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StitchOutlineChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
        color: color.withAlpha(15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StitchLevelChip extends StatelessWidget {
  final String level;

  const _StitchLevelChip({required this.level});

  Color get _chipColor {
    switch (level.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'medium':
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'hard':
      case 'advanced':
      case 'expert':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _chipColor.withAlpha(200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
