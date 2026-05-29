import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/water_tracking_provider.dart';
import '../../providers/workout_plan_provider.dart';
import '../../providers/progress_provider.dart';

/// Date Details Screen — Stitch Design
/// Chi tiết ngày với calorie ring, meal breakdown, water/weight trackers
class DateDetailsScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DateDetailsScreen({super.key, required this.selectedDate});

  @override
  State<DateDetailsScreen> createState() => _DateDetailsScreenState();
}

class _DateDetailsScreenState extends State<DateDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final dateFormat = DateFormat(
      'EEEE, dd/MM/yyyy',
      lang.isVietnamese ? 'vi' : 'en',
    );

    final progress = dashboard.weeklyProgress.firstWhere(
      (p) => DateUtils.isSameDay(p.date, widget.selectedDate),
      orElse: () => dashboard.todayProgress,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(lang, dateFormat),
            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildCalorieRing(lang, progress),
                    const SizedBox(height: 20),
                    _buildMacroSection(lang, progress),
                    const SizedBox(height: 28),
                    _buildMealsSection(lang, progress),
                    const SizedBox(height: 28),
                    _buildWorkoutSection(lang, progress),
                    const SizedBox(height: 20),
                    _buildBottomCards(lang, progress),
                    const SizedBox(height: 20),
                    _buildNotesCard(lang),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(LanguageProvider lang, DateFormat dateFormat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              dateFormat.format(widget.selectedDate),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: AppColors.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null &&
                  !DateUtils.isSameDay(picked, widget.selectedDate)) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DateDetailsScreen(selectedDate: picked),
                    ),
                  );
                }
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calorie Ring ──
  Widget _buildCalorieRing(LanguageProvider lang, dynamic progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final consumed = progress.caloriesConsumed.toInt();
    final goal = 2000;
    final remaining = (goal - consumed).clamp(0, goal);
    final fraction = (consumed / goal).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(180, 180),
                      painter: _CalorieRingPainter(
                        fraction: fraction * _anim.value,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(consumed * _anim.value).toInt()}',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '/ $goal KCAL',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextHint
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${lang.getText(en: "Remaining", vi: "Còn lại")}: $remaining kcal',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Macros ──
  Widget _buildMacroSection(LanguageProvider lang, dynamic progress) {
    return Row(
      children: [
        _buildMacroBar(
          'PROTEIN',
          progress.protein.toInt(),
          150,
          AppColors.proteinColor,
        ),
        const SizedBox(width: 12),
        _buildMacroBar(
          'CARBS',
          progress.carbs?.toInt() ?? 0,
          300,
          AppColors.carbsColor,
        ),
        const SizedBox(width: 12),
        _buildMacroBar(
          'FAT',
          progress.fat?.toInt() ?? 0,
          70,
          AppColors.fatColor,
        ),
      ],
    );
  }

  Widget _buildMacroBar(String label, int value, int goal, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fraction = (value / goal).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${value}G',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: fraction * _anim.value,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'mục tiêu ${goal}g',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Meals Section ──
  Widget _buildMealsSection(LanguageProvider lang, dynamic progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Build meal breakdown from DailyProgress real data
    final totalCal = progress.caloriesConsumed.toInt();
    final mealsCount = progress.mealsLogged as int;

    // Distribute calories per standard meals (breakfast ~25%, lunch ~35%, dinner ~40%)
    final breakfastCal = mealsCount > 0 ? (totalCal * 0.25).toInt() : 0;
    final lunchCal = mealsCount > 0 ? (totalCal * 0.35).toInt() : 0;
    final dinnerCal = mealsCount > 0 ? (totalCal - breakfastCal - lunchCal) : 0;

    final meals = [
      _MealData(
        icon: Icons.wb_sunny,
        iconColor: const Color(0xFFFFB74D),
        name: lang.getText(en: 'Breakfast', vi: 'Bữa sáng'),
        desc: mealsCount > 0
            ? lang.getText(
                en: '$breakfastCal kcal consumed',
                vi: 'Đã nạp $breakfastCal kcal',
              )
            : lang.getText(en: 'Not logged', vi: 'Chưa ghi nhận'),
        kcal: breakfastCal,
      ),
      _MealData(
        icon: Icons.light_mode,
        iconColor: const Color(0xFFFF8A65),
        name: lang.getText(en: 'Lunch', vi: 'Bữa trưa'),
        desc: mealsCount > 0
            ? lang.getText(
                en: '$lunchCal kcal consumed',
                vi: 'Đã nạp $lunchCal kcal',
              )
            : lang.getText(en: 'Not logged', vi: 'Chưa ghi nhận'),
        kcal: lunchCal,
      ),
      _MealData(
        icon: Icons.nightlight_round,
        iconColor: const Color(0xFF5C6BC0),
        name: lang.getText(en: 'Dinner', vi: 'Bữa tối'),
        desc: mealsCount > 0
            ? lang.getText(
                en: '$dinnerCal kcal consumed',
                vi: 'Đã nạp $dinnerCal kcal',
              )
            : lang.getText(en: 'Not logged', vi: 'Chưa ghi nhận'),
        kcal: dinnerCal,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.getText(en: "Today's meals", vi: 'Bữa ăn hôm nay'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              '${progress.caloriesConsumed.toInt()} kcal',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...meals.map((meal) => _buildMealCard(meal)),
        const SizedBox(height: 12),
        // Add meal button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                lang.getText(en: 'Add meal', vi: 'Thêm bữa ăn'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(_MealData meal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meal.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(meal.icon, color: meal.iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    meal.desc,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  '${meal.kcal}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  ' kcal',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Workout Section ──
  Widget _buildWorkoutSection(LanguageProvider lang, dynamic progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workoutPlanProvider = context.watch<WorkoutPlanProvider>();
    final plans = workoutPlanProvider.userPlans;
    final workoutsCompleted = progress.workoutsCompleted as int;
    final caloriesBurned = progress.caloriesBurned;

    // Get today's plan name if available
    final todayPlanName = plans.isNotEmpty
        ? plans.first.name ??
              lang.getText(en: 'Workout Plan', vi: 'Kế hoạch tập')
        : lang.getText(en: 'No plan today', vi: 'Chưa có kế hoạch');

    final exerciseCount = plans.isNotEmpty ? plans.first.details.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.getText(en: "Today's workout", vi: 'Bài tập hôm nay'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayPlanName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      exerciseCount > 0
                          ? '$exerciseCount ${lang.getText(en: 'exercises', vi: 'bài tập')} · ${caloriesBurned.toInt()} kcal'
                          : lang.getText(
                              en: '$workoutsCompleted completed',
                              vi: '$workoutsCompleted đã hoàn thành',
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (workoutsCompleted > 0)
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: isDark
                        ? AppColors.darkTextHint
                        : Colors.grey.shade400,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note, color: Color(0xFFFF9800), size: 18),
              const SizedBox(width: 6),
              Text(
                lang.getText(en: 'Log workout', vi: 'Ghi bài tập'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Water & Weight ──
  Widget _buildBottomCards(LanguageProvider lang, dynamic progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterProvider = context.watch<WaterTrackingProvider>();
    final progressProvider = context.watch<ProgressProvider>();
    final waterIntake = waterProvider.dailyIntake;
    final latestWeight = progressProvider.latestWeight;

    return Row(
      children: [
        // Water — real data from WaterTrackingProvider
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.water_drop,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lang.getText(en: 'WATER', vi: 'NƯỚC'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatNumber(waterIntake.totalMl)} / ${_formatNumber(waterIntake.goalMl)} ml',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: waterIntake.goalMl > 0
                        ? (waterIntake.totalMl / waterIntake.goalMl)
                              .clamp(0, 1)
                              .toDouble()
                        : 0,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Weight — real data from ProgressProvider
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monitor_weight,
                      color: AppColors.fatColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lang.getText(en: 'WEIGHT', vi: 'CÂN NẶNG'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.fatColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: latestWeight > 0
                            ? latestWeight.toStringAsFixed(1)
                            : '--',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: ' kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Format number with comma separators
  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll('.0', '')}k'
          .replaceAll(
            'k',
            ',${(number % 1000).toString().padLeft(3, '0').substring(0, 3)}',
          );
    }
    return number.toString();
  }

  // ── Notes ──
  Widget _buildNotesCard(LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText(en: 'NOTE', vi: 'GHI CHÚ'),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"Hôm nay tập tốt, cảm thấy khỏe"',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painters ──

class _CalorieRingPainter extends CustomPainter {
  final double fraction;

  _CalorieRingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final bgPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter old) =>
      old.fraction != fraction;
}

// ── Data Models ──

class _MealData {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String desc;
  final int kcal;

  _MealData({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.desc,
    required this.kcal,
  });
}
