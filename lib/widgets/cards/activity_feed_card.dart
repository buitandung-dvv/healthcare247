import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Activity Feed Card - Strava-style activity card
class ActivityFeedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String duration;
  final String calories;
  final String timeAgo;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const ActivityFeedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.calories,
    required this.timeAgo,
    this.icon = Icons.fitness_center,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? const Color(0xFFFC4C02);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 22),
                ),
                const SizedBox(width: AppSizes.md),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time ago
                Text(
                  timeAgo,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.md),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  value: duration,
                  label: 'Duration',
                ),
                const SizedBox(width: AppSizes.lg),
                _StatChip(
                  icon: Icons.local_fire_department_outlined,
                  value: calories,
                  label: 'Calories',
                  iconColor: const Color(0xFFFF6B35),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Empty Activity State Widget
class EmptyActivityState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonTap;

  const EmptyActivityState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFC4C02).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run,
              size: 32,
              color: Color(0xFFFC4C02),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton.icon(
            onPressed: onButtonTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC4C02),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

/// Quick Start Workout Card with localization
class QuickStartWorkoutCard extends StatelessWidget {
  final VoidCallback? onStartWorkout;
  final String? titleEn;
  final String? titleVi;
  final String? subtitleEn;
  final String? subtitleVi;

  const QuickStartWorkoutCard({
    super.key,
    this.onStartWorkout,
    this.titleEn,
    this.titleVi,
    this.subtitleEn,
    this.subtitleVi,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng LanguageProvider nếu có, fallback nếu không
    final isVietnamese = Localizations.localeOf(context).languageCode == 'vi';
    final title =
        isVietnamese
            ? (titleVi ?? 'Bắt đầu tập')
            : (titleEn ?? 'Start Workout');
    final subtitle =
        isVietnamese
            ? (subtitleVi ?? 'Theo dõi buổi tập của bạn')
            : (subtitleEn ?? 'Track your exercise session');

    return GestureDetector(
      onTap: onStartWorkout,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFC4C02), Color(0xFFE64A19)],
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFC4C02).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
