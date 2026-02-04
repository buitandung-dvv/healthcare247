import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/goals_model.dart';

/// Goals Repository - Quản lý mục tiêu sức khỏe và thể hình của người dùng
class GoalsRepository {
  final ApiClient _apiClient;

  GoalsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Lấy mục tiêu của người dùng
  Future<UserGoals?> getUserGoals(int userId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.users}/$userId/goals',
      );

      if (response.data != null && response.data!['data'] != null) {
        return UserGoals.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user goals: $e');
    }
  }

  /// Cập nhật mục tiêu của người dùng
  Future<UserGoals?> updateUserGoals({
    required int userId,
    double? caloriesGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? waterGoalMl,
    int? workoutsPerWeek,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConfig.users}/$userId/goals',
        data: {
          if (caloriesGoal != null) 'calories_goal': caloriesGoal,
          if (proteinGoal != null) 'protein_goal': proteinGoal,
          if (carbsGoal != null) 'carbs_goal': carbsGoal,
          if (fatGoal != null) 'fat_goal': fatGoal,
          if (waterGoalMl != null) 'water_goal_ml': waterGoalMl,
          if (workoutsPerWeek != null) 'workouts_per_week': workoutsPerWeek,
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return UserGoals.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update user goals: $e');
    }
  }
}
