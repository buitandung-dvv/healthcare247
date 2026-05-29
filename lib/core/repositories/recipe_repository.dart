import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/recipe_model.dart';

/// Recipe Repository - Truy xuất dữ liệu Recipe từ Database
class RecipeRepository {
  final ApiClient _apiClient;

  RecipeRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Lấy danh sách recipes từ database
  /// [languageId]: 1 = English, 2 = Vietnamese
  /// [page]: Trang hiện tại
  /// [limit]: Số lượng mỗi trang
  /// [category]: Lọc theo category
  /// [area]: Lọc theo vùng miền
  /// [search]: Tìm kiếm theo tên
  Future<PaginatedResponse<Recipe>> getRecipes({
    int languageId = 1,
    int page = 1,
    int limit = 20,
    String? category,
    String? area,
    String? search,
  }) async {
    try {
      final queryParams = {
        ApiConfig.languageParam: languageId.toString(),
        ApiConfig.pageParam: page.toString(),
        ApiConfig.limitParam: limit.toString(),
        'category': ?category,
        'area': ?area,
        if (search != null && search.isNotEmpty) ApiConfig.searchParam: search,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConfig.recipes,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => Recipe.fromJson(json),
        );
      }

      return PaginatedResponse<Recipe>(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: limit,
        hasMore: false,
      );
    } catch (e) {
      throw Exception('Failed to load recipes: $e');
    }
  }

  /// Lấy chi tiết recipe theo ID
  Future<Recipe?> getRecipeById(int recipeId, {int languageId = 1}) async {
    try {
      final path = ApiConfig.recipeDetail.replaceAll('{id}', recipeId.toString());
      final response = await _apiClient.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          ApiConfig.languageParam: languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return Recipe.fromJson(response.data!['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load recipe detail: $e');
    }
  }

  /// Lấy danh sách categories
  Future<List<String>> getCategories({int languageId = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.recipes}/categories',
        queryParameters: {
          ApiConfig.languageParam: languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  /// Lấy danh sách areas/regions
  Future<List<String>> getAreas({int languageId = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.recipes}/areas',
        queryParameters: {
          ApiConfig.languageParam: languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load areas: $e');
    }
  }

  /// Tìm kiếm recipes
  Future<List<Recipe>> searchRecipes(String query, {int languageId = 1}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.recipes}/search',
        queryParameters: {
          'q': query,
          ApiConfig.languageParam: languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        return (response.data!['data'] as List)
            .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search recipes: $e');
    }
  }
}

