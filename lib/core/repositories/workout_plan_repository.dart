import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/plan_model.dart';

/// Workout Plan Repository - Quản lý các kế hoạch tập luyện
class WorkoutPlanRepository {
  final ApiClient _apiClient = ApiClient.instance;

  /// Lấy danh sách kế hoạch của người dùng (bao gồm cả exercises)
  Future<List<Plan>> getUserPlans({int languageId = 1}) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.plans,
        queryParameters: {'language_id': languageId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((e) => Plan.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting user plans: $e');
      rethrow;
    }
  }

  /// Lấy chi tiết một kế hoạch
  Future<Plan?> getPlanById(int planId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.plans}/$planId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return Plan.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting plan detail: $e');
      rethrow;
    }
  }

  /// Tạo kế hoạch mới
  Future<Plan?> createPlan(
    String name, {
    String? description,
    String? scheduleDays,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.plans,
        data: {
          'name': name,
          'plan_type': 'workout',
          'description': description,
          'schedule_days': ?scheduleDays,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return Plan.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error creating plan: $e');
      rethrow;
    }
  }

  /// Thêm bài tập vào kế hoạch
  Future<PlanDetail?> addPlanDetail({
    required int planId,
    required int exerciseId,
    int sets = 3,
    int reps = 10,
    int restDuration = 60,
    int orderIndex = 0,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.plans}/$planId/details',
        data: {
          'exercise_id': exerciseId,
          'sets': sets,
          'reps': reps,
          'rest_duration': restDuration,
          'order_index': orderIndex,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return PlanDetail.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error adding plan detail: $e');
      rethrow;
    }
  }

  /// Xóa chi tiết khỏi kế hoạch
  Future<bool> deletePlanDetail(int detailId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.plans}/details/$detailId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting plan detail: $e');
      rethrow;
    }
  }

  /// Cập nhật kế hoạch
  Future<bool> updatePlan(
    int planId, {
    String? name,
    String? description,
    String? scheduleDays,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.plans}/$planId',
        data: {
          'name': ?name,
          'description': ?description,
          'schedule_days': ?scheduleDays,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating plan: $e');
      rethrow;
    }
  }

  /// Xóa tất cả chi tiết của kế hoạch (dùng khi edit)
  Future<bool> clearPlanDetails(int planId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.plans}/$planId/details',
      );

      // 204 = No Content (success without body)
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error clearing plan details: $e');
      rethrow;
    }
  }

  /// Xóa kế hoạch
  Future<bool> deletePlan(int planId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.plans}/$planId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      rethrow;
    }
  }
}
