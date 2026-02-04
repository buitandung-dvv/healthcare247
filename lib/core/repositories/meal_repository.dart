import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/meal_model.dart';

/// Meal Tracking Repository - Quản lý việc ghi nhận bữa ăn
/// NOTE: Bảng Meals không còn tồn tại trong DB.
/// Repository này làm việc với MealTracking (log bữa ăn),
/// sử dụng Recipe và Food từ các tables tương ứng.
class MealTrackingRepository {
  final ApiClient _apiClient;

  MealTrackingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Lấy danh sách meal tracking của user theo ngày
  Future<List<MealTracking>> getUserMealTracking({
    required int userId,
    DateTime? date,
    String? mealType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (date != null) 'date': date.toIso8601String().split('T')[0],
        if (mealType != null) 'meal_type': mealType,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/meals/user/$userId',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data!['data'] != null) {
        final items = response.data!['data'];
        if (items is List) {
          return items
              .map((e) => MealTracking.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load meal tracking: $e');
    }
  }

  /// Log bữa ăn từ Recipe
  Future<MealTracking?> logMealFromRecipe({
    required int userId,
    required int recipeId,
    required String mealType,
    DateTime? date,
    String? notes,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double quantity = 100,
  }) async {
    try {
      final trackingDate = date ?? DateTime.now();
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.tracking}/meals',
        data: {
          'user_id': userId,
          'recipe_id': recipeId,
          'meal_type': mealType,
          'tracked_date': trackingDate.toIso8601String().split('T')[0],
          if (notes != null) 'notes': notes,
          if (calories != null) 'calories': calories,
          if (protein != null) 'protein': protein,
          if (carbs != null) 'carbs': carbs,
          if (fat != null) 'fat': fat,
          'quantity': quantity,
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return MealTracking.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to log meal from recipe: $e');
    }
  }

  /// Log bữa ăn từ Food
  Future<MealTracking?> logMealFromFood({
    required int userId,
    required int foodId,
    required String mealType,
    DateTime? date,
    String? notes,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double quantity = 100,
  }) async {
    try {
      final trackingDate = date ?? DateTime.now();
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.tracking}/meals',
        data: {
          'user_id': userId,
          'food_id': foodId,
          'meal_type': mealType,
          'tracked_date': trackingDate.toIso8601String().split('T')[0],
          if (notes != null) 'notes': notes,
          if (calories != null) 'calories': calories,
          if (protein != null) 'protein': protein,
          if (carbs != null) 'carbs': carbs,
          if (fat != null) 'fat': fat,
          'quantity': quantity,
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return MealTracking.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to log meal from food: $e');
    }
  }

  /// Log bữa ăn custom (không từ recipe/food)
  Future<MealTracking?> logCustomMeal({
    required int userId,
    required String mealType,
    required String mealName,
    DateTime? date,
    String? notes,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double quantity = 100,
  }) async {
    try {
      final trackingDate = date ?? DateTime.now();
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.tracking}/meals',
        data: {
          'user_id': userId,
          'meal_type': mealType,
          'meal_name': mealName,
          'tracked_date': trackingDate.toIso8601String().split('T')[0],
          if (notes != null) 'notes': notes,
          if (calories != null) 'calories': calories,
          if (protein != null) 'protein': protein,
          if (carbs != null) 'carbs': carbs,
          if (fat != null) 'fat': fat,
          'quantity': quantity,
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return MealTracking.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to log custom meal: $e');
    }
  }

  /// Xóa meal tracking entry
  Future<bool> deleteMealTracking({
    required int userId,
    required DateTime trackedDate,
    required String mealType,
    required DateTime createdAt,
  }) async {
    try {
      await _apiClient.delete(
        '${ApiConfig.tracking}/meals',
        queryParameters: {
          'user_id': userId.toString(),
          'tracked_date': trackedDate.toIso8601String().split('T')[0],
          'meal_type': mealType,
          'created_at': createdAt.toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      throw Exception('Failed to delete meal tracking: $e');
    }
  }

  /// Lấy tổng calories và macros trong ngày
  Future<Map<String, double>> getDailyNutritionSummary({
    required int userId,
    required DateTime date,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/meals/summary',
        queryParameters: {
          'user_id': userId.toString(),
          'date': date.toIso8601String().split('T')[0],
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return {
          'calories': (data['total_calories'] as num?)?.toDouble() ?? 0,
          'protein': (data['total_protein'] as num?)?.toDouble() ?? 0,
          'carbs': (data['total_carbs'] as num?)?.toDouble() ?? 0,
          'fat': (data['total_fat'] as num?)?.toDouble() ?? 0,
        };
      }
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    } catch (e) {
      // Return zeros if API fails
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }
  }
}
