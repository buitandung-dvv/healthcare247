import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/exercise_model.dart';
import '../core/repositories/exercise_repository.dart';

/// Exercise Provider - Quản lý bài tập (Tối ưu hóa)
class ExerciseProvider extends ChangeNotifier {
  final ExerciseRepository _repository;

  final List<Exercise> _exercises = [];
  Exercise? _selectedExercise;
  ExerciseFilter _filter = const ExerciseFilter();
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;

  // Pagination - client side
  static const int itemsPerPage = 10;
  int _currentPage = 1;

  // Cache từ database
  final List<String> _levels = ['beginner', 'intermediate', 'expert'];
  List<String> _categories = [];
  List<String> _equipments = [];
  List<Map<String, dynamic>> _muscles = [];

  // Cache management
  bool _filterOptionsLoaded = false;
  int _cachedLanguageId = 1;

  // Debounce timer cho search
  Timer? _searchDebounce;

  // Cache cho filtered results
  List<Exercise>? _cachedFilteredExercises;
  ExerciseFilter? _lastFilterState;

  ExerciseProvider({ExerciseRepository? repository})
    : _repository = repository ?? ExerciseRepository();

  List<Exercise> get exercises => _exercises;
  Exercise? get selectedExercise => _selectedExercise;
  ExerciseFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // Pagination getters
  int get currentPage => _currentPage;
  int get totalPages => (filteredExercises.length / itemsPerPage).ceil();
  bool get hasNextPage => _currentPage < totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  /// Lấy exercises cho trang hiện tại
  List<Exercise> get paginatedExercises {
    final allFiltered = filteredExercises;
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

  // Getters cho filter options - ưu tiên từ API, fallback từ exercises đã load
  List<String> get levels => _levels;

  List<String> get categories {
    if (_categories.isNotEmpty) return _categories;
    // Extract từ exercises đã load
    final extracted =
        _exercises.map((e) => e.category).toSet().toList()..sort();
    return extracted;
  }

  List<String> get equipments {
    if (_equipments.isNotEmpty) return _equipments;
    // Extract từ exercises đã load
    final extracted =
        _exercises
            .where((e) => e.equipment != null)
            .map((e) => e.equipment!)
            .toSet()
            .toList()
          ..sort();
    return extracted;
  }

  List<Map<String, dynamic>> get muscles {
    if (_muscles.isNotEmpty) return _muscles;
    // Extract từ exercises đã load
    final muscleSet = <String>{};
    for (final e in _exercises) {
      muscleSet.addAll(e.primaryMuscles);
      muscleSet.addAll(e.secondaryMuscles);
    }
    final sortedMuscles = muscleSet.toList()..sort();
    return sortedMuscles.map((m) => {'name': m}).toList();
  }

  /// Load danh sách exercises từ Database
  /// [languageId]: 1 = English, 2 = Vietnamese
  Future<void> loadExercises({int languageId = 1, bool refresh = false}) async {
    // Auto-refresh if language changed
    if (_cachedLanguageId != languageId && _exercises.isNotEmpty) {
      refresh = true;
    }

    if (refresh) {
      _exercises.clear();
      _cachedLanguageId = languageId;
    }

    // Nếu đã có dữ liệu và không refresh thì bỏ qua
    if (_exercises.isNotEmpty && !refresh) return;
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi API để lấy TOÀN BỘ dữ liệu từ database (không phân trang)
      final response = await _repository.getExercises(
        languageId: languageId,
        page: 1,
        limit: 1000, // Load tất cả
      );

      _exercises.addAll(response.items);
      _hasMore = false; // Đã load hết
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load chi tiết exercise từ Database theo ID
  Future<void> loadExerciseDetail(int exerciseId, {int languageId = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Kiểm tra cache trước
      final cachedExercise =
          _exercises.where((e) => e.exerciseId == exerciseId).firstOrNull;

      if (cachedExercise != null && cachedExercise.images.isNotEmpty) {
        // Đã có đầy đủ thông tin trong cache (including images)
        _selectedExercise = cachedExercise;
      } else {
        // Gọi API để lấy chi tiết từ database
        final exercise = await _repository.getExerciseById(
          exerciseId,
          languageId: languageId,
        );
        _selectedExercise = exercise;

        // Cập nhật hoặc thêm vào cache
        if (exercise != null) {
          final index = _exercises.indexWhere(
            (e) => e.exerciseId == exerciseId,
          );
          if (index != -1) {
            // Cập nhật exercise hiện có
            _exercises[index] = exercise;
          } else {
            // Thêm mới vào list
            _exercises.add(exercise);
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load muscles từ Database (hỗ trợ đa ngôn ngữ)
  Future<void> loadMuscles({int languageId = 1}) async {
    try {
      _muscles = await _repository.getMuscles(languageId: languageId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load muscles: $e');
    }
  }

  /// Load equipments từ Database
  Future<void> loadEquipments() async {
    try {
      _equipments = await _repository.getEquipments();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load equipments: $e');
    }
  }

  /// Load categories từ Database
  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
    }
  }

  /// Load tất cả filter options từ Database (với caching)
  Future<void> loadFilterOptions({int languageId = 1}) async {
    // Skip nếu đã load với cùng ngôn ngữ
    if (_filterOptionsLoaded && _cachedLanguageId == languageId) {
      return;
    }

    await Future.wait([
      loadMuscles(languageId: languageId),
      loadEquipments(),
      loadCategories(),
    ]);

    _filterOptionsLoaded = true;
    _cachedLanguageId = languageId;
  }

  /// Tìm kiếm exercises trong Database
  Future<List<Exercise>> searchExercises(
    String query, {
    int languageId = 1,
  }) async {
    try {
      return await _repository.searchExercises(query, languageId: languageId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Lấy exercises theo nhóm cơ từ Database
  Future<List<Exercise>> getExercisesByMuscle(
    String muscle, {
    int languageId = 1,
  }) async {
    try {
      return await _repository.getExercisesByMuscle(
        muscle,
        languageId: languageId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void setFilter(ExerciseFilter newFilter, {int languageId = 1}) {
    _filter = newFilter;
    _invalidateFilterCache();
    resetPagination(); // Reset về trang 1 khi filter thay đổi
    notifyListeners();
  }

  void clearFilter() {
    _filter = const ExerciseFilter();
    _invalidateFilterCache();
    resetPagination(); // Reset về trang 1
    notifyListeners();
  }

  /// Cập nhật search với debounce để tránh gọi quá nhiều
  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _filter = _filter.copyWith(searchQuery: query);
      _invalidateFilterCache();
      resetPagination(); // Reset về trang 1 khi search
      notifyListeners();
    });
  }

  /// Invalidate filter cache khi filter thay đổi
  void _invalidateFilterCache() {
    _cachedFilteredExercises = null;
    _lastFilterState = null;
  }

  /// Filter exercises locally (với caching)
  List<Exercise> get filteredExercises {
    // Trả về cache nếu filter không đổi
    if (_cachedFilteredExercises != null && _lastFilterState == _filter) {
      return _cachedFilteredExercises!;
    }

    // Tính toán filter mới
    _cachedFilteredExercises = _computeFilteredExercises();
    _lastFilterState = _filter;
    return _cachedFilteredExercises!;
  }

  /// Tính toán filtered exercises (tách riêng để dễ optimize)
  List<Exercise> _computeFilteredExercises() {
    if (!_filter.hasFilters) return _exercises;

    final query = _filter.searchQuery?.toLowerCase();

    return _exercises.where((exercise) {
      // Level filter - exercise phải match một trong các levels được chọn
      if (_filter.levels.isNotEmpty &&
          !_filter.levels.contains(exercise.level)) {
        return false;
      }
      // Equipment filter - exercise phải match một trong các equipments được chọn
      if (_filter.equipments.isNotEmpty &&
          !_filter.equipments.contains(exercise.equipment)) {
        return false;
      }
      // Category filter - exercise phải match một trong các categories được chọn
      if (_filter.categories.isNotEmpty &&
          !_filter.categories.contains(exercise.category)) {
        return false;
      }
      // Muscle filter - exercise phải có ít nhất một muscle trong danh sách được chọn
      if (_filter.muscles.isNotEmpty) {
        final hasMatchingMuscle = _filter.muscles.any(
          (muscle) =>
              exercise.primaryMuscles.contains(muscle) ||
              exercise.secondaryMuscles.contains(muscle),
        );
        if (!hasMatchingMuscle) {
          return false;
        }
      }
      // Search query
      if (query != null && query.isNotEmpty) {
        if (!exercise.name.toLowerCase().contains(query) &&
            !(exercise.description?.toLowerCase().contains(query) ?? false)) {
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
    _exercises.clear();
    _muscles.clear();
    _categories.clear();
    _equipments.clear();
    _filterOptionsLoaded = false;
    _cachedLanguageId = languageId;
    _hasMore = true;
    _cachedFilteredExercises = null;
    _lastFilterState = null;

    // Reload all data
    await Future.wait([
      loadExercises(languageId: languageId, refresh: true),
      loadFilterOptions(languageId: languageId),
    ]);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
