import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/language_provider.dart';

/// Goals Screen — Stitch Design
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late int _calorieTarget;
  late double _proteinPct;
  late double _carbsPct;
  late double _fatPct;
  late int _waterTarget;
  late String _activityLevel;
  late Set<int> _trainingDays;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    final goalsProvider = context.read<GoalsProvider>();
    final goals = goalsProvider.userGoals;

    // Load from provider/DB if available, otherwise use defaults
    _calorieTarget = goals?.caloriesGoal.toInt() ?? 2000;
    _proteinPct = goals != null && goals.caloriesGoal > 0
        ? (goals.proteinGoal * 4 / goals.caloriesGoal * 100).clamp(5, 70)
        : 30;
    _carbsPct = goals != null && goals.caloriesGoal > 0
        ? (goals.carbsGoal * 4 / goals.caloriesGoal * 100).clamp(5, 70)
        : 50;
    _fatPct = goals != null && goals.caloriesGoal > 0
        ? (goals.fatGoal * 9 / goals.caloriesGoal * 100).clamp(5, 70)
        : 20;
    _waterTarget = goals?.waterGoalMl ?? 2500;
    _activityLevel = user?.activityLevel ?? 'moderately_active';
    _trainingDays = {1, 3, 5};

    // Load goals from DB if not yet loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId > 0) {
        context.read<GoalsProvider>().loadIfNeeded(userId);
      }
    });
  }

  void _adjustCalories(int delta) {
    setState(() {
      _calorieTarget = (_calorieTarget + delta).clamp(1000, 5000);
    });
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId <= 0) return;

    setState(() => _isSaving = true);

    final proteinGoal = (_calorieTarget * _proteinPct / 100 / 4);
    final carbsGoal = (_calorieTarget * _carbsPct / 100 / 4);
    final fatGoal = (_calorieTarget * _fatPct / 100 / 9);

    final success = await context.read<GoalsProvider>().updateUserGoals(
      userId: userId,
      caloriesGoal: _calorieTarget.toDouble(),
      proteinGoal: proteinGoal,
      carbsGoal: carbsGoal,
      fatGoal: fatGoal,
      waterGoalMl: _waterTarget,
      workoutsPerWeek: _trainingDays.length,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Đã lưu mục tiêu!' : 'Lưu thất bại, thử lại!',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          lang.getText(en: 'My Goals', vi: 'Mục tiêu'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    lang.getText(en: 'Save', vi: 'Lưu'),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calorie Target
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.getText(
                      en: 'Daily Calorie Target',
                      vi: 'Mục tiêu calo mỗi ngày',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$_calorieTarget',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _adjustBtn(
                              Icons.remove,
                              () => _adjustCalories(-50),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '50',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                            _adjustBtn(Icons.add, () => _adjustCalories(50)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_calorieTarget / 5000).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Macros
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.getText(en: 'Macros', vi: 'Chỉ số dinh dưỡng'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_proteinPct.toInt()}% P - ${_carbsPct.toInt()}% C - ${_fatPct.toInt()}% F',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _macroSlider(
                    'Protein (${(_calorieTarget * _proteinPct / 100 / 4).toInt()}g)',
                    _proteinPct,
                    AppColors.primary,
                    (v) => setState(() => _proteinPct = v),
                  ),
                  const SizedBox(height: 16),
                  _macroSlider(
                    'Carbs (${(_calorieTarget * _carbsPct / 100 / 4).toInt()}g)',
                    _carbsPct,
                    const Color(0xFFFFA726),
                    (v) => setState(() => _carbsPct = v),
                  ),
                  const SizedBox(height: 16),
                  _macroSlider(
                    '${lang.getText(en: 'Fat', vi: 'Chất béo')} (${(_calorieTarget * _fatPct / 100 / 9).toInt()}g)',
                    _fatPct,
                    const Color(0xFFEF5350),
                    (v) => setState(() => _fatPct = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Water Target
            _card(
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Color(0xFF42A5F5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.getText(en: 'Water Target', vi: 'Mục tiêu nước'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            activeTrackColor: const Color(0xFF42A5F5),
                            inactiveTrackColor: const Color(0xFFE2E8F0),
                            thumbColor: const Color(0xFF42A5F5),
                          ),
                          child: Slider(
                            value: _waterTarget.toDouble(),
                            min: 500,
                            max: 5000,
                            divisions: 18,
                            onChanged: (v) =>
                                setState(() => _waterTarget = v.toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(_waterTarget / 1000).toStringAsFixed(1)} L',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Activity Level
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.getText(en: 'Activity Level', vi: 'Mức độ vận động'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _activityChip(
                        'sedentary',
                        lang.getText(en: 'Sedentary', vi: 'Ít vận động'),
                      ),
                      _activityChip(
                        'moderately_active',
                        lang.getText(en: 'Moderate', vi: 'Trung bình'),
                      ),
                      _activityChip(
                        'very_active',
                        lang.getText(en: 'Active', vi: 'Năng động'),
                      ),
                      _activityChip(
                        'extra_active',
                        lang.getText(en: 'Very Active', vi: 'Rất năng động'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Training Days
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.getText(en: 'Training Days', vi: 'Ngày tập luyện'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _dayCircle(1, 'T2'),
                      _dayCircle(2, 'T3'),
                      _dayCircle(3, 'T4'),
                      _dayCircle(4, 'T5'),
                      _dayCircle(5, 'T6'),
                      _dayCircle(6, 'T7'),
                      _dayCircle(7, 'CN'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9999),
                    onTap: _save,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.getText(en: 'Save Goals', vi: 'Lưu mục tiêu'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _adjustBtn(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _macroSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
            ),
            Text(
              '${value.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: color,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: color,
          ),
          child: Slider(
            value: value,
            min: 5,
            max: 70,
            divisions: 13,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _activityChip(String value, String label) {
    final isSelected = _activityLevel == value;
    return GestureDetector(
      onTap: () => setState(() => _activityLevel = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _dayCircle(int day, String label) {
    final isSelected = _trainingDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _trainingDays.remove(day);
          } else {
            _trainingDays.add(day);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
