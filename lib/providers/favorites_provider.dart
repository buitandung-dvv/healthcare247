import 'package:flutter/foundation.dart';
import '../core/repositories/favorites_repository.dart';
import '../data/models/favorite_model.dart';

/// Favorites Provider - Quản lý thực phẩm và công thức yêu thích của người dùng
class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _repository;

  // Favorite Foods
  final List<FavoriteFood> _favoriteFoods = [];
  bool _isLoadingFoods = false;
  String? _foodsErrorMessage;
  int _foodsCurrentPage = 1;
  int _foodsTotalPages = 1;

  // Favorite Recipes
  final List<FavoriteRecipe> _favoriteRecipes = [];
  bool _isLoadingRecipes = false;
  String? _recipesErrorMessage;
  int _recipesCurrentPage = 1;
  int _recipesTotalPages = 1;

  // Loading state
  bool _isAddingToFavorites = false;
  bool _isRemovingFromFavorites = false;

  static const int itemsPerPage = 20;

  FavoritesProvider({FavoritesRepository? repository})
    : _repository = repository ?? FavoritesRepository();

  // Getters - Foods
  List<FavoriteFood> get favoriteFoods => _favoriteFoods;
  bool get isLoadingFoods => _isLoadingFoods;
  String? get foodsErrorMessage => _foodsErrorMessage;
  int get foodsCurrentPage => _foodsCurrentPage;
  int get foodsTotalPages => _foodsTotalPages;
  bool get hasPreviousFoodsPage => _foodsCurrentPage > 1;
  bool get hasNextFoodsPage => _foodsCurrentPage < _foodsTotalPages;

  // Getters - Recipes
  List<FavoriteRecipe> get favoriteRecipes => _favoriteRecipes;
  bool get isLoadingRecipes => _isLoadingRecipes;
  String? get recipesErrorMessage => _recipesErrorMessage;
  int get recipesCurrentPage => _recipesCurrentPage;
  int get recipesTotalPages => _recipesTotalPages;
  bool get hasPreviousRecipesPage => _recipesCurrentPage > 1;
  bool get hasNextRecipesPage => _recipesCurrentPage < _recipesTotalPages;

  // Getters - Loading states
  bool get isAddingToFavorites => _isAddingToFavorites;
  bool get isRemovingFromFavorites => _isRemovingFromFavorites;

  /// Load favorite foods - paginable
  Future<void> loadFavoriteFoods({int page = 1}) async {
    _isLoadingFoods = true;
    _foodsErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getFavoriteFoods(
        page: page,
        limit: itemsPerPage,
      );

      _favoriteFoods.clear();
      _favoriteFoods.addAll(result.items);
      _foodsCurrentPage = result.page;
      _foodsTotalPages = (result.totalCount / itemsPerPage).ceil();
      _isLoadingFoods = false;
      _foodsErrorMessage = null;
    } catch (e) {
      _isLoadingFoods = false;
      _foodsErrorMessage = 'Failed to load favorite foods: $e';
      if (kDebugMode) print(_foodsErrorMessage);
    }
    notifyListeners();
  }

  /// Load favorite recipes - paginable
  Future<void> loadFavoriteRecipes({int page = 1}) async {
    _isLoadingRecipes = true;
    _recipesErrorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getFavoriteRecipes(
        page: page,
        limit: itemsPerPage,
      );

      _favoriteRecipes.clear();
      _favoriteRecipes.addAll(result.items);
      _recipesCurrentPage = result.page;
      _recipesTotalPages = (result.totalCount / itemsPerPage).ceil();
      _isLoadingRecipes = false;
      _recipesErrorMessage = null;
    } catch (e) {
      _isLoadingRecipes = false;
      _recipesErrorMessage = 'Failed to load favorite recipes: $e';
      if (kDebugMode) print(_recipesErrorMessage);
    }
    notifyListeners();
  }

  /// Add food to favorites
  Future<bool> addFavoriteFood(int foodId, {String? notes}) async {
    _isAddingToFavorites = true;
    notifyListeners();

    try {
      final favorite = await _repository.addFavoriteFood(foodId, notes: notes);
      _favoriteFoods.insert(0, favorite);
      _isAddingToFavorites = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAddingToFavorites = false;
      _foodsErrorMessage = 'Failed to add favorite food: $e';
      if (kDebugMode) print(_foodsErrorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Add recipe to favorites
  Future<bool> addFavoriteRecipe(int recipeId, {String? notes}) async {
    _isAddingToFavorites = true;
    notifyListeners();

    try {
      final favorite = await _repository.addFavoriteRecipe(recipeId, notes: notes);
      _favoriteRecipes.insert(0, favorite);
      _isAddingToFavorites = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isAddingToFavorites = false;
      _recipesErrorMessage = 'Failed to add favorite recipe: $e';
      if (kDebugMode) print(_recipesErrorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Remove food from favorites
  Future<bool> removeFavoriteFood(int foodId) async {
    _isRemovingFromFavorites = true;
    notifyListeners();

    try {
      await _repository.removeFavoriteFood(foodId);
      _favoriteFoods.removeWhere((f) => f.foodId == foodId);
      _isRemovingFromFavorites = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isRemovingFromFavorites = false;
      _foodsErrorMessage = 'Failed to remove favorite food: $e';
      if (kDebugMode) print(_foodsErrorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Remove recipe from favorites
  Future<bool> removeFavoriteRecipe(int recipeId) async {
    _isRemovingFromFavorites = true;
    notifyListeners();

    try {
      await _repository.removeFavoriteRecipe(recipeId);
      _favoriteRecipes.removeWhere((r) => r.recipeId == recipeId);
      _isRemovingFromFavorites = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isRemovingFromFavorites = false;
      _recipesErrorMessage = 'Failed to remove favorite recipe: $e';
      if (kDebugMode) print(_recipesErrorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Check if food is favorite
  Future<bool> isFavoriteFoodAsync(int foodId) async {
    return await _repository.isFavoriteFood(foodId);
  }

  /// Check if recipe is favorite (from cache)
  bool isFavoriteFood(int foodId) {
    return _favoriteFoods.any((f) => f.foodId == foodId);
  }

  /// Check if recipe is favorite (async)
  Future<bool> isFavoriteRecipeAsync(int recipeId) async {
    return await _repository.isFavoriteRecipe(recipeId);
  }

  /// Check if recipe is favorite (from cache)
  bool isFavoriteRecipe(int recipeId) {
    return _favoriteRecipes.any((r) => r.recipeId == recipeId);
  }

  /// Next page of favorite foods
  Future<void> nextFoodsPage() async {
    if (hasNextFoodsPage) {
      await loadFavoriteFoods(page: _foodsCurrentPage + 1);
    }
  }

  /// Previous page of favorite foods
  Future<void> previousFoodsPage() async {
    if (hasPreviousFoodsPage) {
      await loadFavoriteFoods(page: _foodsCurrentPage - 1);
    }
  }

  /// Next page of favorite recipes
  Future<void> nextRecipesPage() async {
    if (hasNextRecipesPage) {
      await loadFavoriteRecipes(page: _recipesCurrentPage + 1);
    }
  }

  /// Previous page of favorite recipes
  Future<void> previousRecipesPage() async {
    if (hasPreviousRecipesPage) {
      await loadFavoriteRecipes(page: _recipesCurrentPage - 1);
    }
  }

  /// Refresh both favorite foods and recipes
  Future<void> refreshAll() async {
    await Future.wait([
      loadFavoriteFoods(page: 1),
      loadFavoriteRecipes(page: 1),
    ]);
  }

  /// Clear error message
  void clearErrorMessage() {
    _foodsErrorMessage = null;
    _recipesErrorMessage = null;
    notifyListeners();
  }
}
