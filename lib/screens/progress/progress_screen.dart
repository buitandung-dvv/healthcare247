import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/language_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/achievement_model.dart';
import '../../widgets/common/common_widgets.dart';
import '../../widgets/charts/chart_widgets.dart';
import '../../widgets/charts/weight_line_chart.dart';

/// Progress Screen - Theo dõi tiến độ
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Delay data loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();

    if (authProvider.currentUser != null) {
      await progressProvider.loadProgressData(authProvider.currentUser!.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: CustomAppBar(
        title: lang.getText(en: 'Your Progress', vi: 'Tiến độ của bạn'),
      ),
      body: Consumer<ProgressProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSizes.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsOverview(context, lang, provider),
                  const SizedBox(height: AppSizes.lg),
                  _buildWeightSection(context, lang, provider),
                  const SizedBox(height: AppSizes.lg),
                  _buildMacroSection(context, lang, provider),
                  const SizedBox(height: AppSizes.lg),
                  _buildWeeklyCaloriesSection(context, lang, provider),
                  const SizedBox(height: AppSizes.lg),
                  _buildAchievements(context, lang, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogWeightDialog(
    BuildContext context,
    LanguageProvider lang,
    ProgressProvider provider,
  ) {
    final TextEditingController weightController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.getText(en: 'Log Weight', vi: 'Ghi cân nặng'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: lang.getText(
                      en: 'Weight (kg)',
                      vi: 'Cân nặng (kg)',
                    ),
                    suffixText: 'kg',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: lang.getText(
                      en: 'Notes (optional)',
                      vi: 'Ghi chú (tùy chọn)',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final weightText = weightController.text.trim();
                      if (weightText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.getText(
                                en: 'Please enter weight',
                                vi: 'Vui lòng nhập cân nặng',
                              ),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final weight = double.tryParse(weightText);
                      if (weight == null || weight <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.getText(
                                en: 'Please enter a valid weight',
                                vi: 'Vui lòng nhập cân nặng hợp lệ',
                              ),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      final authProvider = context.read<AuthProvider>();
                      if (authProvider.currentUser == null) return;

                      final success = await provider.logWeight(
                        userId: authProvider.currentUser!.userId,
                        weight: weight,
                        notes:
                            notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                      );

                      // Refresh user profile to get updated weight
                      if (success) {
                        await authProvider.refreshUser();
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? lang.getText(
                                    en: 'Weight logged: $weight kg',
                                    vi: 'Đã ghi cân nặng: $weight kg',
                                  )
                                  : lang.getText(
                                    en: 'Failed to log weight',
                                    vi: 'Không thể ghi cân nặng',
                                  ),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(lang.getText(en: 'Save', vi: 'Lưu')),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showAllAchievements(
    BuildContext context,
    LanguageProvider lang,
    ProgressProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              lang.getText(en: 'All Achievements', vi: 'Tất cả thành tựu'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    provider.achievements.map((achievement) {
                      return _AchievementListItem(
                        icon: achievement.icon,
                        title:
                            lang.isVietnamese
                                ? achievement.titleVi
                                : achievement.titleEn,
                        subtitle:
                            lang.isVietnamese
                                ? achievement.descriptionVi
                                : achievement.descriptionEn,
                        isUnlocked: achievement.isUnlocked,
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(lang.getText(en: 'Close', vi: 'Đóng')),
              ),
            ],
          ),
    );
  }

  Widget _buildStatsOverview(
    BuildContext context,
    LanguageProvider lang,
    ProgressProvider provider,
  ) {
    // Use real data or show 0 if no data
    final workouts = provider.totalWorkoutsCompleted.toString();
    final streak = provider.currentStreak.toString();

    // Calculate average calories from weekly progress
    double avgCalories = 0;
    if (provider.weeklyProgress.isNotEmpty) {
      final totalCalories = provider.weeklyProgress.fold<double>(
        0,
        (sum, p) => sum + p.caloriesConsumed,
      );
      avgCalories = totalCalories / provider.weeklyProgress.length;
    }

    // Calculate weight change
    final weightChange = provider.weightChange;
    final weightChangeStr =
        weightChange == 0
            ? '0'
            : (weightChange > 0
                ? '-${weightChange.abs().toStringAsFixed(1)}'
                : '+${weightChange.abs().toStringAsFixed(1)}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.getText(en: 'Overview', vi: 'Tổng quan'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  title: lang.getText(en: 'Workouts', vi: 'Bài tập'),
                  value: workouts,
                  icon: Icons.fitness_center,
                  color: AppColors.primary,
                  subtitle: lang.getText(en: 'Total', vi: 'Tổng cộng'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: lang.getText(en: 'Streak', vi: 'Chuỗi ngày'),
                  value: streak,
                  icon: Icons.local_fire_department,
                  color: AppColors.secondary,
                  subtitle: lang.getText(en: 'Days', vi: 'Ngày'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  title: lang.getText(
                    en: 'Avg Calories',
                    vi: 'Calories Trung bình',
                  ),
                  value: avgCalories > 0 ? avgCalories.toStringAsFixed(0) : '-',
                  icon: Icons.restaurant,
                  color: AppColors.caloriesColor,
                  subtitle: lang.getText(en: 'Per day', vi: 'Mỗi ngày'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: StatCard(
                  title: lang.getText(
                    en: 'Weight Change',
                    vi: 'Thay đổi cân nặng',
                  ),
                  value: provider.hasWeightData ? '${weightChangeStr}kg' : '-',
                  icon: Icons.monitor_weight,
                  color: AppColors.info,
                  subtitle: lang.getText(en: 'Total', vi: 'Tổng'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection(
    BuildContext context,
    LanguageProvider lang,
    ProgressProvider provider,
  ) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.getText(en: 'Weight Progress', vi: 'Tiến độ cân nặng'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () => _showLogWeightDialog(context, lang, provider),
                icon: const Icon(Icons.add, size: 18),
                label: Text(lang.getText(en: 'Log', vi: 'Ghi')),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: 200,
            child: WeightLineChart(
              data: provider.weightHistory,
              emptyText: lang.getText(
                en: 'No weight data yet.\nTap "Log" to record your weight.',
                vi: 'Chưa có dữ liệu cân nặng.\nNhấn "Ghi" để ghi lại cân nặng.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSection(
    BuildContext context,
    LanguageProvider lang,
    ProgressProvider provider,
  ) {
    // Use real macro data from today's progress
    final protein = provider.todayProgress?.protein ?? 0;
    final carbs = provider.todayProgress?.carbs ?? 0;
    final fat = provider.todayProgress?.fat ?? 0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText(en: 'Macro Distribution', vi: 'Phân bổ Macro'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.md),
          MacroPieChart(
            protein: protein,
            carbs: carbs,
            fat: fat,
            emptyText: lang.getText(
              en: 'No meals logged today',
              vi: 'Chưa ghi bữa ăn hôm nay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCaloriesSection(
    BuildContext context,
    LanguageProvider lang,
    ProgressProvider provider,
  ) {
    final labels =
        lang.isVietnamese
            ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
            : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Map weekly progress to data array
    List<double> data;
    if (provider.weeklyProgress.isEmpty) {
      // No data - all zeros
      data = List.filled(7, 0);
    } else {
      // Map to 7 days starting from Monday
      data = List.filled(7, 0);
      for (final progress in provider.weeklyProgress) {
        final dayIndex = progress.date.weekday - 1; // Monday = 0
        if (dayIndex >= 0 && dayIndex < 7) {
          data[dayIndex] = progress.caloriesBurned;
        }
      }
    }

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText(en: 'Weekly Calories Burned', vi: 'Calories đốt tuần'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.md),
          WeeklyBarChart(
            data: data,
            labels: labels,
            barColor: AppColors.primary,
            maxY:
                data.every((d) => d == 0)
                    ? 100
                    : data.reduce((a, b) => a > b ? a : b) * 1.2,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(
    BuildContext context,
    LanguageProvider lang,
    ProgressProvider provider,
  ) {
    final achievements =
        provider.achievements.isEmpty
            ? Achievement.defaultAchievements(
              AppColors.primary,
              AppColors.secondary,
              AppColors.caloriesColor,
              AppColors.info,
            )
            : provider.achievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: lang.getText(en: 'Achievements', vi: 'Thành tựu'),
          actionText: lang.getText(en: 'See All', vi: 'Xem tất cả'),
          onActionTap: () => _showAllAchievements(context, lang, provider),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                achievements.take(4).map((achievement) {
                  return _AchievementBadge(
                    icon: achievement.icon,
                    title:
                        lang.isVietnamese
                            ? achievement.titleVi
                            : achievement.titleEn,
                    color: achievement.color,
                    isUnlocked: achievement.isUnlocked,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.icon,
    required this.title,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: AppSizes.md),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color:
                  isUnlocked
                      ? color.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkCard : AppColors.background),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isUnlocked
                        ? color
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : AppColors.textHint,
              size: AppSizes.iconLg,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isUnlocked ? null : AppColors.textHint,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _AchievementListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isUnlocked;

  const _AchievementListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isUnlocked
                ? AppColors.primary.withValues(alpha: 0.2)
                : (isDark ? AppColors.darkCard : AppColors.background),
        child: Icon(
          icon,
          color: isUnlocked ? AppColors.primary : AppColors.textHint,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isUnlocked ? null : AppColors.textHint,
          fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing:
          isUnlocked
              ? const Icon(Icons.check_circle, color: AppColors.success)
              : const Icon(Icons.lock_outline, color: AppColors.textHint),
    );
  }
}
