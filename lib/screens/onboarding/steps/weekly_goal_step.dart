import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Weekly goal step - Days per week (like example UI)
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
  bool _showDayPicker = false;

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
            'Đặt mục tiêu hàng tuần\ncủa bạn',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Chúng tôi khuyến nghị tập luyện ít nhất 3 ngày mỗi tuần để có kết quả tốt hơn',
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
          // Days selector
          Row(
            children: [
              Text('🗓️', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: AppSizes.sm),
              Text(
                'Ngày tập luyện hàng tuần',
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          // Day number grid
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: List.generate(7, (index) {
              final day = index + 1;
              final isSelected = widget.daysPerWeek == day;
              return _DayButton(
                day: day,
                isSelected: isSelected,
                onTap: () => widget.onDaysChanged(day),
                isDark: isDark,
              );
            }),
          ),
          const SizedBox(height: AppSizes.xl),
          // Start day picker
          InkWell(
            onTap: () => setState(() => _showDayPicker = !_showDayPicker),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Text('📅', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày đầu tiên của tuần',
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getDayName(widget.startDay),
                          style: TextStyle(
                            fontSize: AppSizes.fontMd,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showDayPicker
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_showDayPicker) _buildDayPickerSheet(isDark),
          const SizedBox(height: AppSizes.xxl),
          // Complete button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                elevation: 0,
              ),
              child: const Text(
                'HOÀN TẤT',
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

  Widget _buildDayPickerSheet(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _DayPickerOption(
            label: 'Chủ Nhật',
            value: 'sunday',
            isSelected: widget.startDay == 'sunday',
            onTap: () {
              widget.onStartDayChanged('sunday');
              setState(() => _showDayPicker = false);
            },
            isDark: isDark,
          ),
          _DayPickerOption(
            label: 'Thứ Hai',
            value: 'monday',
            isSelected: widget.startDay == 'monday',
            onTap: () {
              widget.onStartDayChanged('monday');
              setState(() => _showDayPicker = false);
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _getDayName(String day) {
    switch (day) {
      case 'sunday':
        return 'Chủ Nhật';
      case 'monday':
        return 'Thứ Hai';
      default:
        return 'Thứ Hai';
    }
  }
}

class _DayButton extends StatelessWidget {
  final int day;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.border),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayPickerOption extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _DayPickerOption({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
