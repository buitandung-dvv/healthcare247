import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/exercise_model.dart';

/// Exercise Repository - Truy xuất dữ liệu Exercise từ Database
class ExerciseRepository {
  final ApiClient _apiClient;

  ExerciseRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Lấy danh sách exercises từ database
  /// [languageId]: 1 = English, 2 = Vietnamese
  /// [page]: Trang hiện tại
  /// [limit]: Số lượng mỗi trang
  /// [level]: Lọc theo level (beginner, intermediate, expert)
  /// [category]: Lọc theo category
  /// [equipment]: Lọc theo thiết bị
  /// [muscle]: Lọc theo nhóm cơ
  /// [search]: Tìm kiếm theo tên
  Future<PaginatedResponse<Exercise>> getExercises({
    int languageId = 1,
    int page = 1,
    int limit = 20,
    String? level,
    String? category,
    String? equipment,
    String? muscle,
    String? search,
  }) async {
    try {
      final queryParams = {
        ApiConfig.languageParam: languageId.toString(),
        ApiConfig.pageParam: page.toString(),
        ApiConfig.limitParam: limit.toString(),
        'level': ?level,
        'category': ?category,
        'equipment': ?equipment,
        'muscle': ?muscle,
        if (search != null && search.isNotEmpty) ApiConfig.searchParam: search,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.exercises,
        queryParameters: queryParams,
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => Exercise.fromJson(json),
        );
      }

      return PaginatedResponse<Exercise>(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: limit,
        hasMore: false,
      );
    } catch (e) {
      throw Exception('Failed to load exercises: $e');
    }
  }

  /// Lấy chi tiết exercise theo ID
  Future<Exercise?> getExerciseById(
    int exerciseId, {
    int languageId = 1,
  }) async {
    try {
      final path = ApiConfig.exerciseDetail.replaceAll(
        '{id}',
        exerciseId.toString(),
      );
      final response = await _apiClient.get<Map<String, dynamic>>(
        path,
        queryParameters: {ApiConfig.languageParam: languageId.toString()},
      );

      if (response.data != null && response.data!['data'] != null) {
        return Exercise.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load exercise detail: $e');
    }
  }

  /// Lấy danh sách muscles (cached for 1 hour)
  Future<List<Map<String, dynamic>>> getMuscles({int languageId = 1}) async {
    try {
      final response = await _apiClient.getCached<Map<String, dynamic>>(
        '${ApiConfig.exercises}/muscles',
        queryParameters: {ApiConfig.languageParam: languageId.toString()},
        cacheDuration: const Duration(hours: 1),
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load muscles: $e');
    }
  }

  /// Lấy danh sách equipment (cached for 1 hour)
  Future<List<String>> getEquipments() async {
    try {
      final response = await _apiClient.getCached<Map<String, dynamic>>(
        '${ApiConfig.exercises}/equipments',
        cacheDuration: const Duration(hours: 1),
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => e.toString())
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load equipments: $e');
    }
  }

  /// Lấy danh sách categories (cached for 1 hour)
  Future<List<String>> getCategories() async {
    try {
      final response = await _apiClient.getCached<Map<String, dynamic>>(
        '${ApiConfig.exercises}/categories',
        cacheDuration: const Duration(hours: 1),
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => e.toString())
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Tìm kiếm exercises
  Future<List<Exercise>> searchExercises(
    String query, {
    int languageId = 1,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.exercises}/search',
        queryParameters: {
          'q': query,
          ApiConfig.languageParam: languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search exercises: $e');
    }
  }

  /// Lấy exercises theo nhóm cơ
  Future<List<Exercise>> getExercisesByMuscle(
    String muscle, {
    int languageId = 1,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.exercises}/by-muscle/$muscle',
        queryParameters: {ApiConfig.languageParam: languageId.toString()},
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load exercises by muscle: $e');
    }
  }
}
