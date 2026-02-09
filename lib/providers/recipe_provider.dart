import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/recipe_model.dart';
import '../core/repositories/recipe_repository.dart';

/// Recipe Provider - Quản lý công thức nấu ăn (Tối ưu hóa)
class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository;

  final List<Recipe> _recipes = [];
  Recipe? _selectedRecipe;
  RecipeFilter _filter = const RecipeFilter();
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;

  // Pagination - client side
  static const int itemsPerPage = 10;
  int _currentPage = 1;

  // Cache categories và areas từ database
  List<String> _categories = [];
  List<String> _areas = [];

  // Cache management
  bool _initialDataLoaded = false;
  int _cachedLanguageId = 1;

  // Debounce timer cho search
  Timer? _searchDebounce;

  // Cache cho filtered results
  List<Recipe>? _cachedFilteredRecipes;
  RecipeFilter? _lastFilterState;

  RecipeProvider({RecipeRepository? repository})
    : _repository = repository ?? RecipeRepository();

  /// Lazy load - only load if not already loaded
  Future<void> loadIfNeeded({int languageId = 1}) async {
    if (_initialDataLoaded && _cachedLanguageId == languageId) {
      debugPrint('⏭️ RecipeProvider.loadIfNeeded() - already loaded, skipping');
      return;
    }
    debugPrint('🔄 RecipeProvider.loadIfNeeded() - loading...');
    await loadInitialData(languageId: languageId);
    debugPrint('✅ RecipeProvider loaded');
  }

  /// Invalidate cache - force reload on next loadIfNeeded
  void invalidate() {
    _initialDataLoaded = false;
    debugPrint('🔄 RecipeProvider invalidated');
  }

  List<Recipe> get recipes => _recipes;
  Recipe? get selectedRecipe => _selectedRecipe;
  RecipeFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  List<String> get categories => _categories;
  List<String> get areas => _areas;

  // Pagination getters
  int get currentPage => _currentPage;
  int get totalPages => (filteredRecipes.length / itemsPerPage).ceil();
  bool get hasNextPage => _currentPage < totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  /// Lấy recipes cho trang hiện tại
  List<Recipe> get paginatedRecipes {
    final allFiltered = filteredRecipes;
    final startIndex = (_currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, allFiltered.length);

    if (startIndex >= allFiltered.length) return [];
    return allFiltered.sublist(startIndex, endIndex);
  }

  /// Chuyển đến trang tiếp theo
  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      notifyListeners();
    }
  }

  /// Quay lại trang trước
  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      notifyListeners();
    }
  }

  /// Chuyển đến trang cụ thể
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  /// Reset về trang 1
  void resetPagination() {
    _currentPage = 1;
  }

  /// Load danh sách recipes từ Database
  /// [languageId]: 1 = English, 2 = Vietnamese
  Future<void> loadRecipes({int languageId = 1, bool refresh = false}) async {
    if (refresh) {
      _recipes.clear();
    }

    // Nếu đã có dữ liệu và không refresh thì bỏ qua
    if (_recipes.isNotEmpty && !refresh) return;
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi API để lấy TOÀN BỘ dữ liệu từ database (không phân trang)
      final response = await _repository.getRecipes(
        languageId: languageId,
        page: 1,
        limit: 1000, // Load tất cả
      );

      _recipes.addAll(response.items);
      _hasMore = false; // Đã load hết
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load chi tiết recipe từ Database theo ID
  Future<void> loadRecipeDetail(int recipeId, {int languageId = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Kiểm tra cache trước
      final cachedRecipe =
          _recipes.where((r) => r.recipeId == recipeId).firstOrNull;

      if (cachedRecipe != null && cachedRecipe.ingredients.isNotEmpty) {
        // Đã có đầy đủ thông tin trong cache
        _selectedRecipe = cachedRecipe;
      } else {
        // Gọi API để lấy chi tiết từ database
        final recipe = await _repository.getRecipeById(
          recipeId,
          languageId: languageId,
        );
        _selectedRecipe = recipe;

        // Cập nhật cache nếu có
        if (recipe != null) {
          final index = _recipes.indexWhere((r) => r.recipeId == recipeId);
          if (index != -1) {
            _recipes[index] = recipe;
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load categories từ Database
  Future<void> loadCategories({int languageId = 1}) async {
    try {
      _categories = await _repository.getCategories(languageId: languageId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
      // Không throw exception, chỉ log lỗi
    }
  }

  /// Load areas từ Database
  Future<void> loadAreas({int languageId = 1}) async {
    try {
      _areas = await _repository.getAreas(languageId: languageId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load areas: $e');
      // Không throw exception, chỉ log lỗi
    }
  }

  /// Load tất cả dữ liệu cần thiết song song (với caching)
  Future<void> loadInitialData({int languageId = 1}) async {
    // Skip nếu đã load với cùng ngôn ngữ
    if (_initialDataLoaded &&
        _cachedLanguageId == languageId &&
        _recipes.isNotEmpty) {
      return;
    }

    // Clear error state
    _errorMessage = null;

    try {
      // Load tất cả song song để giảm thời gian chờ
      // NOTE: Không set _isLoading ở đây vì loadRecipes sẽ tự quản lý
      await Future.wait([
        loadRecipes(languageId: languageId, refresh: true),
        _loadCategoriesSilent(languageId: languageId),
        _loadAreasSilent(languageId: languageId),
      ], eagerError: false);

      _initialDataLoaded = true;
      _cachedLanguageId = languageId;
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load categories không notify (dùng cho parallel loading)
  Future<void> _loadCategoriesSilent({int languageId = 1}) async {
    try {
      _categories = await _repository.getCategories(languageId: languageId);
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  /// Load areas không notify (dùng cho parallel loading)
  Future<void> _loadAreasSilent({int languageId = 1}) async {
    try {
      _areas = await _repository.getAreas(languageId: languageId);
    } catch (e) {
      debugPrint('Failed to load areas: $e');
    }
  }

  /// Tìm kiếm recipes trong Database
  Future<List<Recipe>> searchRecipes(String query, {int languageId = 1}) async {
    try {
      return await _repository.searchRecipes(query, languageId: languageId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void setFilter(RecipeFilter newFilter, {int languageId = 1}) {
    _filter = newFilter;
    _invalidateFilterCache();
    resetPagination(); // Reset về trang 1 khi filter thay đổi
    notifyListeners();
  }

  void clearFilter() {
    _filter = const RecipeFilter();
    _invalidateFilterCache();
    resetPagination(); // Reset về trang 1
    notifyListeners();
  }

  /// Cập nhật search với debounce
  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateFilterCache();
      resetPagination(); // Reset về trang 1 khi search
      notifyListeners();
    });
  }

  void _invalidateFilterCache() {
    _cachedFilteredRecipes = null;
    _lastFilterState = null;
  }

  /// Filter recipes locally (với caching)
  List<Recipe> get filteredRecipes {
    if (_cachedFilteredRecipes != null && _lastFilterState == _filter) {
      return _cachedFilteredRecipes!;
    }

    _cachedFilteredRecipes = _computeFilteredRecipes();
    _lastFilterState = _filter;
    return _cachedFilteredRecipes!;
  }

  List<Recipe> _computeFilteredRecipes() {
    if (!_filter.hasFilters) return _recipes;

    final query = _filter.searchQuery?.toLowerCase();

    return _recipes.where((recipe) {
      // Category filter - recipe phải match một trong các categories được chọn
      if (_filter.categories.isNotEmpty &&
          !_filter.categories.contains(recipe.category)) {
        return false;
      }
      // Area filter - recipe phải match một trong các areas được chọn
      if (_filter.areas.isNotEmpty && !_filter.areas.contains(recipe.area)) {
        return false;
      }
      // Search query
      if (query != null && query.isNotEmpty) {
        if (!recipe.name.toLowerCase().contains(query) &&
            !recipe.instructionsText.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reload all data for new language
  Future<void> reloadForLanguage(int languageId) async {
    // Clear all cached data
    _recipes.clear();
    _categories.clear();
    _areas.clear();
    _initialDataLoaded = false;
    _cachedLanguageId = languageId;
    _hasMore = true;
    _cachedFilteredRecipes = null;
    _lastFilterState = null;

    // Reload all data
    await loadInitialData(languageId: languageId);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
