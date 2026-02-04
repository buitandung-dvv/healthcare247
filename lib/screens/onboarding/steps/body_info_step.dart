import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Body info step - Height, Weight with ruler picker style
class BodyInfoStep extends StatefulWidget {
  final double? height;
  final double? weight;
  final DateTime? dateOfBirth;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onNext;

  const BodyInfoStep({
    super.key,
    this.height,
    this.weight,
    this.dateOfBirth,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onDateChanged,
    required this.onNext,
  });

  @override
  State<BodyInfoStep> createState() => _BodyInfoStepState();
}

class _BodyInfoStepState extends State<BodyInfoStep> {
  late double _weight;
  late double _height;
  bool _useKg = true;
  bool _useCm = true;

  late FixedExtentScrollController _weightController;
  late FixedExtentScrollController _heightController;

  @override
  void initState() {
    super.initState();
    _weight = widget.weight ?? 70.0;
    _height = widget.height ?? 170.0;

    // Initialize scroll controllers
    _weightController = FixedExtentScrollController(
      initialItem: (_weight - 30).toInt(), // Weight starts from 30kg
    );
    _heightController = FixedExtentScrollController(
      initialItem: (_height - 100).toInt(), // Height starts from 100cm
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.xl),

          // Title
          Text(
            'Hãy cho chúng tôi biết\nthêm về bạn',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Hãy cho chúng tôi biết thêm về bạn\nđể giúp tăng kết quả tập luyện',
            style: TextStyle(
              fontSize: AppSizes.fontMd,
              color: secondaryColor,
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppSizes.xxl),

          // Weight Section
          _buildWeightSection(isDark, textColor, secondaryColor),

          const SizedBox(height: AppSizes.xl),

          // Height Section
          _buildHeightSection(isDark, textColor, secondaryColor),

          const SizedBox(height: AppSizes.xl),

          // Date of Birth Section
          _buildDateOfBirthSection(isDark, textColor, secondaryColor),

          const SizedBox(height: AppSizes.xxl),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthSection(
    bool isDark,
    Color textColor,
    Color secondaryColor,
  ) {
    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final displayText =
        widget.dateOfBirth != null
            ? '${widget.dateOfBirth!.day.toString().padLeft(2, '0')}/${widget.dateOfBirth!.month.toString().padLeft(2, '0')}/${widget.dateOfBirth!.year}'
            : 'Chọn ngày sinh';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày sinh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizes.md),
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color:
                        widget.dateOfBirth != null
                            ? textColor
                            : (isDark
                                ? AppColors.darkTextHint
                                : AppColors.textHint),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: secondaryColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onDateChanged(picked);
    }
  }

  Widget _buildWeightSection(
    bool isDark,
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and Unit Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cân nặng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            _buildUnitToggle(
              firstUnit: 'kg',
              secondUnit: 'lbs',
              isFirst: _useKg,
              onChanged: (value) {
                setState(() => _useKg = value);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Weight Value Display
        Center(
          child: Text(
            _useKg
                ? '${_weight.toStringAsFixed(1)} kg'
                : '${(_weight * 2.205).toStringAsFixed(1)} lbs',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Weight Ruler Picker
        _buildHorizontalRulerPicker(
          controller: _weightController,
          minValue: 30,
          maxValue: 200,
          currentValue: _weight,
          onChanged: (value) {
            setState(() => _weight = value.toDouble());
            widget.onWeightChanged(value.toDouble());
            HapticFeedback.selectionClick();
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildHeightSection(
    bool isDark,
    Color textColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and Unit Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chiều cao',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            _buildUnitToggle(
              firstUnit: 'cm',
              secondUnit: 'ft',
              isFirst: _useCm,
              onChanged: (value) {
                setState(() => _useCm = value);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),

        // Height Value Display
        Center(
          child:
              _useCm
                  ? Text(
                    '${_height.toStringAsFixed(0)} cm',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: textColor,
                    ),
                  )
                  : RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                      ),
                      children: [
                        TextSpan(text: '${(_height / 30.48).floor()}'),
                        TextSpan(
                          text: 'ft ',
                          style: TextStyle(fontSize: 24, color: secondaryColor),
                        ),
                        TextSpan(text: '${((_height % 30.48) / 2.54).round()}'),
                        TextSpan(
                          text: 'in',
                          style: TextStyle(fontSize: 24, color: secondaryColor),
                        ),
                      ],
                    ),
                  ),
        ),
        const SizedBox(height: AppSizes.md),

        // Height Ruler Picker
        _buildHorizontalRulerPicker(
          controller: _heightController,
          minValue: 100,
          maxValue: 250,
          currentValue: _height,
          onChanged: (value) {
            setState(() => _height = value.toDouble());
            widget.onHeightChanged(value.toDouble());
            HapticFeedback.selectionClick();
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildUnitToggle({
    required String firstUnit,
    required String secondUnit,
    required bool isFirst,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUnitButton(
            text: firstUnit,
            isSelected: isFirst,
            onTap: () => onChanged(true),
          ),
          _buildUnitButton(
            text: secondUnit,
            isSelected: !isFirst,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalRulerPicker({
    required FixedExtentScrollController controller,
    required int minValue,
    required int maxValue,
    required double currentValue,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    final itemCount = maxValue - minValue + 1;

    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ruler picker
          RotatedBox(
            quarterTurns: -1,
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 20,
              perspective: 0.003,
              diameterRatio: 2.5,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                onChanged(minValue + index);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: itemCount,
                builder: (context, index) {
                  final value = minValue + index;
                  final isSelected = value == currentValue.toInt();
                  final isMajorTick = value % 5 == 0;

                  return RotatedBox(
                    quarterTurns: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isMajorTick)
                          Text(
                            value.toString(),
                            style: TextStyle(
                              fontSize: isSelected ? 14 : 11,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.darkTextHint
                                          : AppColors.textHint),
                            ),
                          ),
                        Container(
                          width: 2,
                          height: isMajorTick ? 24 : 12,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.border),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Center indicator
          Container(
            width: 3,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
