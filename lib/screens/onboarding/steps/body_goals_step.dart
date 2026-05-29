import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../widgets/buttons/gradient_button.dart';

/// Body goals step - Focus areas with centered image
class BodyGoalsStep extends StatelessWidget {
  final List<String> selectedGoals;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  const BodyGoalsStep({
    super.key,
    required this.selectedGoals,
    required this.onChanged,
    required this.onNext,
  });

  void _toggleGoal(String goalId) {
    List<String> updated;

    if (goalId == 'full_body') {
      // Selecting full_body: toggle it and clear all others
      if (selectedGoals.contains('full_body')) {
        updated = []; // Deselect full_body
      } else {
        updated = ['full_body']; // Select only full_body
      }
    } else {
      // Selecting a specific body part
      updated = List<String>.from(selectedGoals);
      // Remove full_body if it was selected
      updated.remove('full_body');

      if (updated.contains(goalId)) {
        updated.remove(goalId);
      } else {
        updated.add(goalId);
      }
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.sm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chọn Mục Tiêu Tập Luyện',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),

        // Main content
        Expanded(
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Fitness image - BIG, takes most of the right side
                Positioned(
                  left: 80,
                  right: -80,
                  top: -50,
                  bottom: -50,
                  child: Image.asset(
                    'assets/images/fitness_man.png',
                    fit: BoxFit.contain,
                  ),
                ),

                // Options on the left side
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOptionChip('full_body', 'Toàn thân', isDark),
                      const SizedBox(height: 20),
                      _buildOptionChip('arms', 'Cánh tay', isDark),
                      const SizedBox(height: 20),
                      _buildOptionChip('chest', 'Ngực', isDark),
                      const SizedBox(height: 20),
                      _buildOptionChip('abs', 'Bụng', isDark),
                      const SizedBox(height: 20),
                      _buildOptionChip('legs', 'Chân', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom button
        Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: GradientButton(
            text: 'TIẾP THEO',
            onPressed: selectedGoals.isNotEmpty ? onNext : null,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionChip(String id, String label, bool isDark) {
    final isSelected = selectedGoals.contains(id);
    final isFullBodySelected = selectedGoals.contains('full_body');
    // Disable other buttons when full_body is selected
    final isDisabled = isFullBodySelected && id != 'full_body';

    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleGoal(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              isDisabled
                  ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
                  : (isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkCard : Colors.white)),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color:
                isDisabled
                    ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                    : (isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.border)),
            width: 1.5,
          ),
          boxShadow:
              isDisabled
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isDisabled
                      ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500)
                      : (isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
