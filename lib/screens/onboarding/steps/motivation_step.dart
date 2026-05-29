import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/buttons/gradient_button.dart';

/// Motivation step - What drives you (like example UI)
class MotivationStep extends StatelessWidget {
  final List<String> selectedMotivations;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  const MotivationStep({
    super.key,
    required this.selectedMotivations,
    required this.onChanged,
    required this.onNext,
  });

  static const List<Map<String, dynamic>> _motivations = [
    {'id': 'confidence', 'emoji': '😊', 'label': 'Cảm thấy tự tin'},
    {'id': 'stress', 'emoji': '🎈', 'label': 'Giải tỏa căng thẳng'},
    {'id': 'health', 'emoji': '💪', 'label': 'Cải thiện sức khỏe'},
    {'id': 'energy', 'emoji': '😃', 'label': 'Tăng cường năng lượng'},
  ];

  void _toggleMotivation(String id) {
    final updated = List<String>.from(selectedMotivations);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    onChanged(updated);
  }

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
            'Điều gì thúc đẩy bạn\nnhiều nhất?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Chọn tất cả những gì phù hợp',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Motivation options
          ..._motivations.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: _MotivationOption(
                emoji: m['emoji'],
                label: m['label'],
                isSelected: selectedMotivations.contains(m['id']),
                onTap: () => _toggleMotivation(m['id']),
                isDark: isDark,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Next button
          GradientButton(
            text: 'TIẾP THEO',
            onPressed: selectedMotivations.isNotEmpty ? onNext : null,
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}

class _MotivationOption extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _MotivationOption({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isSelected
            ? AppColors.selectedBg
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
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primary : textColor,
                  ),
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
