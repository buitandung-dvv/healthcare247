import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/water_tracking_provider.dart';
import '../../providers/workout_plan_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../main/main_navigation_screen.dart';
import '../notifications/notifications_screen.dart';
import '../progress/water_tracking_screen.dart';
import '../recipes/recipe_detail_screen.dart';
import '../workout/workout_plans_screen.dart';
import '../meals/my_meals_screen.dart';
import 'date_details_screen.dart';

/// Home Screen - Stitch Redesign
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final workoutPlanProvider = context.read<WorkoutPlanProvider>();
    final waterTrackingProvider = context.read<WaterTrackingProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final languageProvider = context.read<LanguageProvider>();

    await Future.wait([
      dashboardProvider.loadDashboardData(authProvider.userId),
      workoutPlanProvider.loadUserPlans(
        languageId: languageProvider.languageId,
      ),
      waterTrackingProvider.loadTodayWaterIntake(authProvider.userId),
      recipeProvider.loadIfNeeded(languageId: languageProvider.languageId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final progress = dashboardProvider.todayProgress;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: dashboardProvider.isLoading
            ? const LoadingWidget()
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with avatar + greeting + notification
                      _buildHeader(context, langProvider),
                      const SizedBox(height: 20),
                      // Daily Summary Card — white with gradient top
                      _buildDailySummaryCard(context, langProvider, progress),
                      const SizedBox(height: 24),
                      // Quick Actions — 4 circular buttons
                      _buildQuickActions(context, langProvider),
                      const SizedBox(height: 24),
                      // Water Tracking inline card
                      _buildWaterCard(context, langProvider, progress),
                      const SizedBox(height: 16),
                      // Today's Workout — dark gradient card
                      _buildWorkoutCard(context, langProvider),
                      const SizedBox(height: 24),
                      // Health Tips — horizontal scroll
                      _buildTipsSection(context, langProvider),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // HEADER — Avatar + Greeting + Notification Bell
  // ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, LanguageProvider langProvider) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final userName = user?.displayName ?? 'User';
    final greeting = _getGreeting(langProvider, userName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () {
              final nav = context
                  .findAncestorStateOfType<MainNavigationScreenState>();
              nav?.switchToTab(4); // Profile tab
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Greeting text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  langProvider.getText(
                    en: "Let's start the day!",
                    vi: "Hãy bắt đầu ngày mới!",
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextHint
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.06,
                        ),
                        offset: const Offset(0, 1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                // Red dot
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // DAILY SUMMARY CARD — Circular progress + Macro bars
  // ────────────────────────────────────────────────
  Widget _buildDailySummaryCard(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic progress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caloriesConsumed = progress.caloriesConsumed as double;
    final caloriesGoal = progress.caloriesGoal as double;
    final calorieProgress = caloriesGoal > 0
        ? (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DateDetailsScreen(selectedDate: DateTime.now()),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                offset: const Offset(0, 2),
                blurRadius: 12,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Gradient top bar
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF42A5F5)],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Circular Calorie Progress
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: _CalorieRingPainter(
                          progress: calorieProgress,
                          primaryColor: AppColors.primary,
                          trackColor: isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade100,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${caloriesConsumed.toInt()}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '/ ${caloriesGoal.toInt()} kcal',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextHint
                                      : Colors.grey.shade400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Macro Bars
                    Expanded(
                      child: Column(
                        children: [
                          _MacroBar(
                            label: 'Protein',
                            current: progress.protein,
                            goal: progress.proteinGoal,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(height: 16),
                          _MacroBar(
                            label: 'Carbs',
                            current: progress.carbs,
                            goal: progress.carbsGoal,
                            color: const Color(0xFFF97316),
                          ),
                          const SizedBox(height: 16),
                          _MacroBar(
                            label: 'Fat',
                            current: progress.fat,
                            goal: progress.fatGoal,
                            color: const Color(0xFFFB7185),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // QUICK ACTIONS — 4 circular buttons
  // ────────────────────────────────────────────────
  Widget _buildQuickActions(
    BuildContext context,
    LanguageProvider langProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CircularAction(
            icon: Icons.fitness_center,
            label: langProvider.getText(en: 'Workout', vi: 'Tập luyện'),
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.1),
            onTap: () => _navigateToExercises(context),
          ),
          _CircularAction(
            icon: Icons.restaurant,
            label: langProvider.getText(en: 'Meals', vi: 'Bữa ăn'),
            color: const Color(0xFFEA580C),
            bgColor: const Color(0xFFFFF7ED),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyMealsScreen()),
            ),
          ),
          _CircularAction(
            icon: Icons.water_drop,
            label: langProvider.getText(en: 'Water', vi: 'Nước'),
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WaterTrackingScreen()),
              );
            },
          ),
          _CircularAction(
            icon: Icons.show_chart,
            label: langProvider.getText(en: 'Progress', vi: 'Tiến độ'),
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
            onTap: () => _navigateToProgress(context),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // WATER TRACKING CARD
  // ────────────────────────────────────────────────
  Widget _buildWaterCard(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic progress,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterProvider = context.watch<WaterTrackingProvider>();
    final dailyIntake = waterProvider.dailyIntake;
    final totalL = (dailyIntake.totalMl / 1000).toStringAsFixed(1);
    final goalL = (dailyIntake.goalMl / 1000).toStringAsFixed(1);
    final waterProgress = dailyIntake.goalMl > 0
        ? (dailyIntake.totalMl / dailyIntake.goalMl).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WaterTrackingScreen()),
          );
        },
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
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              // Water icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Label + progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langProvider.getText(
                        en: 'Water intake',
                        vi: 'Lượng nước',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: waterProgress,
                              backgroundColor: isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey.shade100,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF60A5FA),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalL / ${goalL}L',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextHint
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Add button - quick add 250ml
              GestureDetector(
                onTap: () async {
                  final authProvider = context.read<AuthProvider>();
                  final success = await waterProvider.addGlass(
                    authProvider.userId,
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          langProvider.getText(
                            en: '+250ml water added!',
                            vi: '+250ml nước đã thêm!',
                          ),
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 14),
                      SizedBox(width: 2),
                      Text(
                        '250ml',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // TODAY'S WORKOUT — Dark gradient card
  // ────────────────────────────────────────────────
  Widget _buildWorkoutCard(
    BuildContext context,
    LanguageProvider langProvider,
  ) {
    final workoutProvider = context.watch<WorkoutPlanProvider>();
    final plans = workoutProvider.userPlans;

    // Find today's plan by checking scheduleDays
    final today = DateTime.now().weekday; // 1=Mon, 7=Sun
    final todayPlan = plans.isEmpty
        ? null
        : plans.cast<dynamic>().firstWhere(
            (p) => p.hasScheduleOnDay(today),
            orElse: () => plans.first,
          );

    final planName =
        todayPlan?.name ??
        langProvider.getText(en: 'No plan today', vi: 'Chưa có kế hoạch');
    final exerciseCount = todayPlan?.details.length ?? 0;
    final estMinutes = exerciseCount * 8; // ~8 min per exercise

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _navigateToPlans(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0F172A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              // Background icon
              Positioned(
                top: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        langProvider.getText(
                          en: "TODAY'S WORKOUT",
                          vi: 'BUỔI TẬP HÔM NAY',
                        ),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title - from real plan data
                    Text(
                      planName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Metadata - from real plan data
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 14,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          langProvider.getText(
                            en: '$exerciseCount exercises',
                            vi: '$exerciseCount bài tập',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          langProvider.getText(
                            en: '$estMinutes min',
                            vi: '$estMinutes phút',
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Start button — white pill
                    GestureDetector(
                      onTap: () => _navigateToPlans(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Text(
                          langProvider.getText(en: 'Start', vi: 'Bắt đầu'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // TIPS SECTION — Horizontal scroll
  // ────────────────────────────────────────────────
  Widget _buildTipsSection(
    BuildContext context,
    LanguageProvider langProvider,
  ) {
    final recipeProvider = context.watch<RecipeProvider>();
    final workoutProvider = context.watch<WorkoutPlanProvider>();
    final recipes = recipeProvider.recipes;
    final plans = workoutProvider.userPlans;

    // Build suggestion cards from real data
    final List<Widget> suggestionCards = [];

    // Add recipe cards (up to 3)
    for (int i = 0; i < recipes.length && i < 3; i++) {
      final recipe = recipes[i];
      if (suggestionCards.isNotEmpty) {
        suggestionCards.add(const SizedBox(width: 16));
      }
      suggestionCards.add(
        _SuggestionCard(
          category: langProvider.getText(en: 'Nutrition', vi: 'Dinh dưỡng'),
          title: recipe.name,
          categoryColor: const Color(0xFF059669),
          imageUrl: recipe.thumbnailUrl ?? recipe.imageUrl,
          icon: Icons.restaurant_menu,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe),
              ),
            );
          },
        ),
      );
    }

    // Add workout plan cards (up to 2)
    for (int i = 0; i < plans.length && i < 2; i++) {
      final plan = plans[i];
      if (suggestionCards.isNotEmpty) {
        suggestionCards.add(const SizedBox(width: 16));
      }
      final exerciseCount = plan.details.length;
      suggestionCards.add(
        _SuggestionCard(
          category: langProvider.getText(en: 'Workout', vi: 'Tập luyện'),
          title: plan.name ?? 'Workout Plan',
          subtitle: langProvider.getText(
            en: '$exerciseCount exercises',
            vi: '$exerciseCount bài tập',
          ),
          categoryColor: AppColors.primary,
          icon: Icons.fitness_center,
          onTap: () => _navigateToPlans(context),
        ),
      );
    }

    // Fallback if no data yet
    if (suggestionCards.isEmpty) {
      suggestionCards.add(
        _SuggestionCard(
          category: langProvider.getText(en: 'Getting started', vi: 'Bắt đầu'),
          title: langProvider.getText(
            en: 'Start your health journey today!',
            vi: 'Hãy bắt đầu hành trình sức khỏe!',
          ),
          categoryColor: AppColors.primary,
          icon: Icons.favorite,
          onTap: () {},
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                langProvider.getText(en: 'For you', vi: 'Dành cho bạn'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to recipes tab
                  final navState = context
                      .findAncestorStateOfType<MainNavigationScreenState>();
                  navState?.switchToTab(2); // Switch to recipes/nutrition tab
                },
                child: Text(
                  langProvider.getText(en: 'See all', vi: 'Xem tất cả'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: suggestionCards,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────
  // HELPERS
  // ────────────────────────────────────────────────
  String _getGreeting(LanguageProvider langProvider, String userName) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return langProvider.getText(
        en: 'Good morning, $userName',
        vi: 'Chào buổi sáng, $userName',
      );
    } else if (hour < 17) {
      return langProvider.getText(
        en: 'Good afternoon, $userName',
        vi: 'Chào buổi chiều, $userName',
      );
    } else {
      return langProvider.getText(
        en: 'Good evening, $userName',
        vi: 'Chào buổi tối, $userName',
      );
    }
  }

  void _navigateToExercises(BuildContext context) {
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    nav?.switchToTab(1);
  }

  void _navigateToProgress(BuildContext context) {
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    nav?.switchToTab(3);
  }

  void _navigateToPlans(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutPlansScreen()),
    );
  }
}

// ──────────────────────────────────────────────────
// CUSTOM PAINTERS & WIDGETS
// ──────────────────────────────────────────────────

/// Circular calorie ring painter (like Stitch SVG)
class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;

  _CalorieRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Macro progress bar (Protein/Carbs/Fat)
class _MacroBar extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;

  const _MacroBar({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              '${current.toInt()}/${goal.toInt()}g',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextHint : Colors.grey.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: isDark
                ? AppColors.darkBorder
                : Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Circular quick action button
class _CircularAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _CircularAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tip card for horizontal scroll section
class _SuggestionCard extends StatelessWidget {
  final String category;
  final String title;
  final String? subtitle;
  final Color categoryColor;
  final String? imageUrl;
  final IconData icon;
  final VoidCallback? onTap;

  const _SuggestionCard({
    required this.category,
    required this.title,
    this.subtitle,
    required this.categoryColor,
    this.imageUrl,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — real image or icon fallback
            SizedBox(
              height: 120,
              width: double.infinity,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: categoryColor.withValues(alpha: 0.1),
                        child: Icon(icon, size: 40, color: categoryColor),
                      ),
                    )
                  : Container(
                      color: categoryColor.withValues(alpha: 0.1),
                      child: Icon(icon, size: 40, color: categoryColor),
                    ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextHint
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
