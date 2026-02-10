import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

import '../../data/models/workout_session_model.dart';

/// Workout Session Repository - Quản lý buổi tập
class WorkoutSessionRepository {
  final ApiClient _apiClient = ApiClient.instance;
  static const String _enpoint = '/workout-sessions';

  /// Bắt đầu buổi tập mới
  Future<WorkoutSession?> startSession({
    int? planId,
    int? exerciseId,
    String? name,
  }) async {
    try {
      final response = await _apiClient.post(
        _enpoint,
        data: {'plan_id': planId, 'exercise_id': exerciseId, 'name': name},
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return WorkoutSession.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  /// Lấy buổi tập đang diễn ra
  Future<WorkoutSession?> getActiveSession() async {
    try {
      final response = await _apiClient.get('$_enpoint/active');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return WorkoutSession.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting active session: $e');
      // Không rethrow để không chặn UI nếu lỗi mạng, chỉ return null
      return null;
    }
  }

  /// Lấy chi tiết buổi tập
  Future<WorkoutSession?> getSessionById(int sessionId) async {
    try {
      final response = await _apiClient.get('$_enpoint/$sessionId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return WorkoutSession.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting session details: $e');
      rethrow;
    }
  }

  /// Cập nhật tiến độ bài tập
  Future<WorkoutSessionDetail?> updateExerciseProgress({
    required int sessionId,
    required int exerciseId,
    required int setsCompleted,
    String? repsCompleted,
    String? weightUsed,
    String? notes,
    int? orderIndex,
    DateTime? startedAt,
    DateTime? completedAt,
  }) async {
    try {
      // VERSION MARKER
      debugPrint('🔥🔥🔥 REPOSITORY VERSION 2.0 🔥🔥🔥');
      debugPrint('📤 PARAMS: orderIndex=$orderIndex, startedAt=$startedAt, completedAt=$completedAt');

      // Build request data, only include timing fields if they have values
      final Map<String, dynamic> requestData = {
        'sets_completed': setsCompleted,
        'reps_completed': repsCompleted,
        'weight_used': weightUsed,
        'notes': notes,
        'order_index': orderIndex,
      };

      // Only add timing fields if they have values
      if (startedAt != null) {
        requestData['started_at'] = startedAt.toIso8601String();
      }
      if (completedAt != null) {
        requestData['completed_at'] = completedAt.toIso8601String();
      }

      debugPrint('📤 FINAL REQUEST DATA: $requestData');

      final response = await _apiClient.put(
        '$_enpoint/$sessionId/exercises/$exerciseId',
        data: requestData,
      );

      debugPrint('📥 API Response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return WorkoutSessionDetail.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error updating progress: $e');
      rethrow;
    }
  }

  /// Hoàn thành buổi tập
  Future<WorkoutSession?> completeSession(
    int sessionId, {
    String? notes,
    int? totalDurationSeconds,
  }) async {
    try {
      debugPrint('📤 Completing session $sessionId with duration: ${totalDurationSeconds}s');

      final response = await _apiClient.put(
        '$_enpoint/$sessionId/complete',
        data: {
          'notes': notes,
          'total_duration': totalDurationSeconds,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return WorkoutSession.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error completing session: $e');
      rethrow;
    }
  }

  /// Hủy buổi tập
  Future<bool> cancelSession(int sessionId) async {
    try {
      final response = await _apiClient.post('$_enpoint/$sessionId/cancel');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error cancelling session: $e');
      rethrow;
    }
  }

  /// Lấy lịch sử tập luyện
  Future<List<WorkoutSession>> getSessionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '$_enpoint/history',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting history: $e');
      rethrow;
    }
  }
}
