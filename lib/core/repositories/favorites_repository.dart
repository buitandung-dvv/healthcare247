import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/favorite_model.dart';

/// Favorites Repository - Manage user favorite foods and recipes
class FavoritesRepository {
  final ApiClient _apiClient;

  FavoritesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  // Base endpoints
  static const String _favoritesFood = '/favorites/foods';
  static const String _favoritesRecipes = '/favorites/recipes';

  /// Get user's favorite foods
  Future<PaginatedResponse<FavoriteFood>> getFavoriteFoods({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        _favoritesFood,
        queryParameters: {
          ApiConfig.pageParam: page.toString(),
          ApiConfig.limitParam: limit.toString(),
        },
      );

      if (response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => FavoriteFood.fromJson(json),
        );
      }

      return PaginatedResponse<FavoriteFood>(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: limit,
        hasMore: false,
      );
    } catch (e) {
      throw Exception('Failed to load favorite foods: $e');
    }
  }

  /// Get user's favorite recipes
  Future<PaginatedResponse<FavoriteRecipe>> getFavoriteRecipes({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        _favoritesRecipes,
        queryParameters: {
          ApiConfig.pageParam: page.toString(),
          ApiConfig.limitParam: limit.toString(),
        },
      );

      if (response.data != null) {
        return PaginatedResponse.fromJson(
          response.data!,
          (json) => FavoriteRecipe.fromJson(json),
        );
      }

      return PaginatedResponse<FavoriteRecipe>(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: limit,
        hasMore: false,
      );
    } catch (e) {
      throw Exception('Failed to load favorite recipes: $e');
    }
  }

  /// Add food to favorites
  Future<FavoriteFood> addFavoriteFood(int foodId, {String? notes}) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        _favoritesFood,
        data: {'food_id': foodId, if (notes != null) 'notes': notes},
      );

      if (response.data != null && response.data!['data'] != null) {
        return FavoriteFood.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to add favorite food: $e');
    }
  }

  /// Add recipe to favorites
  Future<FavoriteRecipe> addFavoriteRecipe(
    int recipeId, {
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        _favoritesRecipes,
        data: {'recipe_id': recipeId, if (notes != null) 'notes': notes},
      );

      if (response.data != null && response.data!['data'] != null) {
        return FavoriteRecipe.fromJson(
          response.data!['data'] as Map<String, dynamic>,
        );
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to add favorite recipe: $e');
    }
  }

  /// Remove food from favorites
  Future<void> removeFavoriteFood(int foodId) async {
    try {
      await _apiClient.delete('$_favoritesFood/$foodId');
    } catch (e) {
      throw Exception('Failed to remove favorite food: $e');
    }
  }

  /// Remove recipe from favorites
  Future<void> removeFavoriteRecipe(int recipeId) async {
    try {
      await _apiClient.delete('$_favoritesRecipes/$recipeId');
    } catch (e) {
      throw Exception('Failed to remove favorite recipe: $e');
    }
  }

  /// Check if food is favorite
  Future<bool> isFavoriteFood(int foodId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '$_favoritesFood/$foodId',
      );
      return response.data != null && response.data!['data'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if recipe is favorite
  Future<bool> isFavoriteRecipe(int recipeId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '$_favoritesRecipes/$recipeId',
      );
      return response.data != null && response.data!['data'] != null;
    } catch (e) {
      return false;
    }
  }
}
