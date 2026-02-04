import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/tracking_model.dart';

/// Weight Line Chart - Biểu đồ đường cho theo dõi cân nặng
class WeightLineChart extends StatelessWidget {
  final List<WeightTracking> data;
  final double? goalWeight;
  final Color lineColor;
  final String emptyText;

  const WeightLineChart({
    super.key,
    required this.data,
    this.goalWeight,
    this.lineColor = AppColors.primary,
    this.emptyText = 'No weight data',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: AppColors.textHint.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                emptyText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Prepare data points (reversed to show oldest to newest)
    final sortedData = List<WeightTracking>.from(data)
      ..sort((a, b) => a.trackedAt.compareTo(b.trackedAt));

    final spots =
        sortedData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.weight);
        }).toList();

    // Calculate min/max for Y axis
    final weights = sortedData.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    final padding = range > 0 ? range * 0.2 : 5.0;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: range > 0 ? range / 4 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border.withValues(alpha: 0.5),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedData.length) {
                    return const SizedBox.shrink();
                  }
                  // Show every nth label based on data count
                  final interval = (sortedData.length / 5).ceil();
                  if (index % interval != 0 && index != sortedData.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final date = sortedData[index].trackedAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSizes.xs),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppSizes.fontXs,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppSizes.fontXs,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minWeight - padding,
          maxY: maxWeight + padding,
          lineBarsData: [
            // Main weight line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: AppColors.card,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withValues(alpha: 0.1),
              ),
            ),
            // Goal weight line (if provided)
            if (goalWeight != null)
              LineChartBarData(
                spots: [
                  FlSpot(0, goalWeight!),
                  FlSpot(spots.length - 1, goalWeight!),
                ],
                isCurved: false,
                color: AppColors.success.withValues(alpha: 0.7),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                dashArray: [5, 5],
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.spotIndex;
                  if (index < 0 || index >= sortedData.length) {
                    return null;
                  }
                  final tracking = sortedData[index];
                  final date = tracking.trackedAt;
                  final hasNotes =
                      tracking.notes != null && tracking.notes!.isNotEmpty;
                  return LineTooltipItem(
                    '${tracking.weight.toStringAsFixed(1)} kg\n${date.day}/${date.month}/${date.year}${hasNotes ? '\n📝 ${tracking.notes}' : ''}',
                    const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontSm,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
}
