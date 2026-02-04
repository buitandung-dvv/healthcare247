/// Food Model - Phản ánh bảng Foods trong database HeathCare
/// Bảng này đã merge với Daily_Foods trong schema mới
class Food {
  final int foodId;
  final String code;
  final String? source; // 'nutrition_vn', 'daily_food', 'user'
  final String? mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final double? calories;
  final double? protein;
  final double? fat;
  final double? saturatedFat;
  final double? carbs;
  final double? fiber;
  final double? sugars;
  final double? cholesterol;
  final double? calcium;
  final double? phosphorus;
  final double? iron;
  final double? sodium;
  final double? potassium;
  final double? magnesium;
  final double? betaCarotene;
  final double? vitaminA;
  final double? vitaminB1;
  final double? vitaminC;
  final double? water;
  final String? categoryCode;
  final int? waterIntakeMl;
  final DateTime? createdAt;

  // Từ bảng Food_Translations
  final String name;
  final String? categoryName;

  Food({
    required this.foodId,
    required this.code,
    this.source,
    this.mealType,
    this.calories,
    this.protein,
    this.fat,
    this.saturatedFat,
    this.carbs,
    this.fiber,
    this.sugars,
    this.cholesterol,
    this.calcium,
    this.phosphorus,
    this.iron,
    this.sodium,
    this.potassium,
    this.magnesium,
    this.betaCarotene,
    this.vitaminA,
    this.vitaminB1,
    this.vitaminC,
    this.water,
    this.categoryCode,
    this.waterIntakeMl,
    this.createdAt,
    required this.name,
    this.categoryName,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      foodId: json['food_id'] as int,
      code: json['code'] as String,
      source: json['source'] as String?,
      mealType: json['meal_type'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      saturatedFat: (json['saturated_fat'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      sugars: (json['sugars'] as num?)?.toDouble(),
      cholesterol: (json['cholesterol'] as num?)?.toDouble(),
      calcium: (json['calcium'] as num?)?.toDouble(),
      phosphorus: (json['phosphorus'] as num?)?.toDouble(),
      iron: (json['iron'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      potassium: (json['potassium'] as num?)?.toDouble(),
      magnesium: (json['magnesium'] as num?)?.toDouble(),
      betaCarotene: (json['beta_carotene'] as num?)?.toDouble(),
      vitaminA: (json['vitamin_a'] as num?)?.toDouble(),
      vitaminB1: (json['vitamin_b1'] as num?)?.toDouble(),
      vitaminC: (json['vitamin_c'] as num?)?.toDouble(),
      water: (json['water'] as num?)?.toDouble(),
      categoryCode: json['category_code'] as String?,
      waterIntakeMl: json['water_intake_ml'] as int?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      name: json['name'] as String? ?? '',
      categoryName: json['category_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'food_id': foodId,
    'code': code,
    'source': source,
    'meal_type': mealType,
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'saturated_fat': saturatedFat,
    'carbs': carbs,
    'fiber': fiber,
    'sugars': sugars,
    'cholesterol': cholesterol,
    'calcium': calcium,
    'phosphorus': phosphorus,
    'iron': iron,
    'sodium': sodium,
    'potassium': potassium,
    'magnesium': magnesium,
    'beta_carotene': betaCarotene,
    'vitamin_a': vitaminA,
    'vitamin_b1': vitaminB1,
    'vitamin_c': vitaminC,
    'water': water,
    'category_code': categoryCode,
    'water_intake_ml': waterIntakeMl,
    'created_at': createdAt?.toIso8601String(),
    'name': name,
    'category_name': categoryName,
  };
}

// NOTE: Meal và MealFoodItem đã bị xóa vì không còn tồn tại trong database.
// Sử dụng Recipe và Favorite_Foods/Favorite_Recipes thay thế.
// Xem: recipe_model.dart và favorite_model.dart

/// Meal Tracking - Phản ánh bảng Meal_Tracking trong database
/// Theo DB schema: sử dụng recipe_id HOẶC food_id (không còn meal_id)
class MealTracking {
  final int userId;
  final DateTime trackedDate;
  final String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final int? recipeId;
  final int? foodId;
  final String? mealName; // Tên tùy chỉnh nếu không từ recipe/food
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double quantity;
  final String? notes;
  final DateTime createdAt;

  MealTracking({
    required this.userId,
    required this.trackedDate,
    required this.mealType,
    this.recipeId,
    this.foodId,
    this.mealName,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.quantity = 100,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MealTracking.fromJson(Map<String, dynamic> json) {
    // Handle both 'tracked_date' and 'date' from API
    DateTime trackedDate;
    if (json['tracked_date'] != null) {
      trackedDate = DateTime.parse(json['tracked_date'] as String);
    } else if (json['date'] != null) {
      trackedDate = DateTime.parse(json['date'] as String);
    } else {
      trackedDate = DateTime.now();
    }

    return MealTracking(
      userId: json['user_id'] as int,
      trackedDate: trackedDate,
      mealType: json['meal_type'] as String? ?? 'Snack',
      recipeId: json['recipe_id'] as int?,
      foodId: json['food_id'] as int?,
      mealName: json['meal_name'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 100,
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'tracked_date': trackedDate.toIso8601String().split('T')[0], // DATE only
    'meal_type': mealType,
    if (recipeId != null) 'recipe_id': recipeId,
    if (foodId != null) 'food_id': foodId,
    'meal_name': mealName,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'quantity': quantity,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };
}
