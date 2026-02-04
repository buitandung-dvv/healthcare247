import 'package:equatable/equatable.dart';

/// Exercise Tracking Model
class ExerciseTracking extends Equatable {
  final int? trackingId;
  final int userId;
  final int exerciseId;
  final String? exerciseName;
  final int? duration; // in minutes
  final int? sets;
  final int? reps;
  final double? weight;
  final double? caloriesBurned;
  final String? notes;
  final DateTime trackedAt;

  const ExerciseTracking({
    this.trackingId,
    required this.userId,
    required this.exerciseId,
    this.exerciseName,
    this.duration,
    this.sets,
    this.reps,
    this.weight,
    this.caloriesBurned,
    this.notes,
    required this.trackedAt,
  });

  factory ExerciseTracking.fromJson(Map<String, dynamic> json) {
    return ExerciseTracking(
      trackingId: json['tracking_id'] as int?,
      userId: json['user_id'] as int,
      exerciseId: json['exercise_id'] as int,
      exerciseName: json['exercise_name'] as String?,
      duration: json['duration'] as int?,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      trackedAt:
          json['tracked_at'] != null
              ? DateTime.parse(json['tracked_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracking_id': trackingId,
      'user_id': userId,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'duration': duration,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'calories_burned': caloriesBurned,
      'notes': notes,
      'tracked_at': trackedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [trackingId, userId, exerciseId, trackedAt];
}

/// Meal Tracking Model
class MealTracking extends Equatable {
  final int? trackingId;
  final int userId;
  final int? mealId;
  final String? mealType;
  final String? mealName;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? notes;
  final double? quantity;
  final DateTime trackedAt;

  const MealTracking({
    this.trackingId,
    required this.userId,
    this.mealId,
    this.mealType,
    this.mealName,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.notes,
    this.quantity,
    required this.trackedAt,
  });

  factory MealTracking.fromJson(Map<String, dynamic> json) {
    // Handle both 'tracked_at' and 'date' fields from API
    DateTime trackedAt;
    if (json['tracked_at'] != null) {
      trackedAt = DateTime.parse(json['tracked_at'] as String);
    } else if (json['date'] != null) {
      trackedAt = DateTime.parse(json['date'] as String);
    } else {
      trackedAt = DateTime.now();
    }

    return MealTracking(
      trackingId: json['tracking_id'] as int?,
      userId: json['user_id'] as int,
      mealId: json['meal_id'] as int?,
      mealType: json['meal_type'] as String?,
      mealName: json['meal_name'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 100,
      trackedAt: trackedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracking_id': trackingId,
      'user_id': userId,
      'meal_id': mealId,
      'meal_type': mealType,
      'meal_name': mealName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'notes': notes,
      'tracked_at': trackedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [trackingId, userId, mealId, trackedAt];
}

/// Weight Tracking Model
class WeightTracking extends Equatable {
  final int? trackingId;
  final int userId;
  final double weight;
  final String? notes;
  final DateTime trackedAt;

  const WeightTracking({
    this.trackingId,
    required this.userId,
    required this.weight,
    this.notes,
    required this.trackedAt,
  });

  factory WeightTracking.fromJson(Map<String, dynamic> json) {
    return WeightTracking(
      trackingId: json['tracking_id'] as int?,
      userId: json['user_id'] as int,
      weight: (json['weight'] as num).toDouble(),
      notes: json['notes'] as String?,
      trackedAt:
          json['tracked_at'] != null
              ? DateTime.parse(json['tracked_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracking_id': trackingId,
      'user_id': userId,
      'weight': weight,
      'notes': notes,
      'tracked_at': trackedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [trackingId, userId, weight, trackedAt];
}

/// Water Tracking Model
class WaterTracking extends Equatable {
  final int? trackingId;
  final int userId;
  final int amountMl;
  final String? notes;
  final DateTime trackedAt;

  const WaterTracking({
    this.trackingId,
    required this.userId,
    required this.amountMl,
    this.notes,
    required this.trackedAt,
  });

  factory WaterTracking.fromJson(Map<String, dynamic> json) {
    return WaterTracking(
      trackingId: json['tracking_id'] as int?,
      userId: json['user_id'] as int,
      amountMl: json['amount_ml'] as int,
      notes: json['notes'] as String?,
      trackedAt:
          json['tracked_at'] != null
              ? DateTime.parse(json['tracked_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracking_id': trackingId,
      'user_id': userId,
      'amount_ml': amountMl,
      'notes': notes,
      'tracked_at': trackedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [trackingId, userId, amountMl, trackedAt];
}

/// Daily Water Intake Summary
class DailyWaterIntake extends Equatable {
  final int totalMl;
  final int entries;
  final int goalMl;
  final double progress;

  const DailyWaterIntake({
    this.totalMl = 0,
    this.entries = 0,
    this.goalMl = 2000,
    this.progress = 0,
  });

  factory DailyWaterIntake.fromJson(Map<String, dynamic> json) {
    return DailyWaterIntake(
      totalMl: json['total_ml'] as int? ?? 0,
      entries: json['entries'] as int? ?? 0,
      goalMl: json['goal_ml'] as int? ?? 2000,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Remaining water to drink in ml
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);

  /// Number of glasses (assuming 250ml per glass)
  int get glassesConsumed => (totalMl / 250).floor();
  int get glassesGoal => (goalMl / 250).floor();

  @override
  List<Object?> get props => [totalMl, entries, goalMl, progress];
}

/// Daily Progress Summary
class DailyProgress extends Equatable {
  final DateTime date;
  final double caloriesConsumed;
  final double caloriesBurned;
  final double caloriesGoal;
  final double protein;
  final double proteinGoal;
  final double carbs;
  final double carbsGoal;
  final double fat;
  final double fatGoal;
  final int workoutsCompleted;
  final int workoutsPlanned;
  final int mealsLogged;

  const DailyProgress({
    required this.date,
    this.caloriesConsumed = 0,
    this.caloriesBurned = 0,
    this.caloriesGoal = 2000,
    this.protein = 0,
    this.proteinGoal = 150,
    this.carbs = 0,
    this.carbsGoal = 250,
    this.fat = 0,
    this.fatGoal = 65,
    this.workoutsCompleted = 0,
    this.workoutsPlanned = 0,
    this.mealsLogged = 0,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: DateTime.parse(json['date'] as String),
      caloriesConsumed: (json['calories_consumed'] as num?)?.toDouble() ?? 0,
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble() ?? 0,
      caloriesGoal: (json['calories_goal'] as num?)?.toDouble() ?? 2000,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      proteinGoal: (json['protein_goal'] as num?)?.toDouble() ?? 150,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      carbsGoal: (json['carbs_goal'] as num?)?.toDouble() ?? 250,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fatGoal: (json['fat_goal'] as num?)?.toDouble() ?? 65,
      workoutsCompleted: json['workouts_completed'] as int? ?? 0,
      workoutsPlanned: json['workouts_planned'] as int? ?? 0,
      mealsLogged: json['meals_logged'] as int? ?? 0,
    );
  }

  double get caloriesProgress =>
      caloriesGoal > 0 ? (caloriesConsumed / caloriesGoal).clamp(0, 1) : 0;

  double get proteinProgress =>
      proteinGoal > 0 ? (protein / proteinGoal).clamp(0, 1) : 0;

  double get carbsProgress =>
      carbsGoal > 0 ? (carbs / carbsGoal).clamp(0, 1) : 0;

  double get fatProgress => fatGoal > 0 ? (fat / fatGoal).clamp(0, 1) : 0;

  double get workoutProgress =>
      workoutsPlanned > 0
          ? (workoutsCompleted / workoutsPlanned).clamp(0, 1)
          : 0;

  double get netCalories => caloriesConsumed - caloriesBurned;

  @override
  List<Object?> get props => [date];
}
