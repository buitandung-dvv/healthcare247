import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Fitness goal selection step - Maintain Weight, Build Muscle, Lose Weight
class FitnessGoalStep extends StatelessWidget {
  final String? selectedGoal;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const FitnessGoalStep({
    super.key,
    this.selectedGoal,
    required this.onChanged,
    required this.onNext,
  });

  static const List<Map<String, dynamic>> _goals = [
    {
      'id': 'maintain_weight',
      'emoji': '⚖️',
      'label': 'Duy trì cân nặng',
      'desc': 'Giữ nguyên cân nặng hiện tại',
    },
    {
      'id': 'build_muscle',
      'emoji': '💪',
      'label': 'Tăng cơ',
      'desc': 'Xây dựng cơ bắp và tăng sức mạnh',
    },
    {
      'id': 'lose_weight',
      'emoji': '🏃',
      'label': 'Giảm cân',
      'desc': 'Giảm mỡ và cân nặng',
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
            'Mục tiêu của bạn\nlà gì?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Chọn mục tiêu để chúng tôi điều chỉnh kế hoạch phù hợp với bạn',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Goal options
          ..._goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: _GoalOption(
                emoji: goal['emoji'],
                label: goal['label'],
                description: goal['desc'],
                isSelected: selectedGoal == goal['id'],
                onTap: () => onChanged(goal['id']),
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
              onPressed: selectedGoal != null ? onNext : null,
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

class _GoalOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _GoalOption({
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
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppSizes.fontLg,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
