import 'package:equatable/equatable.dart';

/// Food Model - Thực phẩm và dinh dưỡng
class Food extends Equatable {
  final int foodId;
  final String code;
  final String name;
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? fiber;
  final double? cholesterol;
  final double? calcium;
  final double? iron;
  final String? categoryCode;
  final DateTime? createdAt;

  const Food({
    required this.foodId,
    required this.code,
    required this.name,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.fiber,
    this.cholesterol,
    this.calcium,
    this.iron,
    this.categoryCode,
    this.createdAt,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      foodId: json['food_id'] as int,
      code: json['code'] as String,
      name: json['name'] as String? ?? '',
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      cholesterol: (json['cholesterol'] as num?)?.toDouble(),
      calcium: (json['calcium'] as num?)?.toDouble(),
      iron: (json['iron'] as num?)?.toDouble(),
      categoryCode: json['category_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'code': code,
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'fiber': fiber,
      'cholesterol': cholesterol,
      'calcium': calcium,
      'iron': iron,
      'category_code': categoryCode,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [foodId, code, name];
}

