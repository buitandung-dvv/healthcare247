import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'steps/welcome_step.dart';

import 'steps/body_info_step.dart';
import 'steps/activity_level_step.dart';
import 'steps/fitness_goal_step.dart';
import 'steps/body_goals_step.dart';
import 'steps/motivation_step.dart';
import 'steps/weekly_goal_step.dart';

/// Onboarding data model
class OnboardingData {
  String? gender;
  DateTime? dateOfBirth;
  double? height;
  double? weight;
  String? activityLevel;
  String? fitnessGoal; // maintain_weight, build_muscle, lose_weight
  List<String> bodyGoals = []; // arms, chest, abs, etc.
  List<String> motivations = [];
  int workoutDaysPerWeek = 3;
  String weekStartDay = 'monday';
}

/// Main onboarding flow controller
class OnboardingFlowScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final bool isReview;

  const OnboardingFlowScreen({
    super.key,
    this.onComplete,
    this.onSkip,
    this.isReview = false,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  final OnboardingData _data = OnboardingData();
  int _currentStep = 0;
  final int _totalSteps =
      7; // Welcome + BodyInfo(+gender) + Activity + Goal + BodyGoals + Motivation + Weekly

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding data to backend via AuthProvider
    final authProvider = context.read<AuthProvider>();

    // Combine body goals into a string for body_goals field
    final bodyGoalsString =
        _data.bodyGoals.isNotEmpty ? _data.bodyGoals.join(', ') : null;

    // Migrate old activity level values to new format
    String? activityLevel = _data.activityLevel;
    const activityLevelMap = {
      'light': 'lightly_active',
      'moderate': 'moderately_active',
      'active': 'very_active',
    };
    if (activityLevel != null && activityLevelMap.containsKey(activityLevel)) {
      activityLevel = activityLevelMap[activityLevel];
    }

    // Debug: Log the data being sent
    debugPrint('=== ONBOARDING DATA ===');
    debugPrint('isReview: ${widget.isReview}');
    debugPrint('Gender: ${_data.gender}');
    debugPrint('Date of Birth: ${_data.dateOfBirth}');
    debugPrint('Height: ${_data.height}');
    debugPrint('Weight: ${_data.weight}');
    debugPrint(
      'Activity Level: $activityLevel (original: ${_data.activityLevel})',
    );
    debugPrint('Fitness Goal: ${_data.fitnessGoal}');
    debugPrint('Body Goals: $bodyGoalsString');
    debugPrint('========================');

    final success = await authProvider.completeOnboarding(
      gender: _data.gender,
      dateOfBirth: _data.dateOfBirth,
      height: _data.height,
      weight: _data.weight,
      activityLevel: activityLevel,
      goal: _data.fitnessGoal,
      bodyGoals: bodyGoalsString,
    );

    debugPrint('Onboarding save result: $success');
    if (!success) {
      debugPrint('Error: ${authProvider.errorMessage}');
    }

    if (success && mounted) {
      // If in review mode, just go back
      if (widget.isReview) {
        Navigator.of(context).pop();
      } else {
        widget.onComplete?.call();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Lưu thông tin thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _skipOnboarding() async {
    // If in review mode, just go back
    if (widget.isReview) {
      Navigator.of(context).pop();
      return;
    }

    // Mark onboarding as completed with null data
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.completeOnboarding();

    if (success && mounted) {
      if (widget.onSkip != null) {
        widget.onSkip!();
      } else {
        widget.onComplete?.call();
      }
    } else if (mounted) {
      // If save failed, show error but still allow skip
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu, nhưng bạn có thể tiếp tục'),
          backgroundColor: Colors.orange,
        ),
      );
      // Still complete onboarding locally
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress and skip
            _buildHeader(context, isDark),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  WelcomeStep(onNext: _nextStep),
                  BodyInfoStep(
                    gender: _data.gender,
                    height: _data.height,
                    weight: _data.weight,
                    dateOfBirth: _data.dateOfBirth,
                    onGenderChanged: (v) => setState(() => _data.gender = v),
                    onHeightChanged: (v) => setState(() => _data.height = v),
                    onWeightChanged: (v) => setState(() => _data.weight = v),
                    onDateChanged: (v) => setState(() => _data.dateOfBirth = v),
                    onNext: _nextStep,
                  ),
                  ActivityLevelStep(
                    selectedLevel: _data.activityLevel,
                    onChanged: (v) => setState(() => _data.activityLevel = v),
                    onNext: _nextStep,
                  ),
                  FitnessGoalStep(
                    selectedGoal: _data.fitnessGoal,
                    onChanged: (v) => setState(() => _data.fitnessGoal = v),
                    onNext: _nextStep,
                  ),
                  BodyGoalsStep(
                    selectedGoals: _data.bodyGoals,
                    onChanged: (v) => setState(() => _data.bodyGoals = v),
                    onNext: _nextStep,
                  ),
                  MotivationStep(
                    selectedMotivations: _data.motivations,
                    onChanged: (v) => setState(() => _data.motivations = v),
                    onNext: _nextStep,
                  ),
                  WeeklyGoalStep(
                    daysPerWeek: _data.workoutDaysPerWeek,
                    startDay: _data.weekStartDay,
                    onDaysChanged:
                        (v) => setState(() => _data.workoutDaysPerWeek = v),
                    onStartDayChanged:
                        (v) => setState(() => _data.weekStartDay = v),
                    onComplete: _completeOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Welcome step: show simplified header with just skip
    if (_currentStep == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _skipOnboarding,
              child: Text(
                'Bỏ qua',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Other steps: Stitch-style header with progress bar + counter
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Top row: back button + title + skip
          Row(
            children: [
              GestureDetector(
                onTap: _previousStep,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'HealthCare247',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _skipOnboarding,
                child: Text(
                  'Bỏ qua',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar row — Stitch style
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tiến trình hoàn thiện hồ sơ',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : const Color(0xFF64748B),
                  ),
                ),
              ),
              Text(
                '$_currentStep/$_totalSteps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _currentStep / _totalSteps,
              minHeight: 6,
              backgroundColor:
                  isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
