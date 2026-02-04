import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/plan_model.dart';

/// Plan Repository - Quản lý kế hoạch tập luyện và ăn uống
class PlanRepository {
  final ApiClient _apiClient;

  PlanRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Lấy danh sách plans của user
  Future<List<Plan>> getUserPlans({
    required int userId,
    String? planType,
  }) async {
    try {
      final queryParams = {
        if (planType != null) 'plan_type': planType,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.plans}/user/$userId',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data!['items'] != null) {
        return (response.data!['items'] as List)
            .map((e) => Plan.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get user plans: $e');
    }
  }

  /// Lấy chi tiết plan theo ID
  Future<Plan?> getPlanById(int planId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.plans}/$planId',
      );

      if (response.data != null) {
        return Plan.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get plan detail: $e');
    }
  }

  /// Tạo plan mới
  Future<Plan?> createPlan({
    required int userId,
    required String planType,
    String? description,
    List<PlanDetail>? details,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.plans,
        data: {
          'user_id': userId,
          'plan_type': planType,
          'description': description,
          'details': details?.map((e) => e.toJson()).toList(),
        },
      );

      if (response.data != null) {
        return Plan.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to create plan: $e');
    }
  }

  /// Cập nhật plan
  Future<Plan?> updatePlan({
    required int planId,
    String? planType,
    String? description,
    List<PlanDetail>? details,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConfig.plans}/$planId',
        data: {
          if (planType != null) 'plan_type': planType,
          if (description != null) 'description': description,
          if (details != null) 'details': details.map((e) => e.toJson()).toList(),
        },
      );

      if (response.data != null) {
        return Plan.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to update plan: $e');
    }
  }

  /// Xóa plan
  Future<bool> deletePlan(int planId) async {
    try {
      await _apiClient.delete('${ApiConfig.plans}/$planId');
      return true;
    } catch (e) {
      throw Exception('Failed to delete plan: $e');
    }
  }

  /// Thêm detail vào plan
  Future<PlanDetail?> addPlanDetail({
    required int planId,
    required int dayOfWeek,
    int? exerciseId,
    int? mealId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.plans}/$planId/details',
        data: {
          'day_of_week': dayOfWeek,
          'exercise_id': exerciseId,
          'meal_id': mealId,
        },
      );

      if (response.data != null) {
        return PlanDetail.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to add plan detail: $e');
    }
  }

  /// Xóa detail khỏi plan
  Future<bool> removePlanDetail(int planId, int detailId) async {
    try {
      await _apiClient.delete('${ApiConfig.plans}/$planId/details/$detailId');
      return true;
    } catch (e) {
      throw Exception('Failed to remove plan detail: $e');
    }
  }
}

