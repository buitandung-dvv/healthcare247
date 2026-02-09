import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/common/weekly_calendar_strip.dart';
import '../../widgets/greeting/greeting_icon_widget.dart';
import '../../widgets/cards/gradient_banner_card.dart';
import '../../widgets/charts/chart_widgets.dart';
import '../main/main_navigation_screen.dart';
import 'date_details_screen.dart';

/// Home Screen - Dashboard chính
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData(
        1,
      ); // userId = 1 for now
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final progress = dashboardProvider.todayProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : null,
      body: SafeArea(
        child:
            dashboardProvider.isLoading
                ? const LoadingWidget()
                : RefreshIndicator(
                  onRefresh: () async {
                    await dashboardProvider.loadDashboardData(1);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSizes.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(context, langProvider),
                        const SizedBox(height: AppSizes.md),
                        // Weekly Calendar Strip
                        WeeklyCalendarStrip(
                          selectedDate: DateTime.now(),
                          streakDays: dashboardProvider.currentStreak,
                          onDateSelected: (date) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        DateDetailsScreen(selectedDate: date),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.lg),
                        // Today's Overview Card
                        _buildOverviewCard(context, langProvider, progress),
                        const SizedBox(height: AppSizes.md),
                        // Challenge Banner
                        GradientBannerCard(
                          title: langProvider.getText(
                            en: "7-Day Fitness Challenge",
                            vi: "Thử thách 7 ngày",
                          ),
                          subtitle: langProvider.getText(
                            en: "Complete daily workouts to earn rewards!",
                            vi: "Hoàn thành bài tập mỗi ngày để nhận thưởng!",
                          ),
                          buttonText: langProvider.getText(
                            en: "Join Now",
                            vi: "Tham gia",
                          ),
                          onButtonPressed: () => _navigateToExercises(context),
                          gradient: AppColors.heroGradient,
                          trailing: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          margin: EdgeInsets.zero,
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Macro Distribution
                        _buildMacroSection(context, langProvider, progress),
                        const SizedBox(height: AppSizes.md),
                        // Quick Actions
                        _buildQuickActions(context, langProvider),
                        const SizedBox(height: AppSizes.md),
                        // Weekly Progress
                        _buildWeeklyProgress(
                          context,
                          langProvider,
                          dashboardProvider.weeklyProgress,
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Today's Plan Summary
                        _buildTodaysPlan(context, langProvider),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider langProvider) {
    final greeting = _getGreeting(langProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                // Dynamic time of day icon
                const GreetingIconWidget(size: 18),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              langProvider.getText(
                en: "Today's Overview",
                vi: "Tổng quan hôm nay",
              ),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        // Language toggle
        IconButton(
          icon: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Text(
              langProvider.currentLanguage.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onPressed: () => langProvider.toggleLanguage(),
        ),
      ],
    );
  }

  String _getGreeting(LanguageProvider langProvider) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return langProvider.getText(en: "Good morning!", vi: "Chào buổi sáng!");
    } else if (hour < 17) {
      return langProvider.getText(
        en: "Good afternoon!",
        vi: "Chào buổi chiều!",
      );
    } else {
      return langProvider.getText(en: "Good evening!", vi: "Chào buổi tối!");
    }
  }

  void _showLogMealSheet(BuildContext context, LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langProvider.getText(en: 'Log Meal', vi: 'Ghi bữa ăn'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.free_breakfast,
                    color: Colors.orange,
                  ),
                  title: Text(
                    langProvider.getText(en: 'Breakfast', vi: 'Bữa sáng'),
                  ),
                  onTap: () => _logMeal(context, langProvider, 'Breakfast'),
                ),
                ListTile(
                  leading: const Icon(Icons.lunch_dining, color: Colors.green),
                  title: Text(
                    langProvider.getText(en: 'Lunch', vi: 'Bữa trưa'),
                  ),
                  onTap: () => _logMeal(context, langProvider, 'Lunch'),
                ),
                ListTile(
                  leading: const Icon(Icons.dinner_dining, color: Colors.blue),
                  title: Text(
                    langProvider.getText(en: 'Dinner', vi: 'Bữa tối'),
                  ),
                  onTap: () => _logMeal(context, langProvider, 'Dinner'),
                ),
                ListTile(
                  leading: const Icon(Icons.icecream, color: Colors.pink),
                  title: Text(langProvider.getText(en: 'Snack', vi: 'Ăn vặt')),
                  onTap: () => _logMeal(context, langProvider, 'Snack'),
                ),
              ],
            ),
          ),
    );
  }

  void _logMeal(
    BuildContext context,
    LanguageProvider langProvider,
    String mealType,
  ) {
    Navigator.pop(context);
    final dashboard = context.read<DashboardProvider>();
    dashboard.logMeal(
      userId: 1,
      mealType: mealType.toLowerCase(),
      calories: 350,
      protein: 20,
      carbs: 45,
      fat: 12,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          langProvider.getText(
            en: '$mealType logged successfully!',
            vi: 'Đã ghi $mealType thành công!',
          ),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _navigateToExercises(BuildContext context) {
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    nav?.switchToTab(1);
  }

  void _navigateToProgress(BuildContext context) {
    final nav = context.findAncestorStateOfType<MainNavigationScreenState>();
    nav?.switchToTab(3);
  }

  Widget _buildOverviewCard(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic progress,
  ) {
    return Container(
      padding: AppSizes.paddingMd,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCaloriesDisplay(context, langProvider, progress),
              _buildWorkoutDisplay(context, langProvider, progress),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesDisplay(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic progress,
  ) {
    return Column(
      children: [
        CircularProgressCard(
          title: '',
          current: progress.caloriesConsumed,
          goal: progress.caloriesGoal,
          unit: '',
          color: AppColors.textWhite,
          size: 100,
        ),
        Text(
          langProvider.getText(en: 'Calories', vi: 'Calories'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textWhite),
        ),
        Text(
          '${progress.netCalories.toInt()} ${langProvider.getText(en: "net", vi: "ròng")}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textWhite.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutDisplay(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic progress,
  ) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.textWhite.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${progress.workoutsCompleted}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/${progress.workoutsPlanned}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          langProvider.getText(en: 'Workouts', vi: 'Bài tập'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textWhite),
        ),
      ],
    );
  }

  Widget _buildMacroSection(
    BuildContext context,
    LanguageProvider langProvider,
    dynamic progress,
  ) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            langProvider.getText(
              en: 'Macro Distribution',
              vi: 'Phân bổ dinh dưỡng',
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.md),
          MacroPieChart(
            protein: progress.protein,
            carbs: progress.carbs,
            fat: progress.fat,
          ),
          const SizedBox(height: AppSizes.md),
          LinearProgressBar(
            label: langProvider.getText(en: 'Protein', vi: 'Chất đạm'),
            current: progress.protein,
            goal: progress.proteinGoal,
            unit: 'g',
            color: AppColors.proteinColor,
          ),
          const SizedBox(height: AppSizes.sm),
          LinearProgressBar(
            label: langProvider.getText(en: 'Carbs', vi: 'Tinh bột'),
            current: progress.carbs,
            goal: progress.carbsGoal,
            unit: 'g',
            color: AppColors.carbsColor,
          ),
          const SizedBox(height: AppSizes.sm),
          LinearProgressBar(
            label: langProvider.getText(en: 'Fat', vi: 'Chất béo'),
            current: progress.fat,
            goal: progress.fatGoal,
            unit: 'g',
            color: AppColors.fatColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    LanguageProvider langProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          langProvider.getText(en: 'Quick Actions', vi: 'Thao tác nhanh'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.restaurant_menu,
                label: langProvider.getText(en: 'Log Meal', vi: 'Ghi bữa ăn'),
                color: AppColors.secondary,
                onTap: () => _showLogMealSheet(context, langProvider),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.fitness_center,
                label: langProvider.getText(
                  en: 'Log Workout',
                  vi: 'Ghi tập luyện',
                ),
                color: AppColors.primary,
                onTap: () => _navigateToExercises(context),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.calendar_today,
                label: langProvider.getText(
                  en: 'View Plan',
                  vi: 'Xem kế hoạch',
                ),
                color: AppColors.info,
                onTap: () => _navigateToProgress(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyProgress(
    BuildContext context,
    LanguageProvider langProvider,
    List weeklyProgress,
  ) {
    final data =
        weeklyProgress.map((p) => p.caloriesConsumed as double).toList();
    final labels =
        langProvider.currentLanguage == 'vi'
            ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
            : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            langProvider.getText(en: 'Weekly Calories', vi: 'Calories tuần'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.md),
          WeeklyBarChart(
            data: data.isEmpty ? List.filled(7, 0.0) : data,
            labels: labels,
            barColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPlan(BuildContext context, LanguageProvider langProvider) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                langProvider.getText(
                  en: "Today's Plan",
                  vi: "Kế hoạch hôm nay",
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () => _navigateToProgress(context),
                child: Text(
                  langProvider.getText(en: 'See All', vi: 'Xem tất cả'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Placeholder for today's plan items
          _PlanItem(
            icon: Icons.wb_sunny,
            title: langProvider.getText(en: 'Breakfast', vi: 'Bữa sáng'),
            subtitle: langProvider.getText(
              en: 'Oatmeal & Fruits',
              vi: 'Yến mạch & Trái cây',
            ),
            isCompleted: true,
          ),
          _PlanItem(
            icon: Icons.fitness_center,
            title: langProvider.getText(en: 'Morning Workout', vi: 'Tập sáng'),
            subtitle: langProvider.getText(
              en: 'Upper body strength',
              vi: 'Tập sức mạnh thân trên',
            ),
            isCompleted: true,
          ),
          _PlanItem(
            icon: Icons.restaurant,
            title: langProvider.getText(en: 'Lunch', vi: 'Bữa trưa'),
            subtitle: langProvider.getText(
              en: 'Grilled chicken salad',
              vi: 'Salad gà nướng',
            ),
            isCompleted: false,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: AppSizes.paddingMd,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.iconLg),
            const SizedBox(height: AppSizes.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;

  const _PlanItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Container(
            padding: AppSizes.paddingSm,
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              icon,
              color: isCompleted ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color:
                        isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: AppColors.success)
          else
            const Icon(Icons.circle_outlined, color: AppColors.textHint),
        ],
      ),
    );
  }
}
