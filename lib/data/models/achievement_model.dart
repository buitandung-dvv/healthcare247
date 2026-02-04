import 'package:flutter/material.dart';

/// Achievement Model - Thành tựu của người dùng
class Achievement {
  final String id;
  final String titleEn;
  final String titleVi;
  final String descriptionEn;
  final String descriptionVi;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.titleEn,
    required this.titleVi,
    required this.descriptionEn,
    required this.descriptionVi,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? titleEn,
    String? titleVi,
    String? descriptionEn,
    String? descriptionVi,
    IconData? icon,
    Color? color,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      titleEn: titleEn ?? this.titleEn,
      titleVi: titleVi ?? this.titleVi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionVi: descriptionVi ?? this.descriptionVi,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// Các thành tựu mặc định
  static List<Achievement> defaultAchievements(
    Color primary,
    Color secondary,
    Color caloriesColor,
    Color info,
  ) => [
    Achievement(
      id: 'first_week',
      titleEn: 'First Week',
      titleVi: 'Tuần đầu',
      descriptionEn: 'Complete your first week using the app',
      descriptionVi: 'Hoàn thành tuần đầu tiên sử dụng app',
      icon: Icons.emoji_events,
      color: secondary,
    ),
    Achievement(
      id: '7_day_streak',
      titleEn: '7 Day Streak',
      titleVi: '7 ngày liên tiếp',
      descriptionEn: 'Maintain a 7-day activity streak',
      descriptionVi: 'Duy trì hoạt động 7 ngày liên tiếp',
      icon: Icons.local_fire_department,
      color: caloriesColor,
    ),
    Achievement(
      id: '10_workouts',
      titleEn: '10 Workouts',
      titleVi: '10 bài tập',
      descriptionEn: 'Complete 10 workout sessions',
      descriptionVi: 'Hoàn thành 10 buổi tập luyện',
      icon: Icons.fitness_center,
      color: primary,
    ),
    Achievement(
      id: '30_days',
      titleEn: '30 Days',
      titleVi: '30 ngày',
      descriptionEn: 'Use the app for 30 days',
      descriptionVi: 'Sử dụng app 30 ngày',
      icon: Icons.star,
      color: info,
    ),
    Achievement(
      id: 'goal_reached',
      titleEn: 'Goal Reached',
      titleVi: 'Đạt mục tiêu',
      descriptionEn: 'Reach your weight goal',
      descriptionVi: 'Đạt mục tiêu cân nặng',
      icon: Icons.flag,
      color: primary,
    ),
  ];
}
