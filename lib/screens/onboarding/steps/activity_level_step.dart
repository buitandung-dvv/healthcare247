import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Activity level selection step with emoji
class ActivityLevelStep extends StatelessWidget {
  final String? selectedLevel;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const ActivityLevelStep({
    super.key,
    this.selectedLevel,
    required this.onChanged,
    required this.onNext,
  });

  static const List<Map<String, dynamic>> _levels = [
    {
      'id': 'sedentary',
      'emoji': '🧘',
      'label': 'Ít vận động',
      'desc': 'Ít hoặc không tập thể dục',
    },
    {
      'id': 'lightly_active',
      'emoji': '🚶',
      'label': 'Hơi tích cực',
      'desc': 'Tập nhẹ 1-3 ngày/tuần',
    },
    {
      'id': 'moderately_active',
      'emoji': '🏃',
      'label': 'Tích cực vừa phải',
      'desc': 'Tập vừa 3-5 ngày/tuần',
    },
    {
      'id': 'very_active',
      'emoji': '🏋️',
      'label': 'Rất tích cực',
      'desc': 'Tập nặng 6-7 ngày/tuần',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.xl),
          Text(
            'Mức độ vận động\ncủa bạn?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Activity options
          ..._levels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: _ActivityOption(
                emoji: level['emoji'],
                label: level['label'],
                description: level['desc'],
                isSelected: selectedLevel == level['id'],
                onTap: () => onChanged(level['id']),
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Next button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedLevel != null ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDark ? AppColors.darkBorder : AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                elevation: 0,
              ),
              child: const Text(
                'TIẾP THEO',
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}

class _ActivityOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ActivityOption({
    required this.emoji,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : isDark
            ? AppColors.darkCard
            : Colors.white;
    final borderColor =
        isSelected
            ? AppColors.primary
            : isDark
            ? AppColors.darkBorder
            : AppColors.border;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppSizes.fontMd,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : textColor,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
