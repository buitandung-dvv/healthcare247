import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/language_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/tracking_model.dart';

/// Activity History Screen - Shows all workout history sorted by date
class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthProvider>();
    final dashboard = context.read<DashboardProvider>();
    await dashboard.loadDashboardData(auth.userId);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final activities = dashboard.recentActivities;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.getText(en: 'Activity History', vi: 'Lịch sử hoạt động'),
        ),
      ),
      body:
          dashboard.isLoading
              ? const Center(child: CircularProgressIndicator())
              : activities.isEmpty
              ? _buildEmptyState(lang)
              : RefreshIndicator(
                onRefresh: _loadHistory,
                child: _buildActivityList(activities, lang),
              ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textHint),
          const SizedBox(height: AppSizes.md),
          Text(
            lang.getText(en: 'No activity yet', vi: 'Chưa có hoạt động'),
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            lang.getText(
              en: 'Complete your first workout to see history here',
              vi: 'Hoàn thành buổi tập đầu tiên để xem lịch sử',
            ),
            style: TextStyle(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(
    List<ExerciseTracking> activities,
    LanguageProvider lang,
  ) {
    // Group activities by date
    final grouped = <String, List<ExerciseTracking>>{};
    for (final activity in activities) {
      final dateKey = DateFormat('yyyy-MM-dd').format(activity.trackedAt);
      grouped.putIfAbsent(dateKey, () => []).add(activity);
    }

    // Sort dates descending
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayActivities = grouped[dateKey]!;
        final date = DateTime.tryParse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    _formatDateHeader(date, lang),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      '${dayActivities.length} ${lang.getText(en: 'exercises', vi: 'bài tập')}',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            // Activities for this date
            ...dayActivities.map(
              (activity) => _buildActivityCard(activity, lang),
            ),
            if (index < sortedDates.length - 1)
              const Divider(height: AppSizes.lg),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(ExerciseTracking activity, LanguageProvider lang) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(Icons.fitness_center, color: AppColors.primary),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.exerciseName ??
                        lang.getText(en: 'Exercise', vi: 'Bài tập'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (activity.sets != null && activity.reps != null) ...[
                        Icon(Icons.repeat, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.sets} × ${activity.reps}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                      ],
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.duration ?? 0} ${lang.getText(en: 'min', vi: 'phút')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(activity.caloriesBurned ?? 0).round()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'cal',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime? date, LanguageProvider lang) {
    if (date == null) return lang.getText(en: 'Unknown', vi: 'Không xác định');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return lang.getText(en: 'Today', vi: 'Hôm nay');
    } else if (targetDate == yesterday) {
      return lang.getText(en: 'Yesterday', vi: 'Hôm qua');
    } else {
      return DateFormat(
        'EEEE, dd/MM/yyyy',
        lang.currentLanguage == 'vi' ? 'vi' : 'en',
      ).format(date);
    }
  }
}
