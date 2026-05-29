import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Body info step — Stitch design: Gender cards + Height/Weight rulers + DOB picker (merged)
class BodyInfoStep extends StatefulWidget {
  final String? gender;
  final double? height;
  final double? weight;
  final DateTime? dateOfBirth;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onNext;

  const BodyInfoStep({
    super.key,
    this.gender,
    this.height,
    this.weight,
    this.dateOfBirth,
    required this.onGenderChanged,
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

  late FixedExtentScrollController _weightController;
  late FixedExtentScrollController _heightController;

  @override
  void initState() {
    super.initState();
    _weight = widget.weight ?? 65.0;
    _height = widget.height ?? 170.0;

    _weightController = FixedExtentScrollController(
      initialItem: (_weight - 30).toInt(),
    );
    _heightController = FixedExtentScrollController(
      initialItem: (_height - 100).toInt(),
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
        isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Title — Stitch style
          Text(
            'Thông tin cơ thể của bạn',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Giúp chúng tôi tính toán chỉ số phù hợp',
            style: TextStyle(fontSize: 14, color: secondaryColor),
          ),

          const SizedBox(height: 24),

          // ── GENDER ─────────────────────────
          Text(
            'Giới tính',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  icon: Icons.male_rounded,
                  label: 'Nam',
                  isSelected: widget.gender == 'male',
                  onTap: () => widget.onGenderChanged('male'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _GenderCard(
                  icon: Icons.female_rounded,
                  label: 'Nữ',
                  isSelected: widget.gender == 'female',
                  onTap: () => widget.onGenderChanged('female'),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── HEIGHT ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chiều cao',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_height.toInt()}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' cm',
                      style: TextStyle(fontSize: 14, color: secondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

          const SizedBox(height: 24),

          // ── WEIGHT ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cân nặng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_weight.toInt()}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' kg',
                      style: TextStyle(fontSize: 14, color: secondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

          const SizedBox(height: 28),

          // ── DATE OF BIRTH ──────────────────
          _buildDateOfBirthSection(isDark, textColor, secondaryColor),

          const SizedBox(height: 32),

          // ── GRADIENT BUTTON ────────────────
          GestureDetector(
            onTap: widget.onNext,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
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
              style: TextStyle(fontSize: 15, color: secondaryColor),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── DATE OF BIRTH ───────────────────────────────────────────

  Widget _buildDateOfBirthSection(
    bool isDark,
    Color textColor,
    Color secondaryColor,
  ) {
    final displayText =
        widget.dateOfBirth != null
            ? '${widget.dateOfBirth!.day.toString().padLeft(2, '0')} / ${widget.dateOfBirth!.month.toString().padLeft(2, '0')} / ${widget.dateOfBirth!.year}'
            : 'Chọn ngày sinh';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày sinh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        widget.dateOfBirth != null ? textColor : secondaryColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 22,
                  color: secondaryColor,
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

  // ─── HORIZONTAL RULER PICKER ─────────────────────────────────

  Widget _buildHorizontalRulerPicker({
    required FixedExtentScrollController controller,
    required int minValue,
    required int maxValue,
    required double currentValue,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    final itemCount = maxValue - minValue + 1;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
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
                              fontSize: isSelected ? 13 : 10,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w700
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
                          height: isMajorTick ? 20 : 10,
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
          // Center indicator triangle
          Positioned(
            top: 0,
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GENDER CARD ──────────────────────────────────────────────

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
        height: 100,
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
              size: 36,
              color:
                  isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
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
