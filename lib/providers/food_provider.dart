import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/meal_model.dart';
import '../core/repositories/food_repository.dart';

/// Food Filter - Bộ lọc cho thực phẩm
class FoodFilter {
  final Set<String> categories;
  final String? searchQuery;

  const FoodFilter({this.categories = const {}, this.searchQuery});

  bool get hasFilters =>
      categories.isNotEmpty || (searchQuery?.isNotEmpty ?? false);

  FoodFilter copyWith({Set<String>? categories, String? searchQuery}) {
    return FoodFilter(
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  FoodFilter toggleCategory(String category) {
    final newCategories = Set<String>.from(categories);
    if (newCategories.contains(category)) {
      newCategories.remove(category);
    } else {
      newCategories.add(category);
    }
    return copyWith(categories: newCategories);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodFilter &&
        setEquals(other.categories, categories) &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => categories.hashCode ^ searchQuery.hashCode;
}

/// Food Provider - Quản lý thực phẩm (giống ExerciseProvider)
class FoodProvider extends ChangeNotifier {
  final FoodRepository _repository;

  final List<Food> _foods = [];
  FoodFilter _filter = const FoodFilter();
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination - client side
  static const int itemsPerPage = 15;
  int _currentPage = 1;

  // Cache cho categories
  List<String> _categories = [];
  bool _categoriesLoaded = false;
  int _cachedLanguageId = 1;

  // Debounce timer cho search
  Timer? _searchDebounce;

  // Cache cho filtered results
  List<Food>? _cachedFilteredFoods;
  FoodFilter? _lastFilterState;

  FoodProvider({FoodRepository? repository})
    : _repository = repository ?? FoodRepository();

  // Lazy loading flag
  bool _isLoaded = false;

  /// Lazy load - only load if not already loaded
  Future<void> loadIfNeeded({int languageId = 1}) async {
    if (_isLoaded && _cachedLanguageId == languageId) {
      debugPrint('⏭️ FoodProvider.loadIfNeeded() - already loaded, skipping');
      return;
    }
    debugPrint('🔄 FoodProvider.loadIfNeeded() - loading...');
    await Future.wait([
      loadFoods(languageId: languageId),
      loadCategories(languageId: languageId),
    ]);
    _isLoaded = true;
    debugPrint('✅ FoodProvider loaded');
  }

  /// Invalidate cache - force reload on next loadIfNeeded
  void invalidate() {
    _isLoaded = false;
    debugPrint('🔄 FoodProvider invalidated');
  }

  List<Food> get foods => _foods;
  FoodFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get categories => _categories;

  // Pagination getters
  int get currentPage => _currentPage;
  int get totalPages => (filteredFoods.length / itemsPerPage).ceil();
  bool get hasNextPage => _currentPage < totalPages;
  bool get hasPreviousPage => _currentPage > 1;
  int get totalFilteredCount => filteredFoods.length;

  /// Lấy foods cho trang hiện tại
  List<Food> get paginatedFoods {
    final allFiltered = filteredFoods;
    final startIndex = (_currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, allFiltered.length);

    if (startIndex >= allFiltered.length) return [];
    return allFiltered.sublist(startIndex, endIndex);
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

  /// Load danh sách foods từ Database
  Future<void> loadFoods({int languageId = 1, bool refresh = false}) async {
    if (refresh) {
      _foods.clear();
      _cachedFilteredFoods = null;
      _lastFilterState = null;
    }

    // Nếu đã có dữ liệu và không refresh thì bỏ qua
    if (_foods.isNotEmpty && !refresh) return;
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load toàn bộ foods (cho phép filter local)
      final response = await _repository.getFoods(
        languageId: languageId,
        page: 1,
        limit: 10000, // Load all foods
      );

      _foods.addAll(response.items);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load categories từ Database
  Future<void> loadCategories({int languageId = 1}) async {
    // Skip nếu đã load với cùng ngôn ngữ
    if (_categoriesLoaded && _cachedLanguageId == languageId) {
      return;
    }

    try {
      _categories = await _repository.getCategories(languageId: languageId);
      _categoriesLoaded = true;
      _cachedLanguageId = languageId;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  void setFilter(FoodFilter newFilter, {int languageId = 1}) {
    _filter = newFilter;
    _invalidateFilterCache();
    resetPagination();
    notifyListeners();
  }

  void clearFilter() {
    _filter = const FoodFilter();
    _invalidateFilterCache();
    resetPagination();
    notifyListeners();
  }

  /// Cập nhật search với debounce
  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateFilterCache();
      resetPagination();
      notifyListeners();
    });
  }

  /// Invalidate filter cache
  void _invalidateFilterCache() {
    _cachedFilteredFoods = null;
    _lastFilterState = null;
  }

  /// Filter foods locally (với caching)
  List<Food> get filteredFoods {
    // Trả về cache nếu filter không đổi
    if (_cachedFilteredFoods != null && _lastFilterState == _filter) {
      return _cachedFilteredFoods!;
    }

    // Tính toán filter mới
    _cachedFilteredFoods = _computeFilteredFoods();
    _lastFilterState = _filter;
    return _cachedFilteredFoods!;
  }

  /// Tính toán filtered foods
  List<Food> _computeFilteredFoods() {
    if (!_filter.hasFilters) return _foods;

    final query = _filter.searchQuery?.toLowerCase();

    return _foods.where((food) {
      // Category filter - food phải match một trong các categories được chọn
      if (_filter.categories.isNotEmpty) {
        final foodCategory = food.categoryName ?? '';
        final hasMatchingCategory = _filter.categories.any((category) {
          // Match exact, subcategory, or parent category
          // e.g., filter "Rau củ" matches "Rau củ" and "Rau củ/Chế biến"
          // e.g., filter "Rau củ/Chế biến" matches "Rau củ/Chế biến" only
          return foodCategory == category ||
              foodCategory.startsWith('$category/') ||
              category.startsWith('$foodCategory/');
        });
        if (!hasMatchingCategory) {
          return false;
        }
      }
      // Search query
      if (query != null && query.isNotEmpty) {
        if (!food.name.toLowerCase().contains(query)) {
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
    _foods.clear();
    _categories.clear();
    _categoriesLoaded = false;
    _cachedLanguageId = languageId;
    _cachedFilteredFoods = null;
    _lastFilterState = null;

    await Future.wait([
      loadFoods(languageId: languageId, refresh: true),
      loadCategories(languageId: languageId),
    ]);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
