import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Gender selection step — Stitch design: side-by-side card selectors
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Title
          Text(
            'Giới tính',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Điều này giúp chúng tôi tính toán chỉ số phù hợp',
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 32),

          // Stitch-style side-by-side gender cards
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  icon: Icons.male_rounded,
                  label: 'Nam',
                  isSelected: selectedGender == 'male',
                  onTap: () => onChanged('male'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderCard(
                  icon: Icons.female_rounded,
                  label: 'Nữ',
                  isSelected: selectedGender == 'female',
                  onTap: () => onChanged('female'),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Gradient Next button
          GestureDetector(
            onTap: selectedGender != null ? onNext : null,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient:
                    selectedGender != null
                        ? const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                        )
                        : LinearGradient(
                          colors: [
                            const Color(0xFF42A5F5).withValues(alpha: 0.4),
                            const Color(0xFF1565C0).withValues(alpha: 0.4),
                          ],
                        ),
                borderRadius: BorderRadius.circular(9999),
                boxShadow:
                    selectedGender != null
                        ? [
                          BoxShadow(
                            color: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                        : null,
              ),
              child: const Center(
                child: Text(
                  'Tiếp theo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Stitch gender card: large rounded box with icon + label, blue border when selected
class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 160,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFFEBF5FF)
                  : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color:
                  isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color:
                    isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
