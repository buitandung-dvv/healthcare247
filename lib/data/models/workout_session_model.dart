import 'package:health_care/data/models/plan_model.dart';

class WorkoutSession {
  final int sessionId;
  final int userId;
  final int? planId;
  final int? exerciseId;
  final String? name;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? totalDuration; // seconds
  final double? caloriesBurned;
  final String status; // in_progress, completed, cancelled
  final String? notes;
  final List<WorkoutSessionDetail> details;

  // Optional relations
  final Plan? plan;

  WorkoutSession({
    required this.sessionId,
    required this.userId,
    this.planId,
    this.exerciseId,
    this.name,
    required this.startedAt,
    this.completedAt,
    this.totalDuration,
    this.caloriesBurned,
    required this.status,
    this.notes,
    this.details = const [],
    this.plan,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      sessionId: json['session_id'] as int,
      userId: json['user_id'] as int,
      planId: json['plan_id'] as int?,
      exerciseId: json['exercise_id'] as int?,
      name: json['name'] as String?,
      startedAt: DateTime.parse(json['started_at'].toString()),
      completedAt:
          json['completed_at'] != null
              ? DateTime.tryParse(json['completed_at'].toString())
              : null,
      totalDuration: json['total_duration'] as int?,
      caloriesBurned:
          json['calories_burned'] != null
              ? (json['calories_burned'] as num).toDouble()
              : null,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      details:
          json['details'] != null
              ? (json['details'] as List)
                  .map(
                    (e) => WorkoutSessionDetail.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList()
              : [],
      plan:
          json['plan'] != null
              ? Plan.fromJson(json['plan'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
    'user_id': userId,
    'plan_id': planId,
    'exercise_id': exerciseId,
    'name': name,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'total_duration': totalDuration,
    'calories_burned': caloriesBurned,
    'status': status,
    'notes': notes,
    'details': details.map((e) => e.toJson()).toList(),
  };
}

class WorkoutSessionDetail {
  final int detailId;
  final int sessionId;
  final int exerciseId;
  final int targetSets;
  final int targetReps;
  final int setsCompleted;
  final String? repsCompleted; // JSON string
  final String? weightUsed; // JSON string
  final int restDuration;
  final int orderIndex;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final String? exerciseName;

  WorkoutSessionDetail({
    required this.detailId,
    required this.sessionId,
    required this.exerciseId,
    this.targetSets = 3,
    this.targetReps = 10,
    this.setsCompleted = 0,
    this.repsCompleted,
    this.weightUsed,
    this.restDuration = 60,
    this.orderIndex = 0,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.exerciseName,
  });

  factory WorkoutSessionDetail.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionDetail(
      detailId: json['detail_id'] as int? ?? 0,
      sessionId: json['session_id'] as int? ?? 0,
      exerciseId: json['exercise_id'] as int? ?? 0,
      targetSets: json['target_sets'] as int? ?? 3,
      targetReps: json['target_reps'] as int? ?? 10,
      setsCompleted: json['sets_completed'] as int? ?? 0,
      repsCompleted: json['reps_completed'] as String?,
      weightUsed: json['weight_used'] as String?,
      restDuration: json['rest_duration'] as int? ?? 60,
      orderIndex: json['order_index'] as int? ?? 0,
      startedAt:
          json['started_at'] != null
              ? DateTime.tryParse(json['started_at'].toString())
              : null,
      completedAt:
          json['completed_at'] != null
              ? DateTime.tryParse(json['completed_at'].toString())
              : null,
      notes: json['notes'] as String?,
      exerciseName: json['exercise_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'detail_id': detailId,
    'session_id': sessionId,
    'exercise_id': exerciseId,
    'target_sets': targetSets,
    'target_reps': targetReps,
    'sets_completed': setsCompleted,
    'reps_completed': repsCompleted,
    'weight_used': weightUsed,
    'rest_duration': restDuration,
    'order_index': orderIndex,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'notes': notes,
  };
}
