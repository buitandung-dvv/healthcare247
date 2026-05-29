import 'package:equatable/equatable.dart';
import 'meal_model.dart';
import 'recipe_model.dart';

/// Favorite Food Model - User's favorite foods
class FavoriteFood extends Equatable {
  final int userId;
  final int foodId;
  final String? notes;
  final DateTime? createdAt;

  // Optional joined data
  final Food? food;

  const FavoriteFood({
    required this.userId,
    required this.foodId,
    this.notes,
    this.createdAt,
    this.food,
  });

  factory FavoriteFood.fromJson(Map<String, dynamic> json) {
    return FavoriteFood(
      userId: json['user_id'] as int,
      foodId: json['food_id'] as int,
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      food:
          json['food'] != null
              ? Food.fromJson(json['food'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'food_id': foodId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      if (food != null) 'food': food!.toJson(),
    };
  }

  @override
  List<Object?> get props => [userId, foodId, createdAt];
}

/// Favorite Recipe Model - User's favorite recipes
class FavoriteRecipe extends Equatable {
  final int userId;
  final int recipeId;
  final String? notes;
  final DateTime? createdAt;

  // Optional joined data
  final Recipe? recipe;

  const FavoriteRecipe({
    required this.userId,
    required this.recipeId,
    this.notes,
    this.createdAt,
    this.recipe,
  });

  factory FavoriteRecipe.fromJson(Map<String, dynamic> json) {
    return FavoriteRecipe(
      userId: json['user_id'] as int,
      recipeId: json['recipe_id'] as int,
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      recipe:
          json['recipe'] != null
              ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'recipe_id': recipeId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      if (recipe != null) 'recipe': recipe!.toJson(),
    };
  }

  @override
  List<Object?> get props => [userId, recipeId, createdAt];
}

/// Favorite Exercise Model - User's favorite exercises
class FavoriteExercise extends Equatable {
  final int userId;
  final int exerciseId;
  final String? notes;
  final DateTime? createdAt;

  // Optional joined data
  final String? name;
  final String? bodyPart;
  final String? equipment;
  final String? gifUrl;
  final String? targetMuscle;

  const FavoriteExercise({
    required this.userId,
    required this.exerciseId,
    this.notes,
    this.createdAt,
    this.name,
    this.bodyPart,
    this.equipment,
    this.gifUrl,
    this.targetMuscle,
  });

  factory FavoriteExercise.fromJson(Map<String, dynamic> json) {
    final exercise = json['exercise'] as Map<String, dynamic>?;
    return FavoriteExercise(
      userId: json['user_id'] as int,
      exerciseId: json['exercise_id'] as int,
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      name: exercise?['name'] as String?,
      bodyPart: exercise?['body_part'] as String?,
      equipment: exercise?['equipment'] as String?,
      gifUrl: exercise?['gif_url'] as String?,
      targetMuscle: exercise?['target_muscle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'exercise_id': exerciseId,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, exerciseId, createdAt];
}
