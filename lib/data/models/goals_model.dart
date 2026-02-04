import 'package:equatable/equatable.dart';

/// User Goals Model - Phản ánh bảng User_Goals trong database HeathCare
/// Tracks user health and fitness goals with calories, macros, water, and workout targets
class UserGoals extends Equatable {
  final int? goalId;
  final int userId;
  final double caloriesGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final int waterGoalMl;
  final int workoutsPerWeek;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserGoals({
    this.goalId,
    required this.userId,
    this.caloriesGoal = 2000,
    this.proteinGoal = 150,
    this.carbsGoal = 250,
    this.fatGoal = 65,
    this.waterGoalMl = 2000,
    this.workoutsPerWeek = 3,
    this.createdAt,
    this.updatedAt,
  });

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      goalId: json['goal_id'] as int?,
      userId: json['user_id'] as int,
      caloriesGoal: (json['calories_goal'] as num?)?.toDouble() ?? 2000,
      proteinGoal: (json['protein_goal'] as num?)?.toDouble() ?? 150,
      carbsGoal: (json['carbs_goal'] as num?)?.toDouble() ?? 250,
      fatGoal: (json['fat_goal'] as num?)?.toDouble() ?? 65,
      waterGoalMl: json['water_goal_ml'] as int? ?? 2000,
      workoutsPerWeek: json['workouts_per_week'] as int? ?? 3,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (goalId != null) 'goal_id': goalId,
      'user_id': userId,
      'calories_goal': caloriesGoal,
      'protein_goal': proteinGoal,
      'carbs_goal': carbsGoal,
      'fat_goal': fatGoal,
      'water_goal_ml': waterGoalMl,
      'workouts_per_week': workoutsPerWeek,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserGoals copyWith({
    int? goalId,
    int? userId,
    double? caloriesGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? waterGoalMl,
    int? workoutsPerWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGoals(
      goalId: goalId ?? this.goalId,
      userId: userId ?? this.userId,
      caloriesGoal: caloriesGoal ?? this.caloriesGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      workoutsPerWeek: workoutsPerWeek ?? this.workoutsPerWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate daily calorie allowance remaining
  double getRemainingCalories(double consumed) => caloriesGoal - consumed;

  /// Check if water goal is met
  bool isWaterGoalMet(int consumed) => consumed >= waterGoalMl;

  @override
  List<Object?> get props => [
    goalId,
    userId,
    caloriesGoal,
    proteinGoal,
    carbsGoal,
    fatGoal,
  ];
}
