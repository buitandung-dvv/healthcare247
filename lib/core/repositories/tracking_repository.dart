import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/tracking_model.dart';

/// Tracking Repository - Quản lý theo dõi tập luyện và ăn uống
class TrackingRepository {
  final ApiClient _apiClient;

  TrackingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  // ==================== EXERCISE TRACKING ====================

  /// Ghi nhận bài tập
  Future<ExerciseTracking?> logExercise({
    required int userId,
    required int exerciseId,
    int? duration,
    int? sets,
    int? reps,
    double? weight,
    double? caloriesBurned,
    String? notes,
    DateTime? trackedAt,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.tracking}/exercises',
        data: {
          'user_id': userId,
          'exercise_id': exerciseId,
          'duration': duration,
          'sets': sets,
          'reps': reps,
          'weight': weight,
          'calories_burned': caloriesBurned,
          'notes': notes,
          'tracked_at': (trackedAt ?? DateTime.now()).toIso8601String(),
        },
      );

      if (response.data != null) {
        return ExerciseTracking.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to log exercise: $e');
    }
  }

  /// Lấy lịch sử tập luyện
  Future<List<ExerciseTracking>> getExerciseHistory({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = {
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/exercises',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => ExerciseTracking.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get exercise history: $e');
    }
  }

  // ==================== MEAL TRACKING ====================

  /// Ghi nhận bữa ăn
  Future<MealTracking?> logMeal({
    required int userId,
    int? mealId,
    String? mealType,
    String? mealName,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? notes,
    double? quantity,
    DateTime? trackedAt,
  }) async {
    try {
      debugPrint(
        '📤 [Repository] logMeal: $mealType - $mealName (${quantity}g)',
      );

      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.tracking}/meals',
        data: {
          'user_id': userId,
          'meal_id': mealId,
          'meal_type': mealType,
          'meal_name': mealName,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'notes': notes,
          'quantity': quantity ?? 100,
          'tracked_at': (trackedAt ?? DateTime.now()).toIso8601String(),
        },
      );

      debugPrint('📥 [Repository] logMeal response: ${response.data}');

      if (response.data != null && response.data!['data'] != null) {
        return MealTracking.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Repository] logMeal error: $e');
      throw Exception('Failed to log meal: $e');
    }
  }

  /// Lấy lịch sử ăn uống
  Future<List<MealTracking>> getMealHistory({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = {
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        if (limit != null) 'limit': limit.toString(),
      };

      debugPrint('🍽️ getMealHistory: params=$queryParams');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/meals',
        queryParameters: queryParams,
      );

      debugPrint('🍽️ getMealHistory response: ${response.data}');

      if (response.data != null && response.data!['data'] != null) {
        final list =
            (response.data!['data'] as List)
                .map((e) => MealTracking.fromJson(e as Map<String, dynamic>))
                .toList();
        debugPrint('✅ Parsed ${list.length} meal entries');
        return list;
      }
      debugPrint('⚠️ No meal data in response');
      return [];
    } catch (e) {
      debugPrint('❌ Get meal history error: $e');
      throw Exception('Failed to get meal history: $e');
    }
  }

  // ==================== DAILY PROGRESS ====================

  /// Lấy tiến độ hàng ngày (bao gồm goals từ User_Goals table)
  Future<DailyProgress?> getDailyProgress({
    required int userId,
    required DateTime date,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/stats/daily',
        queryParameters: {'date': date.toIso8601String().split('T')[0]},
      );

      if (response.data != null && response.data!['data'] != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return DailyProgress(
          date: date,
          // Actual nutrition data from backend
          caloriesConsumed:
              (data['totalCaloriesConsumed'] as num?)?.toDouble() ?? 0,
          caloriesBurned:
              (data['totalCaloriesBurned'] as num?)?.toDouble() ?? 0,
          protein: (data['totalProtein'] as num?)?.toDouble() ?? 0,
          carbs: (data['totalCarbs'] as num?)?.toDouble() ?? 0,
          fat: (data['totalFat'] as num?)?.toDouble() ?? 0,
          workoutsCompleted: data['exercisesCompleted'] as int? ?? 0,
          mealsLogged: data['mealsLogged'] as int? ?? 0,
          // Goals từ User_Goals table
          caloriesGoal: (data['calories_goal'] as num?)?.toDouble() ?? 2000,
          proteinGoal: (data['protein_goal'] as num?)?.toDouble() ?? 150,
          carbsGoal: (data['carbs_goal'] as num?)?.toDouble() ?? 250,
          fatGoal: (data['fat_goal'] as num?)?.toDouble() ?? 65,
          workoutsPlanned: data['workouts_per_week'] as int? ?? 3,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get daily progress: $e');
    }
  }

  /// Lấy tiến độ tuần
  Future<List<DailyProgress>> getWeeklyProgress({
    required int userId,
    DateTime? startDate,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/stats/weekly',
      );

      if (response.data != null && response.data!['data'] != null) {
        final items = response.data!['data'] as List;
        return items.map((e) {
          final data = e as Map<String, dynamic>;
          return DailyProgress(
            date: DateTime.parse(data['date'].toString()),
            caloriesConsumed:
                (data['caloriesConsumed'] as num?)?.toDouble() ?? 0,
            caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0,
            protein: (data['protein'] as num?)?.toDouble() ?? 0,
            carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
            fat: (data['fat'] as num?)?.toDouble() ?? 0,
            workoutsCompleted: data['exercisesCompleted'] as int? ?? 0,
            mealsLogged: data['mealsLogged'] as int? ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get weekly progress: $e');
    }
  }

  // ==================== WEIGHT TRACKING ====================

  /// Ghi nhận cân nặng
  Future<WeightTracking?> logWeight({
    required int userId,
    required double weight,
    String? notes,
    DateTime? trackedAt,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.tracking}/weight',
        data: {
          'weight': weight,
          'notes': notes,
          'tracked_at': (trackedAt ?? DateTime.now()).toIso8601String(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return WeightTracking.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to log weight: $e');
    }
  }

  /// Lấy lịch sử cân nặng
  Future<List<WeightTracking>> getWeightHistory({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = {
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/weight',
        queryParameters: queryParams,
      );

      debugPrint('📦 Weight API response: ${response.data}');

      if (response.data != null && response.data!['data'] != null) {
        final list =
            (response.data!['data'] as List)
                .map((e) => WeightTracking.fromJson(e as Map<String, dynamic>))
                .toList();
        debugPrint('✅ Parsed ${list.length} weight entries');
        return list;
      }
      debugPrint('⚠️ No weight data in response');
      return [];
    } catch (e) {
      debugPrint('❌ Weight history error: $e');
      throw Exception('Failed to get weight history: $e');
    }
  }

  // ==================== WATER TRACKING ====================

  /// Ghi nhận lượng nước uống
  Future<WaterTracking?> logWater({
    required int userId,
    required int amountMl,
    String? notes,
    DateTime? trackedAt,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.tracking}/water',
        data: {
          'amount_ml': amountMl,
          'notes': notes,
          'tracked_at': (trackedAt ?? DateTime.now()).toIso8601String(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return WaterTracking.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Log water error: $e');
      throw Exception('Failed to log water: $e');
    }
  }

  /// Lấy lịch sử uống nước
  Future<List<WaterTracking>> getWaterHistory({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final queryParams = {
        if (startDate != null)
          'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null)
          'end_date': endDate.toIso8601String().split('T')[0],
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/water',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => WaterTracking.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Water history error: $e');
      throw Exception('Failed to get water history: $e');
    }
  }

  /// Lấy tổng lượng nước uống hôm nay
  Future<DailyWaterIntake?> getDailyWaterIntake({
    required int userId,
    DateTime? date,
  }) async {
    try {
      final queryParams = {
        if (date != null) 'date': date.toIso8601String().split('T')[0],
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.tracking}/water/daily',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data!['data'] != null) {
        return DailyWaterIntake.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Daily water intake error: $e');
      throw Exception('Failed to get daily water intake: $e');
    }
  }

  /// Xóa entry nước uống
  Future<bool> deleteWaterEntry({required int trackingId}) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '${ApiConfig.tracking}/water/$trackingId',
      );

      return response.data?['success'] == true;
    } catch (e) {
      debugPrint('❌ Delete water entry error: $e');
      throw Exception('Failed to delete water entry: $e');
    }
  }
}
