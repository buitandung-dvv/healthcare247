/// Plan Model - Phản ánh bảng Plans trong database HeathCare
class Plan {
  final int planId;
  final int? userId;
  final String? name; // Tên kế hoạch
  final String? planType;
  final String? description;
  final DateTime? createdAt;

  // Từ bảng Plan_Details
  final List<PlanDetail> details;

  Plan({
    required this.planId,
    this.userId,
    this.name,
    this.planType,
    this.description,
    this.createdAt,
    this.details = const [],
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      planId: json['plan_id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String?,
      planType: json['plan_type'] as String?,
      description: json['description'] as String?,
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
    'created_at': createdAt?.toIso8601String(),
    'details': details.map((e) => e.toJson()).toList(),
  };
}

/// Plan Detail - Phản ánh bảng Plan_Details
class PlanDetail {
  final int planId;
  final int dayOfWeek; // 1 = Monday, ... 7 = Sunday (database uses 1-7)
  final int? exerciseId;
  final int? recipeId; // Changed from mealId to match database

  final int? sets;
  final int? reps;
  final int? restDuration;
  final int? orderIndex;
  final String? exerciseName;
  final String? recipeName; // Changed from mealName

  PlanDetail({
    required this.planId,
    required this.dayOfWeek,
    this.exerciseId,
    this.recipeId,
    this.sets,
    this.reps,
    this.restDuration,
    this.orderIndex,
    this.exerciseName,
    this.recipeName,
  });

  // Generate a unique ID from composite key
  String get compositeId => '${planId}_${dayOfWeek}_${orderIndex ?? 0}';

  factory PlanDetail.fromJson(Map<String, dynamic> json) {
    return PlanDetail(
      planId: json['plan_id'] as int,
      dayOfWeek: json['day_of_week'] as int,
      exerciseId: json['exercise_id'] as int?,
      recipeId: json['recipe_id'] as int?,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
      restDuration: json['rest_duration'] as int?,
      orderIndex: json['order_index'] as int?,
      exerciseName: json['exercise_name'] as String?,
      recipeName: json['recipe_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'day_of_week': dayOfWeek,
    'exercise_id': exerciseId,
    'recipe_id': recipeId,
    'sets': sets,
    'reps': reps,
    'rest_duration': restDuration,
    'order_index': orderIndex,
  };

  /// Lấy tên ngày trong tuần
  String getDayName({bool vietnamese = false}) {
    const daysEn = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    const daysVi = [
      'Chủ nhật',
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
    ];
    return vietnamese ? daysVi[dayOfWeek] : daysEn[dayOfWeek];
  }
}
