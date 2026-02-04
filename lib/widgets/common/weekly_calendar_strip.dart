import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Weekly calendar strip như trong example UI
/// Hiển thị hàng ngày trong tuần với ngày được chọn
class WeeklyCalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime? startDate;
  final ValueChanged<DateTime>? onDateSelected;
  final int streakDays;
  final EdgeInsets padding;

  const WeeklyCalendarStrip({
    super.key,
    required this.selectedDate,
    this.startDate,
    this.onDateSelected,
    this.streakDays = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSizes.md),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = startDate ?? _getWeekStart(DateTime.now());

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month/Year header
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMonthYear(selectedDate),
                  style: TextStyle(
                    fontSize: AppSizes.fontMd,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                ),
                if (streakDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streakDays',
                          style: const TextStyle(
                            fontSize: AppSizes.fontSm,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Days row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = now.add(Duration(days: index));
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return _DayItem(
                date: date,
                isSelected: isSelected,
                isToday: isToday,
                isDark: isDark,
                onTap:
                    onDateSelected != null ? () => onDateSelected!(date) : null,
              );
            }),
          ),
        ],
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return '${months[date.month - 1]}, ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isDark;
  final VoidCallback? onTap;

  const _DayItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final dayName = dayNames[date.weekday - 1];

    final selectedColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: AppSizes.fontXs,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? selectedColor
                      : isToday
                      ? selectedColor.withValues(alpha: 0.15)
                      : Colors.transparent,
              shape: BoxShape.circle,
              border:
                  isToday && !isSelected
                      ? Border.all(color: selectedColor, width: 1.5)
                      : null,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected
                          ? Colors.white
                          : isToday
                          ? selectedColor
                          : textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
