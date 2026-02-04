import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/language_provider.dart';
import '../../providers/dashboard_provider.dart';

class DateDetailsScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DateDetailsScreen({super.key, required this.selectedDate});

  @override
  State<DateDetailsScreen> createState() => _DateDetailsScreenState();
}

class _DateDetailsScreenState extends State<DateDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final dateFormat = DateFormat(
      'EEEE, d MMMM yyyy',
      lang.isVietnamese ? 'vi' : 'en',
    );
    final isToday = DateUtils.isSameDay(widget.selectedDate, DateTime.now());

    // Get progress for selected date from weekly progress
    final progress = dashboard.weeklyProgress.firstWhere(
      (p) => DateUtils.isSameDay(p.date, widget.selectedDate),
      orElse: () => dashboard.todayProgress,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isToday
              ? lang.getText(en: 'Today', vi: 'Hôm nay')
              : dateFormat.format(widget.selectedDate),
        ),
      ),
      body:
          dashboard.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    if (!isToday)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: Text(
                          dateFormat.format(widget.selectedDate),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Stats cards
                    _buildStatsGrid(lang, progress),
                    const SizedBox(height: AppSizes.lg),

                    // Summary section
                    _buildSummarySection(lang, progress),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatsGrid(LanguageProvider lang, dynamic progress) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSizes.sm,
      crossAxisSpacing: AppSizes.sm,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.local_fire_department,
          value: '${progress.caloriesBurned.toInt()}',
          label: lang.getText(en: 'Calories Burned', vi: 'Calo đốt'),
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.fitness_center,
          value: '${progress.workoutsCompleted}',
          label: lang.getText(en: 'Workouts', vi: 'Bài tập'),
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.restaurant,
          value: '${progress.caloriesConsumed.toInt()}',
          label: lang.getText(en: 'Calories Eaten', vi: 'Calo nạp'),
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.egg_alt,
          value: '${progress.protein.toInt()}g',
          label: lang.getText(en: 'Protein', vi: 'Protein'),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(LanguageProvider lang, dynamic progress) {
    final isPositive = progress.caloriesBurned >= progress.caloriesConsumed;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.getText(en: 'Daily Summary', vi: 'Tổng kết ngày'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isPositive
                        ? lang.getText(
                          en: 'Great job! You burned more than you consumed.',
                          vi: 'Tuyệt vời! Bạn đốt nhiều hơn bạn nạp.',
                        )
                        : lang.getText(
                          en: 'Keep going! Try to burn more calories.',
                          vi: 'Cố lên! Hãy đốt thêm calo.',
                        ),
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
