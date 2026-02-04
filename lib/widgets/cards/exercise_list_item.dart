import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Exercise list item như trong example UI
/// Thumbnail + Title + Subtitle + Duration + Arrow
class ExerciseListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? duration;
  final String? imageUrl;
  final String? level;
  final VoidCallback? onTap;
  final bool showArrow;
  final Widget? trailing;

  const ExerciseListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.duration,
    this.imageUrl,
    this.level,
    this.onTap,
    this.showArrow = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkShadow : AppColors.shadow)
                .withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Row(
              children: [
                // Thumbnail
                _buildThumbnail(isDark),
                const SizedBox(width: AppSizes.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppSizes.fontMd,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null || duration != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (duration != null) ...[
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: mutedColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                duration!,
                                style: TextStyle(
                                  fontSize: AppSizes.fontSm,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                            if (duration != null && subtitle != null)
                              Text(' • ', style: TextStyle(color: mutedColor)),
                            if (subtitle != null)
                              Flexible(
                                child: Text(
                                  subtitle!,
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSm,
                                    color: mutedColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (level != null) ...[
                        const SizedBox(height: 6),
                        _LevelBadge(level: level!, isDark: isDark),
                      ],
                    ],
                  ),
                ),
                // Trailing
                if (trailing != null)
                  trailing!
                else if (showArrow)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: mutedColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(bool isDark) {
    final placeholderColor =
        isDark ? AppColors.darkSurface : AppColors.backgroundAlt;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: SizedBox(
        width: 64,
        height: 64,
        child:
            imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, __) => Container(
                        color: placeholderColor,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  errorWidget:
                      (_, __, ___) => Container(
                        color: placeholderColor,
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.primary.withValues(alpha: 0.5),
                          size: 28,
                        ),
                      ),
                )
                : Container(
                  color: placeholderColor,
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary.withValues(alpha: 0.5),
                    size: 28,
                  ),
                ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final bool isDark;

  const _LevelBadge({required this.level, required this.isDark});

  String _getDisplayLevel(BuildContext context) {
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    if (!isVietnamese) return level;

    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Cơ bản';
      case 'intermediate':
        return 'Trung bình';
      case 'expert':
      case 'advanced':
        return 'Nâng cao';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (level.toLowerCase()) {
      case 'beginner':
      case 'người mới':
        badgeColor = AppColors.beginnerColor;
        break;
      case 'intermediate':
      case 'trung bình':
        badgeColor = AppColors.intermediateColor;
        break;
      case 'expert':
      case 'nâng cao':
        badgeColor = AppColors.expertColor;
        break;
      default:
        badgeColor = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        _getDisplayLevel(context),
        style: TextStyle(
          fontSize: AppSizes.fontXs,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}

/// Workout list item with progress indicator
class WorkoutListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int exerciseCount;
  final int? completedCount;
  final VoidCallback? onTap;

  const WorkoutListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.exerciseCount,
    this.completedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final hasProgress = completedCount != null && completedCount! > 0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkShadow : AppColors.shadow)
                .withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: Container(
                    width: 72,
                    height: 72,
                    color:
                        isDark
                            ? AppColors.darkSurface
                            : AppColors.backgroundAlt,
                    child:
                        imageUrl != null
                            ? CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                            )
                            : Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.primary.withValues(alpha: 0.5),
                              size: 32,
                            ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppSizes.fontLg,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$exerciseCount bài tập',
                            style: TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          if (hasProgress) ...[
                            const SizedBox(width: AppSizes.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Text(
                                '$completedCount/$exerciseCount',
                                style: const TextStyle(
                                  fontSize: AppSizes.fontXs,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mutedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
