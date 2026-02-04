import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Gender selection step
class GenderStep extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  const GenderStep({
    super.key,
    this.selectedGender,
    required this.onChanged,
    required this.onNext,
  });

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
            'Giới tính của bạn?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Điều này giúp chúng tôi cá nhân hóa trải nghiệm của bạn',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
          // Gender options
          _GenderOption(
            icon: Icons.male_rounded,
            label: 'Nam',
            value: 'male',
            isSelected: selectedGender == 'male',
            onTap: () => onChanged('male'),
            isDark: isDark,
          ),
          const SizedBox(height: AppSizes.md),
          _GenderOption(
            icon: Icons.female_rounded,
            label: 'Nữ',
            value: 'female',
            isSelected: selectedGender == 'female',
            onTap: () => onChanged('female'),
            isDark: isDark,
          ),
          const SizedBox(height: AppSizes.xxl),
          // Next button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedGender != null ? onNext : null,
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

class _GenderOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _GenderOption({
    required this.icon,
    required this.label,
    required this.value,
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
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? AppColors.primary : textColor,
              ),
              const SizedBox(width: AppSizes.md),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : textColor,
                ),
              ),
              const Spacer(),
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
