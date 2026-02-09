import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/greeting_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_plan_provider.dart';
import '../../providers/water_tracking_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/loading_skeleton.dart';
import '../../widgets/common/app_animations.dart';
import '../../widgets/greeting/greeting_icon_widget.dart';
import '../../widgets/charts/chart_widgets.dart';
import '../../widgets/cards/activity_feed_card.dart';
import '../../widgets/progress/animated_progress_ring.dart';
import '../../widgets/water/water_tracking_widget.dart';
import '../main/main_navigation_screen.dart';
import '../workout/start_workout_screen.dart';
import '../workout/workout_plans_screen.dart';
import '../activity/activity_history_screen.dart';
import '../meals/my_meals_screen.dart';
import '../meals/add_meal_screen.dart';
import '../foods/food_list_screen.dart';

/// Dashboard Screen - Trang chủ với tổng quan tiến độ
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling notifyListeners during build
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
    final languageProvider = context.read<LanguageProvider>();

    // Load dashboard data, workout plans, and water intake in parallel
    await Future.wait([
      dashboardProvider.loadDashboardData(authProvider.userId),
      workoutPlanProvider.loadUserPlans(
        languageId: languageProvider.languageId,
      ),
      waterTrackingProvider.loadTodayWaterIntake(authProvider.userId),
    ]);
  }

  void _showNotifications(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.notifications, color: AppColors.primary),
                const SizedBox(width: AppSizes.sm),
                Text(lang.getText(en: 'Notifications', vi: 'Thông báo')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NotificationItem(
                  icon: Icons.fitness_center,
                  title: lang.getText(
                    en: 'Workout reminder',
                    vi: 'Nhắc nhở tập luyện',
                  ),
                  subtitle: lang.getText(
                    en: 'Time for your daily workout!',
                    vi: 'Đến giờ tập luyện hàng ngày!',
                  ),
                  time: lang.getText(en: '1h ago', vi: '1 giờ trước'),
                ),
                const Divider(),
                _NotificationItem(
                  icon: Icons.restaurant,
                  title: lang.getText(en: 'Meal time', vi: 'Giờ ăn'),
                  subtitle: lang.getText(
                    en: 'Don\'t forget to log your lunch',
                    vi: 'Đừng quên ghi lại bữa trưa',
                  ),
                  time: lang.getText(en: '3h ago', vi: '3 giờ trước'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.getText(en: 'Close', vi: 'Đóng')),
              ),
            ],
          ),
    );
  }

  void _showLogMealSheet(BuildContext context, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary,
                                AppColors.secondary.withAlpha(180),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.getText(en: 'Log Meal', vi: 'Ghi bữa ăn'),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              lang.getText(
                                en: 'Select meal type',
                                vi: 'Chọn loại bữa ăn',
                              ),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Meal type grid - 2x2
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _MealTypeChip(
                          icon: Icons.wb_sunny_outlined,
                          label: lang.getText(en: 'Breakfast', vi: 'Bữa sáng'),
                          color: const Color(0xFFFF9500), // Orange
                          onTap: () => _logMealType(context, lang, 'breakfast'),
                        ),
                        _MealTypeChip(
                          icon: Icons.wb_cloudy_outlined,
                          label: lang.getText(en: 'Lunch', vi: 'Bữa trưa'),
                          color: const Color(0xFF34C759), // Green
                          onTap: () => _logMealType(context, lang, 'lunch'),
                        ),
                        _MealTypeChip(
                          icon: Icons.nights_stay_outlined,
                          label: lang.getText(en: 'Dinner', vi: 'Bữa tối'),
                          color: const Color(0xFF5856D6), // Purple
                          onTap: () => _logMealType(context, lang, 'dinner'),
                        ),
                        _MealTypeChip(
                          icon: Icons.cookie_outlined,
                          label: lang.getText(en: 'Snack', vi: 'Ăn vặt'),
                          color: const Color(0xFFFF2D55), // Pink
                          onTap: () => _logMealType(context, lang, 'snack'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bottom buttons
                    Row(
                      children: [
                        Expanded(
                          child: _BottomActionButton(
                            icon: Icons.history_rounded,
                            label: lang.getText(
                              en: 'My Meals',
                              vi: 'Bữa ăn của tôi',
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyMealsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BottomActionButton(
                            icon: Icons.search_rounded,
                            label: lang.getText(
                              en: 'Search Food',
                              vi: 'Tìm món ăn',
                            ),
                            isPrimary: true,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FoodListScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _logMealType(
    BuildContext context,
    LanguageProvider lang,
    String mealType,
  ) async {
    // Read providers BEFORE async gap
    final auth = context.read<AuthProvider>();
    final dashboard = context.read<DashboardProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    navigator.pop(); // Close modal sheet

    // Navigate to AddMealScreen and wait for result
    final result = await navigator.push<MealEntry>(
      MaterialPageRoute(
        builder:
            (context) =>
                AddMealScreen(mealType: mealType, date: DateTime.now()),
      ),
    );

    // If user selected a food, save to backend
    if (result != null && mounted) {
      await dashboard.logMeal(
        userId: auth.userId,
        mealType: mealType,
        mealName: result.name,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        quantity: result.quantity,
      );

      // Show success message
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              lang.getText(
                en: 'Added ${result.name} (${result.calories.toInt()} kcal)',
                vi: 'Đã thêm ${result.name} (${result.calories.toInt()} kcal)',
              ),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _navigateToExercises(BuildContext context) {
    // Navigate to Exercises tab (index 1)
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    nav?.switchToTab(1);
  }

  void _navigateToProgress(BuildContext context) {
    // Navigate to Progress tab (index 3)
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    nav?.switchToTab(3);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final progress = dashboard.todayProgress;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child:
            dashboard.isLoading
                ? const DashboardSkeleton()
                : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSizes.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, lang),
                        const SizedBox(height: AppSizes.lg),
                        RepaintBoundary(
                          child: _buildOverviewCard(context, lang, progress),
                        ),
                        const SizedBox(height: AppSizes.md),
                        RepaintBoundary(
                          child: _buildMacroSection(context, lang, progress),
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Water Tracking Widget
                        const RepaintBoundary(child: WaterTrackingWidget()),
                        const SizedBox(height: AppSizes.md),
                        RepaintBoundary(
                          child: _buildQuickActions(context, lang),
                        ),
                        const SizedBox(height: AppSizes.md),
                        RepaintBoundary(
                          child: _buildWeeklyChart(context, lang, dashboard),
                        ),
                        const SizedBox(height: AppSizes.md),
                        RepaintBoundary(child: _buildMyPlans(context, lang)),
                        const SizedBox(height: AppSizes.md),
                        RepaintBoundary(
                          child: _buildRecentActivity(context, lang),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider lang) {
    final auth = context.watch<AuthProvider>();
    final isVietnamese = lang.currentLanguage == 'vi';

    return SlideIn.fromLeft(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GreetingHelper.getGreeting(isVietnamese: isVietnamese),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      auth.currentUser?.displayName ?? 'User',
                      style: Theme.of(context).textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  // Time of day icon with dynamic styling
                  const GreetingIconWidget(size: 24),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => lang.toggleLanguage(),
                icon: Text(
                  lang.currentLanguage.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showNotifications(context, lang),
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    LanguageProvider lang,
    progress,
  ) {
    return Container(
      padding: AppSizes.paddingMd,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText(en: "Today's Overview", vi: 'Tổng quan hôm nay'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textWhite),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _OverviewItem(
                icon: Icons.local_fire_department,
                value: '${progress.caloriesConsumed.toInt()}',
                label: lang.getText(en: 'Calories', vi: 'Calories'),
                subtitle: '/ ${progress.caloriesGoal.toInt()}',
              ),
              _OverviewItem(
                icon: Icons.fitness_center,
                value: '${progress.workoutsCompleted}',
                label: lang.getText(en: 'Workouts', vi: 'Bài tập'),
                subtitle: '/ ${progress.workoutsPlanned}',
              ),
              _OverviewItem(
                icon: Icons.restaurant,
                value: '${progress.mealsLogged}',
                label: lang.getText(en: 'Meals', vi: 'Bữa ăn'),
                subtitle: lang.getText(en: 'logged', vi: 'đã log'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSection(
    BuildContext context,
    LanguageProvider lang,
    progress,
  ) {
    return SlideIn.fromBottom(
      delay: const Duration(milliseconds: 100),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText(en: 'Macros Progress', vi: 'Tiến độ dinh dưỡng'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MacroProgressRing(
                  label: lang.getText(en: 'Protein', vi: 'Chất đạm'),
                  current: progress.protein,
                  goal: progress.proteinGoal.toDouble(),
                  color: AppColors.proteinColor,
                ),
                MacroProgressRing(
                  label: lang.getText(en: 'Carbs', vi: 'Tinh bột'),
                  current: progress.carbs,
                  goal: progress.carbsGoal.toDouble(),
                  color: AppColors.carbsColor,
                ),
                MacroProgressRing(
                  label: lang.getText(en: 'Fat', vi: 'Chất béo'),
                  current: progress.fat,
                  goal: progress.fatGoal.toDouble(),
                  color: AppColors.fatColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.getText(en: 'Quick Actions', vi: 'Hành động nhanh'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.restaurant_menu,
                title: lang.getText(en: 'Log Meal', vi: 'Ghi bữa ăn'),
                color: AppColors.secondary,
                onTap: () => _showLogMealSheet(context, lang),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.fitness_center,
                title: lang.getText(en: 'Log Workout', vi: 'Ghi bài tập'),
                color: AppColors.primary,
                onTap: () => _navigateToExercises(context),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.calendar_today,
                title: lang.getText(en: 'View Plan', vi: 'Xem kế hoạch'),
                color: AppColors.info,
                onTap: () => _navigateToProgress(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    BuildContext context,
    LanguageProvider lang,
    DashboardProvider dashboard,
  ) {
    final weeklyData = dashboard.weeklyProgress;
    final caloriesData = weeklyData.map((p) => p.caloriesBurned).toList();

    final labels =
        lang.isVietnamese
            ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
            : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Hiển thị empty state nếu không có dữ liệu
    if (caloriesData.isEmpty || caloriesData.every((c) => c == 0)) {
      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText(
                en: 'Weekly Calories Burned',
                vi: 'Calories tiêu thụ tuần này',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSizes.lg),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    lang.getText(
                      en: 'No workout data this week',
                      vi: 'Chưa có dữ liệu tập luyện tuần này',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    lang.getText(
                      en: 'Start exercising to see your progress!',
                      vi: 'Bắt đầu tập luyện để xem tiến độ!',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      );
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText(
              en: 'Weekly Calories Burned',
              vi: 'Calories tiêu thụ tuần này',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.md),
          WeeklyBarChart(
            data: caloriesData,
            labels: labels,
            barColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMyPlans(BuildContext context, LanguageProvider lang) {
    final planProvider = context.watch<WorkoutPlanProvider>();
    final plans = planProvider.userPlans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: lang.getText(
            en: 'My Workout Plans',
            vi: 'Kế hoạch tập của tôi',
          ),
          actionText: lang.getText(en: 'See All', vi: 'Xem tất cả'),
          onActionTap: () {
            // Navigate to Workout Plans screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutPlansScreen(),
              ),
            );
          },
        ),
        if (plans.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.fitness_center, size: 48, color: AppColors.textHint),
                const SizedBox(height: AppSizes.sm),
                Text(
                  lang.getText(en: 'No plans yet', vi: 'Chưa có kế hoạch'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.sm),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutPlansScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    lang.getText(en: 'Create Plan', vi: 'Tạo kế hoạch'),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: plans.length > 5 ? 5 : plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Container(
                  width: 180,
                  margin: EdgeInsets.only(
                    right: index < plans.length - 1 ? AppSizes.sm : 0,
                  ),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        // Navigate to workout plans screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WorkoutPlansScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: AppColors.primary,
                            ),
                            const Spacer(),
                            Text(
                              plan.name ?? plan.planType ?? 'Workout Plan',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.details.length} ${lang.getText(en: 'exercises', vi: 'bài tập')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, LanguageProvider lang) {
    final dashboard = context.watch<DashboardProvider>();
    final hasActivity =
        dashboard.hasData && dashboard.todayProgress.workoutsCompleted > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Start Workout Card
        QuickStartWorkoutCard(
          onStartWorkout: () {
            // Navigate to exercise selection screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StartWorkoutScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.lg),

        // Section Header
        SectionHeader(
          title: lang.getText(en: 'Recent Activity', vi: 'Hoạt động gần đây'),
          actionText: lang.getText(en: 'See All', vi: 'Xem tất cả'),
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityHistoryScreen(),
              ),
            );
          },
        ),

        // Activity Feed - Show real history or empty state
        if (dashboard.recentActivities.isNotEmpty) ...[
          // Show real activity history from API
          ...dashboard.recentActivities.take(5).map((activity) {
            return ActivityFeedCard(
              title:
                  activity.exerciseName ??
                  lang.getText(en: 'Workout', vi: 'Buổi tập'),
              subtitle: lang.getText(
                en: '${activity.sets ?? 0} sets • ${activity.reps ?? 0} reps',
                vi: '${activity.sets ?? 0} set • ${activity.reps ?? 0} lần',
              ),
              duration: '${activity.duration ?? 0} min',
              calories: '${(activity.caloriesBurned ?? 0).round()} cal',
              timeAgo: _formatTimeAgo(activity.trackedAt, lang),
              icon: Icons.fitness_center,
            );
          }),
        ] else if (hasActivity) ...[
          // Fallback to today's summary if no detailed history
          ActivityFeedCard(
            title: lang.getText(en: 'Workout Session', vi: 'Buổi tập luyện'),
            subtitle: lang.getText(
              en:
                  '${dashboard.todayProgress.workoutsCompleted} exercises completed',
              vi:
                  '${dashboard.todayProgress.workoutsCompleted} bài tập hoàn thành',
            ),
            duration:
                '${(dashboard.todayProgress.caloriesBurned / 10).round()} min',
            calories: '${dashboard.todayProgress.caloriesBurned.round()} cal',
            timeAgo: lang.getText(en: 'Today', vi: 'Hôm nay'),
            icon: Icons.fitness_center,
          ),
          if (dashboard.todayProgress.mealsLogged > 0)
            ActivityFeedCard(
              title: lang.getText(en: 'Meals Logged', vi: 'Bữa ăn đã ghi'),
              subtitle: lang.getText(
                en: '${dashboard.todayProgress.mealsLogged} meals today',
                vi: '${dashboard.todayProgress.mealsLogged} bữa hôm nay',
              ),
              duration:
                  '${dashboard.todayProgress.caloriesConsumed.round()} cal',
              calories: '',
              timeAgo: lang.getText(en: 'Today', vi: 'Hôm nay'),
              icon: Icons.restaurant,
              iconColor: AppColors.secondary,
            ),
        ] else
          EmptyActivityState(
            title: lang.getText(en: 'No activity yet', vi: 'Chưa có hoạt động'),
            subtitle: lang.getText(
              en: 'Start your first workout to track your progress',
              vi: 'Bắt đầu buổi tập đầu tiên để theo dõi tiến độ',
            ),
            buttonText: lang.getText(en: 'Start Workout', vi: 'Bắt đầu tập'),
            onButtonTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StartWorkoutScreen(),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime? date, LanguageProvider lang) {
    if (date == null) return lang.getText(en: 'Recently', vi: 'Gần đây');

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return lang.getText(
        en: '${diff.inMinutes}m ago',
        vi: '${diff.inMinutes} phút trước',
      );
    } else if (diff.inHours < 24) {
      return lang.getText(
        en: '${diff.inHours}h ago',
        vi: '${diff.inHours} giờ trước',
      );
    } else if (diff.inDays == 1) {
      return lang.getText(en: 'Yesterday', vi: 'Hôm qua');
    } else if (diff.inDays < 7) {
      return lang.getText(
        en: '${diff.inDays} days ago',
        vi: '${diff.inDays} ngày trước',
      );
    } else {
      return lang.getText(en: 'Last week', vi: 'Tuần trước');
    }
  }
}

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String subtitle;

  const _OverviewItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textWhite, size: AppSizes.iconLg),
        const SizedBox(height: AppSizes.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textWhite.withValues(alpha: 0.8),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textWhite.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.iconMd),
            const SizedBox(height: AppSizes.sm),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _MealTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MealTypeChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withAlpha(40),
        highlightColor: color.withAlpha(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(60), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color.withAlpha(150), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.primary : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
