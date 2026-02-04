/// Recipe Model - Phản ánh cấu trúc database HeathCare v2.2
class Recipe {
  final int recipeId;
  final String recipeCode;
  final String? themealdbId;
  final String? category;
  final String? area;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? youtubeUrl;
  final String? sourceUrl;
  final String? tags;
  final DateTime? createdAt;

  // Từ bảng Recipe_Translations
  final String name;
  final String? overview; // Giới thiệu tổng quan

  // Từ bảng Recipe_Instructions (step-by-step)
  final List<RecipeInstruction> instructions;

  // Từ bảng Recipe_Ingredients
  final List<RecipeIngredient> ingredients;

  // Thông tin dinh dưỡng (tính toán hoặc lấy từ API)
  final NutritionInfo? nutritionInfo;

  Recipe({
    required this.recipeId,
    required this.recipeCode,
    this.themealdbId,
    this.category,
    this.area,
    this.imageUrl,
    this.thumbnailUrl,
    this.youtubeUrl,
    this.sourceUrl,
    this.tags,
    this.createdAt,
    required this.name,
    this.overview,
    this.instructions = const [],
    this.ingredients = const [],
    this.nutritionInfo,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Parse instructions - có thể là List<RecipeInstruction> hoặc String (backward compat)
    List<RecipeInstruction> parsedInstructions = [];
    if (json['instructions'] != null) {
      if (json['instructions'] is List) {
        parsedInstructions =
            (json['instructions'] as List)
                .map(
                  (e) => RecipeInstruction.fromJson(e as Map<String, dynamic>),
                )
                .toList();
      }
    }

    return Recipe(
      recipeId: json['recipe_id'] as int,
      recipeCode: json['recipe_code'] as String,
      themealdbId: json['themealdb_id'] as String?,
      category: json['category'] as String?,
      area: json['area'] as String?,
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      sourceUrl: json['source_url'] as String?,
      tags: json['tags'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      instructions: parsedInstructions,
      ingredients:
          json['ingredients'] != null
              ? (json['ingredients'] as List)
                  .map(
                    (e) => RecipeIngredient.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : [],
      nutritionInfo:
          json['nutrition_info'] != null
              ? NutritionInfo.fromJson(
                json['nutrition_info'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'recipe_id': recipeId,
    'recipe_code': recipeCode,
    'themealdb_id': themealdbId,
    'category': category,
    'area': area,
    'image_url': imageUrl,
    'thumbnail_url': thumbnailUrl,
    'youtube_url': youtubeUrl,
    'source_url': sourceUrl,
    'tags': tags,
    'created_at': createdAt?.toIso8601String(),
    'name': name,
    'overview': overview,
    'instructions': instructions.map((e) => e.toJson()).toList(),
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'nutrition_info': nutritionInfo?.toJson(),
  };

  /// Lấy danh sách tags dưới dạng List
  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Lấy instructions dạng text đơn (backward compatibility)
  String get instructionsText {
    if (instructions.isEmpty) return overview ?? '';
    return instructions
        .map((i) => '${i.stepOrder}. ${i.instruction}')
        .join('\n');
  }

  Recipe copyWith({
    int? recipeId,
    String? recipeCode,
    String? themealdbId,
    String? category,
    String? area,
    String? imageUrl,
    String? thumbnailUrl,
    String? youtubeUrl,
    String? sourceUrl,
    String? tags,
    DateTime? createdAt,
    String? name,
    String? overview,
    List<RecipeInstruction>? instructions,
    List<RecipeIngredient>? ingredients,
    NutritionInfo? nutritionInfo,
  }) {
    return Recipe(
      recipeId: recipeId ?? this.recipeId,
      recipeCode: recipeCode ?? this.recipeCode,
      themealdbId: themealdbId ?? this.themealdbId,
      category: category ?? this.category,
      area: area ?? this.area,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      overview: overview ?? this.overview,
      instructions: instructions ?? this.instructions,
      ingredients: ingredients ?? this.ingredients,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
    );
  }
}

/// Recipe Instruction - Phản ánh bảng Recipe_Instructions
class RecipeInstruction {
  final int stepOrder;
  final String instruction;

  RecipeInstruction({required this.stepOrder, required this.instruction});

  factory RecipeInstruction.fromJson(Map<String, dynamic> json) {
    return RecipeInstruction(
      stepOrder: json['step_order'] as int? ?? 1,
      instruction: json['instruction'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'step_order': stepOrder,
    'instruction': instruction,
  };
}

/// Recipe Ingredient - Phản ánh bảng Recipe_Ingredients
class RecipeIngredient {
  final int? ingredientId;
  final int? recipeId;
  final int? languageId;
  final String ingredientName;
  final String? measure;
  final int displayOrder;

  RecipeIngredient({
    this.ingredientId,
    this.recipeId,
    this.languageId,
    required this.ingredientName,
    this.measure,
    this.displayOrder = 0,
  });

  // Backward compatibility - alias
  String get ingredient => ingredientName;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredient_id'] as int?,
      recipeId: json['recipe_id'] as int?,
      languageId: json['language_id'] as int?,
      ingredientName:
          json['ingredient_name'] as String? ??
          json['ingredient'] as String? ??
          '',
      measure: json['measure'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'ingredient_id': ingredientId,
    'recipe_id': recipeId,
    'language_id': languageId,
    'ingredient_name': ingredientName,
    'measure': measure,
    'display_order': displayOrder,
  };
}

/// Nutrition Info
class NutritionInfo {
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fiber;
  final double? cholesterol;
  final double? sodium;
  final double? potassium;

  const NutritionInfo({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.cholesterol,
    this.sodium,
    this.potassium,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      cholesterol: (json['cholesterol'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      potassium: (json['potassium'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'cholesterol': cholesterol,
    'sodium': sodium,
    'potassium': potassium,
  };
}

/// Recipe Filter - Hỗ trợ chọn nhiều giá trị trong mỗi filter
class RecipeFilter {
  final List<String> categories;
  final List<String> areas;
  final String? searchQuery;
  final List<String> tags;

  const RecipeFilter({
    this.categories = const [],
    this.areas = const [],
    this.searchQuery,
    this.tags = const [],
  });

  // Backward compatibility getters
  String? get category => categories.isNotEmpty ? categories.first : null;
  String? get area => areas.isNotEmpty ? areas.first : null;

  /// Toggle một giá trị trong filter
  RecipeFilter toggleCategory(String value) {
    final newCategories = List<String>.from(categories);
    if (newCategories.contains(value)) {
      newCategories.remove(value);
    } else {
      newCategories.add(value);
    }
    return RecipeFilter(
      categories: newCategories,
      areas: areas,
      searchQuery: searchQuery,
      tags: tags,
    );
  }

  RecipeFilter toggleArea(String value) {
    final newAreas = List<String>.from(areas);
    if (newAreas.contains(value)) {
      newAreas.remove(value);
    } else {
      newAreas.add(value);
    }
    return RecipeFilter(
      categories: categories,
      areas: newAreas,
      searchQuery: searchQuery,
      tags: tags,
    );
  }

  RecipeFilter toggleTag(String value) {
    final newTags = List<String>.from(tags);
    if (newTags.contains(value)) {
      newTags.remove(value);
    } else {
      newTags.add(value);
    }
    return RecipeFilter(
      categories: categories,
      areas: areas,
      searchQuery: searchQuery,
      tags: newTags,
    );
  }

  /// CopyWith
  RecipeFilter copyWith({
    List<String>? categories,
    List<String>? areas,
    String? searchQuery,
    List<String>? tags,
  }) {
    return RecipeFilter(
      categories: categories ?? this.categories,
      areas: areas ?? this.areas,
      searchQuery: searchQuery ?? this.searchQuery,
      tags: tags ?? this.tags,
    );
  }

  /// Clear filters
  RecipeFilter clearCategoryFilter() => copyWith(categories: []);
  RecipeFilter clearAreaFilter() => copyWith(areas: []);
  RecipeFilter clearTagFilter() => copyWith(tags: []);

  bool get hasFilters =>
      categories.isNotEmpty ||
      areas.isNotEmpty ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      tags.isNotEmpty;

  bool get isEmpty => !hasFilters;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeFilter) return false;
    return _listEquals(other.categories, categories) &&
        _listEquals(other.areas, areas) &&
        other.searchQuery == searchQuery &&
        _listEquals(other.tags, tags);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(categories, areas, searchQuery, tags);
}
