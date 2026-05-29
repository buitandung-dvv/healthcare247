import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Activity level step — Stitch design: 5 levels with icon circles + radio
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
      'icon': Icons.weekend_rounded,
      'label': 'Ít vận động',
      'desc': 'Công việc văn phòng, ít di chuyển',
    },
    {
      'id': 'lightly_active',
      'icon': Icons.directions_walk_rounded,
      'label': 'Nhẹ nhàng',
      'desc': 'Đi bộ nhẹ nhàng, 1-2 lần/tuần',
    },
    {
      'id': 'moderately_active',
      'icon': Icons.directions_run_rounded,
      'label': 'Trung bình',
      'desc': 'Tập luyện 3-4 lần/tuần',
    },
    {
      'id': 'very_active',
      'icon': Icons.sports_martial_arts_rounded,
      'label': 'Năng động',
      'desc': 'Tập luyện 5-6 lần/tuần',
    },
    {
      'id': 'extra_active',
      'icon': Icons.local_fire_department_rounded,
      'label': 'Rất năng động',
      'desc': 'Tập luyện hàng ngày hoặc công việc nặng',
    },
  ];

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
          Text(
            'Mức độ vận động của bạn?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn mức độ phù hợp với lối sống hiện tại của bạn để chúng tôi tính toán lộ trình chính xác nhất.',
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Activity level cards
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children:
                    _levels
                        .map(
                          (level) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _StitchOptionCard(
                              icon: level['icon'],
                              label: level['label'],
                              description: level['desc'],
                              isSelected: selectedLevel == level['id'],
                              onTap: () => onChanged(level['id']),
                              isDark: isDark,
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Gradient Next button
          GestureDetector(
            onTap: selectedLevel != null ? onNext : null,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient:
                    selectedLevel != null
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
                    selectedLevel != null
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
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Quay lại',
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Stitch-style option card with icon circle + radio indicator
class _StitchOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _StitchOptionCard({
    required this.icon,
    required this.label,
    required this.description,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color:
                    isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected
                              ? const Color(0xFF0F172A)
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.primary
                          : (isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1)),
                  width: isSelected ? 7 : 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
