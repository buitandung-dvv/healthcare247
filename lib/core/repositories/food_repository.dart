import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/meal_model.dart';

/// Food Repository - Quản lý thực phẩm từ Database
class FoodRepository {
  final ApiClient _apiClient;

  FoodRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Lấy danh sách foods
  Future<PaginatedResponse<Food>> getFoods({
    int languageId = 1,
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = {
        ApiConfig.languageParam: languageId.toString(),
        ApiConfig.pageParam: page.toString(),
        ApiConfig.limitParam: limit.toString(),
        if (category != null) 'category': category,
        if (search != null && search.isNotEmpty) ApiConfig.searchParam: search,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.foods,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => Food.fromJson(json),
        );
      }

      return PaginatedResponse<Food>(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: limit,
        hasMore: false,
      );
    } catch (e) {
      throw Exception('Failed to load foods: $e');
    }
  }

  /// Lấy chi tiết food theo ID
  Future<Food?> getFoodById(int foodId, {int languageId = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.foods}/$foodId',
        queryParameters: {ApiConfig.languageParam: languageId.toString()},
      );

      if (response.data != null && response.data!['data'] != null) {
        return Food.fromJson(response.data!['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load food detail: $e');
    }
  }

  /// Tìm kiếm foods
  Future<List<Food>> searchFoods(String query, {int languageId = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.foods}/search',
        queryParameters: {
          'q': query,
          ApiConfig.languageParam: languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => Food.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search foods: $e');
    }
  }

  /// Lấy categories
  Future<List<String>> getCategories({int languageId = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.foods}/categories',
        queryParameters: {ApiConfig.languageParam: languageId.toString()},
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
}
