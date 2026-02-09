/// Plan Model - Phản ánh bảng Plans trong database HeathCare
class Plan {
  final int planId;
  final int? userId;
  final String? name; // Tên kế hoạch
  final String? planType;
  final String? description;
  final List<int> scheduleDays; // Các ngày tập (1=Mon, 7=Sun)
  final DateTime? createdAt;

  // Từ bảng Plan_Details
  final List<PlanDetail> details;

  Plan({
    required this.planId,
    this.userId,
    this.name,
    this.planType,
    this.description,
    this.scheduleDays = const [],
    this.createdAt,
    this.details = const [],
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // Parse schedule_days from string "1,3,5" to List<int> [1, 3, 5]
    List<int> parsedScheduleDays = [];
    if (json['schedule_days'] != null &&
        json['schedule_days'].toString().isNotEmpty) {
      parsedScheduleDays =
          json['schedule_days']
              .toString()
              .split(',')
              .map((s) => int.tryParse(s.trim()) ?? 0)
              .where((n) => n > 0)
              .toList();
    }

    return Plan(
      planId: json['plan_id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String?,
      planType: json['plan_type'] as String?,
      description: json['description'] as String?,
      scheduleDays: parsedScheduleDays,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      details:
          json['details'] != null
              ? (json['details'] as List)
                  .map((e) => PlanDetail.fromJson(e as Map<String, dynamic>))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'user_id': userId,
    'name': name,
    'plan_type': planType,
    'description': description,
    'schedule_days': scheduleDays.join(','),
    'created_at': createdAt?.toIso8601String(),
    'details': details.map((e) => e.toJson()).toList(),
  };

  /// Kiểm tra plan có lịch tập vào ngày nào đó không
  bool hasScheduleOnDay(int dayOfWeek) => scheduleDays.contains(dayOfWeek);
}

/// Plan Detail - Phản ánh bảng Plan_Details
class PlanDetail {
  final int planId;
  final int? exerciseId;
  final int? recipeId;

  final int? sets;
  final int? reps;
  final int? restDuration;
  final int? orderIndex;
  final String? exerciseName;
  final String? exerciseImage;
  final String? recipeName;

  PlanDetail({
    required this.planId,
    this.exerciseId,
    this.recipeId,
    this.sets,
    this.reps,
    this.restDuration,
    this.orderIndex,
    this.exerciseName,
    this.exerciseImage,
    this.recipeName,
  });

  // Generate a unique ID from composite key
  String get compositeId => '${planId}_${exerciseId ?? 0}_${orderIndex ?? 0}';

  factory PlanDetail.fromJson(Map<String, dynamic> json) {
    return PlanDetail(
      planId: json['plan_id'] as int,
      exerciseId: json['exercise_id'] as int?,
      recipeId: json['recipe_id'] as int?,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      restDuration: json['rest_duration'] as int?,
      orderIndex: json['order_index'] as int?,
      exerciseName: json['exercise_name'] as String?,
      exerciseImage: json['exercise_image'] as String?,
      recipeName: json['recipe_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'exercise_id': exerciseId,
    'recipe_id': recipeId,
    'sets': sets,
    'reps': reps,
    'rest_duration': restDuration,
    'order_index': orderIndex,
  };
}
