import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Circular Progress Card - Cho calories/macro tracking
class CircularProgressCard extends StatelessWidget {
  final String title;
  final double current;
  final double goal;
  final String unit;
  final Color color;
  final double size;

  const CircularProgressCard({
    super.key,
    required this.title,
    required this.current,
    required this.goal,
    this.unit = '',
    this.color = AppColors.primary,
    this.size = 80,
  });

  double get _progress => goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: 8,
      percent: _progress,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            current.toInt().toString(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '/${goal.toInt()}$unit',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      progressColor: color,
      backgroundColor: color.withValues(alpha: 0.2),
      circularStrokeCap: CircularStrokeCap.round,
      footer: Padding(
        padding: const EdgeInsets.only(top: AppSizes.sm),
        child: Text(title, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

/// Linear Progress Bar
class LinearProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;
  final bool showPercentage;

  const LinearProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    this.unit = '',
    this.color = AppColors.primary,
    this.showPercentage = true,
  });

  double get _progress => goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '${current.toInt()}/${goal.toInt()}$unit',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            FractionallySizedBox(
              widthFactor: _progress,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
          ],
        ),
        if (showPercentage) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            '${(_progress * 100).toInt()}%',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}

/// Weekly Bar Chart
class WeeklyBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color barColor;
  final double maxY;

  const WeeklyBarChart({
    super.key,
    required this.data,
    this.labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    this.barColor = AppColors.primary,
    this.maxY = 2500,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()}',
                  const TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSizes.sm),
                      child: Text(
                        labels[value.toInt()],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppSizes.fontSm,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups:
              data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      color: barColor,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSizes.radiusSm),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

/// Macro Distribution Pie Chart
class MacroPieChart extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final String? emptyText;

  const MacroPieChart({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.emptyText,
  });

  double get _total => protein + carbs + fat;

  @override
  Widget build(BuildContext context) {
    if (_total == 0) {
      return Center(child: Text(emptyText ?? 'No data'));
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: protein,
                    color: AppColors.proteinColor,
                    title: '${(protein / _total * 100).toInt()}%',
                    titleStyle: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 45,
                  ),
                  PieChartSectionData(
                    value: carbs,
                    color: AppColors.carbsColor,
                    title: '${(carbs / _total * 100).toInt()}%',
                    titleStyle: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 45,
                  ),
                  PieChartSectionData(
                    value: fat,
                    color: AppColors.fatColor,
                    title: '${(fat / _total * 100).toInt()}%',
                    titleStyle: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: 45,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendItem(
              color: AppColors.proteinColor,
              label: 'Protein',
              value: '${protein.toInt()}g',
            ),
            const SizedBox(height: AppSizes.sm),
            _LegendItem(
              color: AppColors.carbsColor,
              label: 'Carbs',
              value: '${carbs.toInt()}g',
            ),
            const SizedBox(height: AppSizes.sm),
            _LegendItem(
              color: AppColors.fatColor,
              label: 'Fat',
              value: '${fat.toInt()}g',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.sm),
        Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Stat Card
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: AppSizes.paddingMd,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.darkShadow : AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: AppSizes.paddingSm,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconLg),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
