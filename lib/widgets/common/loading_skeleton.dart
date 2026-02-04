import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer Loading Skeleton Widget
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Card Loading Skeleton
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoadingSkeleton(width: 48, height: 48, borderRadius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton(width: 120, height: 16),
                    const SizedBox(height: 8),
                    LoadingSkeleton(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 12),
          const SizedBox(height: 8),
          LoadingSkeleton(width: 200, height: 12),
        ],
      ),
    );
  }
}

/// Activity Feed Loading Skeleton
class ActivityFeedSkeleton extends StatelessWidget {
  final int itemCount;

  const ActivityFeedSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CardSkeleton(),
        ),
      ),
    );
  }
}

/// Stats Card Loading Skeleton
class StatsCardSkeleton extends StatelessWidget {
  const StatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(width: 100, height: 20),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItemSkeleton(),
              _StatItemSkeleton(),
              _StatItemSkeleton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItemSkeleton extends StatelessWidget {
  const _StatItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LoadingSkeleton(width: 40, height: 40, borderRadius: 20),
        const SizedBox(height: 8),
        LoadingSkeleton(width: 50, height: 24),
        const SizedBox(height: 4),
        LoadingSkeleton(width: 30, height: 12),
      ],
    );
  }
}

/// Dashboard Loading Skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(width: 150, height: 28),
          const SizedBox(height: 20),
          StatsCardSkeleton(),
          const SizedBox(height: 32),
          LoadingSkeleton(width: 120, height: 20),
          const SizedBox(height: 16),
          ActivityFeedSkeleton(itemCount: 3),
        ],
      ),
    );
  }
}
