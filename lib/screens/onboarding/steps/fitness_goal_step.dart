import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Fitness goal step — Stitch design: cards with icon circles + radio indicators
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
      'id': 'lose_weight',
      'icon': Icons.fitness_center_rounded,
      'label': 'Giảm cân',
      'desc': 'Burn fat, stay fit',
    },
    {
      'id': 'build_muscle',
      'icon': Icons.sports_martial_arts_rounded,
      'label': 'Tăng cơ',
      'desc': 'Build muscle mass',
    },
    {
      'id': 'maintain_weight',
      'icon': Icons.self_improvement_rounded,
      'label': 'Duy trì sức khỏe',
      'desc': 'Balance body and mind',
    },
    {
      'id': 'improve_endurance',
      'icon': Icons.directions_run_rounded,
      'label': 'Tăng sức bền',
      'desc': 'Improve athletic ability',
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            'Mục tiêu của bạn là gì?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          // Goal cards
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children:
                    _goals
                        .map(
                          (goal) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StitchOptionCard(
                              icon: goal['icon'],
                              label: goal['label'],
                              description: goal['desc'],
                              isSelected: selectedGoal == goal['id'],
                              onTap: () => onChanged(goal['id']),
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
            onTap: selectedGoal != null ? onNext : null,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient:
                    selectedGoal != null
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
                    selectedGoal != null
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

          // "Quay lại" text
          const SizedBox(height: 12),
          Text(
            'Quay lại',
            style: TextStyle(
              fontSize: 15,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF94A3B8),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              width: 52,
              height: 52,
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
                size: 26,
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
