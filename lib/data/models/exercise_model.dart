import '../../core/network/api_config.dart';

/// Exercise Model - Phản ánh cấu trúc database HeathCare
class Exercise {
  final int exerciseId;
  final String slug;
  final String? force; // 'static', 'pull', 'push'
  final String level; // 'beginner', 'intermediate', 'expert'
  final String? mechanic; // 'isolation', 'compound'
  final String? equipment;
  final String category;
  final DateTime? createdAt;

  // Từ bảng translations
  final String name;
  final String? description;

  // Từ bảng ExercisePrimaryMuscles và ExerciseSecondaryMuscles
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  // Từ bảng ExerciseInstructions
  final List<String> instructions;

  // Từ bảng ExerciseImages
  final List<String> images;

  Exercise({
    required this.exerciseId,
    required this.slug,
    this.force,
    required this.level,
    this.mechanic,
    this.equipment,
    required this.category,
    this.createdAt,
    required this.name,
    this.description,
    this.primaryMuscles = const [],
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.images = const [],
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseId: json['exercise_id'] as int,
      slug: json['slug'] as String,
      force: json['force'] as String?,
      level: json['level'] as String,
      mechanic: json['mechanic'] as String?,
      equipment: json['equipment'] as String?,
      category: json['category'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      primaryMuscles: json['primary_muscles'] != null
          ? List<String>.from(json['primary_muscles'])
          : [],
      secondaryMuscles: json['secondary_muscles'] != null
          ? List<String>.from(json['secondary_muscles'])
          : [],
      instructions: json['instructions'] != null
          ? List<String>.from(json['instructions'])
          : [],
      images: json['images'] != null
          ? (json['images'] as List).map((img) => ApiConfig.getImageUrl(img.toString())).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'slug': slug,
    'force': force,
    'level': level,
    'mechanic': mechanic,
    'equipment': equipment,
    'category': category,
    'created_at': createdAt?.toIso8601String(),
    'name': name,
    'description': description,
    'primary_muscles': primaryMuscles,
    'secondary_muscles': secondaryMuscles,
    'instructions': instructions,
    'images': images,
  };

  Exercise copyWith({
    int? exerciseId,
    String? slug,
    String? force,
    String? level,
    String? mechanic,
    String? equipment,
    String? category,
    DateTime? createdAt,
    String? name,
    String? description,
    List<String>? primaryMuscles,
    List<String>? secondaryMuscles,
    List<String>? instructions,
    List<String>? images,
  }) {
    return Exercise(
      exerciseId: exerciseId ?? this.exerciseId,
      slug: slug ?? this.slug,
      force: force ?? this.force,
      level: level ?? this.level,
      mechanic: mechanic ?? this.mechanic,
      equipment: equipment ?? this.equipment,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryMuscles: primaryMuscles ?? this.primaryMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      instructions: instructions ?? this.instructions,
      images: images ?? this.images,
    );
  }
}

/// Muscle Model - Phản ánh bảng Muscles và Muscle_Translations
class Muscle {
  final int muscleId;
  final String code;
  final String name;
  final String? description;

  Muscle({
    required this.muscleId,
    required this.code,
    required this.name,
    this.description,
  });

  factory Muscle.fromJson(Map<String, dynamic> json) {
    return Muscle(
      muscleId: json['muscle_id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'muscle_id': muscleId,
    'code': code,
    'name': name,
    'description': description,
  };
}

/// Exercise Filter - Hỗ trợ chọn nhiều giá trị trong mỗi filter
class ExerciseFilter {
  final List<String> levels;
  final List<String> categories;
  final List<String> equipments;
  final List<String> muscles;
  final String? searchQuery;

  const ExerciseFilter({
    this.levels = const [],
    this.categories = const [],
    this.equipments = const [],
    this.muscles = const [],
    this.searchQuery,
  });

  // Backward compatibility getters
  String? get level => levels.isNotEmpty ? levels.first : null;
  String? get category => categories.isNotEmpty ? categories.first : null;
  String? get equipment => equipments.isNotEmpty ? equipments.first : null;
  String? get muscle => muscles.isNotEmpty ? muscles.first : null;

  /// Toggle một giá trị trong filter (thêm nếu chưa có, xóa nếu đã có)
  ExerciseFilter toggleLevel(String value) {
    final newLevels = List<String>.from(levels);
    if (newLevels.contains(value)) {
      newLevels.remove(value);
    } else {
      newLevels.add(value);
    }
    return ExerciseFilter(
      levels: newLevels,
      categories: categories,
      equipments: equipments,
      muscles: muscles,
      searchQuery: searchQuery,
    );
  }

  ExerciseFilter toggleCategory(String value) {
    final newCategories = List<String>.from(categories);
    if (newCategories.contains(value)) {
      newCategories.remove(value);
    } else {
      newCategories.add(value);
    }
    return ExerciseFilter(
      levels: levels,
      categories: newCategories,
      equipments: equipments,
      muscles: muscles,
      searchQuery: searchQuery,
    );
  }

  ExerciseFilter toggleEquipment(String value) {
    final newEquipments = List<String>.from(equipments);
    if (newEquipments.contains(value)) {
      newEquipments.remove(value);
    } else {
      newEquipments.add(value);
    }
    return ExerciseFilter(
      levels: levels,
      categories: categories,
      equipments: newEquipments,
      muscles: muscles,
      searchQuery: searchQuery,
    );
  }

  ExerciseFilter toggleMuscle(String value) {
    final newMuscles = List<String>.from(muscles);
    if (newMuscles.contains(value)) {
      newMuscles.remove(value);
    } else {
      newMuscles.add(value);
    }
    return ExerciseFilter(
      levels: levels,
      categories: categories,
      equipments: equipments,
      muscles: newMuscles,
      searchQuery: searchQuery,
    );
  }

  /// CopyWith
  ExerciseFilter copyWith({
    List<String>? levels,
    List<String>? categories,
    List<String>? equipments,
    List<String>? muscles,
    String? searchQuery,
  }) {
    return ExerciseFilter(
      levels: levels ?? this.levels,
      categories: categories ?? this.categories,
      equipments: equipments ?? this.equipments,
      muscles: muscles ?? this.muscles,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Xóa một filter cụ thể
  ExerciseFilter clearLevelFilter() => copyWith(levels: []);
  ExerciseFilter clearCategoryFilter() => copyWith(categories: []);
  ExerciseFilter clearEquipmentFilter() => copyWith(equipments: []);
  ExerciseFilter clearMuscleFilter() => copyWith(muscles: []);

  bool get hasFilters =>
      levels.isNotEmpty ||
      categories.isNotEmpty ||
      equipments.isNotEmpty ||
      muscles.isNotEmpty ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// Kiểm tra filter rỗng (để tối ưu tính toán)
  bool get isEmpty => !hasFilters;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseFilter) return false;
    return _listEquals(other.levels, levels) &&
        _listEquals(other.categories, categories) &&
        _listEquals(other.equipments, equipments) &&
        _listEquals(other.muscles, muscles) &&
        other.searchQuery == searchQuery;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(level, category, equipment, muscle, searchQuery);
}

/// Exercise Tracking Model - Phản ánh bảng Exercise_Tracking
class ExerciseTracking {
  final int trackingId;
  final int userId;
  final int exerciseId;
  final int? durationMinutes;
  final double? caloriesBurned;
  final DateTime date;

  ExerciseTracking({
    required this.trackingId,
    required this.userId,
    required this.exerciseId,
    this.durationMinutes,
    this.caloriesBurned,
    required this.date,
  });

  factory ExerciseTracking.fromJson(Map<String, dynamic> json) {
    return ExerciseTracking(
      trackingId: json['tracking_id'] as int,
      userId: json['user_id'] as int,
      exerciseId: json['exercise_id'] as int,
      durationMinutes: json['duration_minutes'] as int?,
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
      date: DateTime.parse(json['date'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'tracking_id': trackingId,
    'user_id': userId,
    'exercise_id': exerciseId,
    'duration_minutes': durationMinutes,
    'calories_burned': caloriesBurned,
    'date': date.toIso8601String(),
  };
}

