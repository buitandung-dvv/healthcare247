import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/auth_provider.dart';
import 'steps/welcome_step.dart';
import 'steps/gender_step.dart';
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
  final int _totalSteps = 8; // Added FitnessGoalStep

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
                  GenderStep(
                    selectedGender: _data.gender,
                    onChanged: (v) => setState(() => _data.gender = v),
                    onNext: _nextStep,
                  ),
                  BodyInfoStep(
                    height: _data.height,
                    weight: _data.weight,
                    dateOfBirth: _data.dateOfBirth,
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            )
          else
            const SizedBox(width: 48),
          // Progress indicator
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor:
                      isDark ? AppColors.darkBorder : AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
          ),
          // Skip button
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Bỏ qua',
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
