import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Weekly goal step — Stitch design: day circle toggles (T2-CN) + recommendation tip
class WeeklyGoalStep extends StatefulWidget {
  final int daysPerWeek;
  final String startDay;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<String> onStartDayChanged;
  final VoidCallback onComplete;

  const WeeklyGoalStep({
    super.key,
    required this.daysPerWeek,
    required this.startDay,
    required this.onDaysChanged,
    required this.onStartDayChanged,
    required this.onComplete,
  });

  @override
  State<WeeklyGoalStep> createState() => _WeeklyGoalStepState();
}

class _WeeklyGoalStepState extends State<WeeklyGoalStep> {
  // Track which days are selected (T2=Mon through CN=Sun)
  final Set<int> _selectedDays = {0, 2, 4}; // Default: T2, T4, T6

  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  void _toggleDay(int index) {
    setState(() {
      if (_selectedDays.contains(index)) {
        _selectedDays.remove(index);
      } else {
        _selectedDays.add(index);
      }
    });
    widget.onDaysChanged(_selectedDays.length);
  }

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
            'Bạn muốn tập vào ngày nào?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chúng tôi sẽ nhắc bạn vào những ngày này',
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 32),

          // Day circles — Stitch design: 2 rows (4+3)
          _buildDayGrid(isDark),

          const SizedBox(height: 24),

          // Selected count
          Center(
            child: Text(
              'Bạn đã chọn ${_selectedDays.length} ngày/tuần',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recommendation tip — Stitch design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF5FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Khuyến nghị: 3-5 ngày/tuần cho mục tiêu của bạn',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : const Color(0xFF1565C0),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Gradient "Hoàn tất" button
          GestureDetector(
            onTap: _selectedDays.isNotEmpty ? widget.onComplete : null,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient:
                    _selectedDays.isNotEmpty
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
                    _selectedDays.isNotEmpty
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
                  'Hoàn tất',
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

  Widget _buildDayGrid(bool isDark) {
    return Column(
      children: [
        // First row: T2, T3, T4, T5
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) => _buildDayCircle(i, isDark)),
        ),
        const SizedBox(height: 16),
        // Second row: T6, T7, CN
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...List.generate(3, (i) => _buildDayCircle(i + 4, isDark)),
            // Empty placeholder for alignment
            const SizedBox(width: 70, height: 70),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCircle(int index, bool isDark) {
    final isSelected = _selectedDays.contains(index);

    return GestureDetector(
      onTap: () => _toggleDay(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : (isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1)),
            width: 2,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Text(
            _dayLabels[index],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color:
                  isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }
}
