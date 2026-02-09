import 'package:flutter/foundation.dart';
import '../data/models/tracking_model.dart';
import '../core/repositories/tracking_repository.dart';

/// Dashboard Provider - Quản lý dữ liệu trang chủ
class DashboardProvider extends ChangeNotifier {
  final TrackingRepository _repository;

  DashboardProvider({TrackingRepository? repository})
    : _repository = repository ?? TrackingRepository();

  DailyProgress _todayProgress = DailyProgress(date: DateTime.now());
  List<DailyProgress> _weeklyProgress = [];
  List<ExerciseTracking> _recentActivities = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasData = false; // Track if user has real data

  // Callback for notifying when data is updated (for invalidating other providers)
  VoidCallback? onDataUpdated;

  DailyProgress get todayProgress => _todayProgress;
  List<DailyProgress> get weeklyProgress => _weeklyProgress;
  List<ExerciseTracking> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _hasData; // Check if user has real data

  /// Calculate current streak from weekly progress
  int get currentStreak {
    if (_weeklyProgress.isEmpty) return 0;
    int streak = 0;
    // Count consecutive days with workouts completed
    for (final day in _weeklyProgress.reversed) {
      if (day.workoutsCompleted > 0 || day.mealsLogged > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> loadDashboardData(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load daily, weekly progress, and activity history in parallel
      final results = await Future.wait([
        _repository.getDailyProgress(userId: userId, date: DateTime.now()),
        _repository.getWeeklyProgress(userId: userId),
        _repository.getExerciseHistory(
          userId: userId,
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          limit: 10,
        ),
      ], eagerError: false);

      final daily = results[0] as DailyProgress?;
      final weekly = results[1] as List<DailyProgress>;
      final activities = results[2] as List<ExerciseTracking>;

      if (daily != null) {
        _todayProgress = daily;
        _hasData = true;
      }
      if (weekly.isNotEmpty) {
        _weeklyProgress = weekly;
        _hasData = true;
      }
      if (activities.isNotEmpty) {
        _recentActivities = activities;
        _hasData = true;
      } else {
        _recentActivities = [];
      }

      // No data - keep hasData as false, show empty state
      if (daily == null && weekly.isEmpty && activities.isEmpty) {
        _hasData = false;
        _todayProgress = DailyProgress(date: DateTime.now());
        _weeklyProgress = [];
        _recentActivities = [];
      }
    } catch (e) {
      debugPrint('Dashboard API error: $e');
      // API error (e.g. 401 not logged in) - show empty state
      _hasData = false;
      _todayProgress = DailyProgress(date: DateTime.now());
      _weeklyProgress = [];
      _recentActivities = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logMeal({
    required int userId,
    required String mealType,
    String? mealName,
    required double calories,
    double? protein,
    double? carbs,
    double? fat,
    double? quantity,
  }) async {
    try {
      // Debug-only logging
      assert(() {
        debugPrint(
          '🍽️ [DashboardProvider] logMeal: $mealType - $mealName (${quantity}g, $calories kcal)',
        );
        return true;
      }());

      // Log to API
      final result = await _repository.logMeal(
        userId: userId,
        mealType: mealType,
        mealName: mealName,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        quantity: quantity,
      );

      // Debug-only logging
      assert(() {
        debugPrint(
          '✅ [DashboardProvider] logMeal success: ${result?.trackingId}',
        );
        return true;
      }());

      // Update local state
      _todayProgress = DailyProgress(
        date: _todayProgress.date,
        caloriesConsumed: _todayProgress.caloriesConsumed + calories,
        caloriesBurned: _todayProgress.caloriesBurned,
        caloriesGoal: _todayProgress.caloriesGoal,
        protein: _todayProgress.protein + (protein ?? 0),
        proteinGoal: _todayProgress.proteinGoal,
        carbs: _todayProgress.carbs + (carbs ?? 0),
        carbsGoal: _todayProgress.carbsGoal,
        fat: _todayProgress.fat + (fat ?? 0),
        fatGoal: _todayProgress.fatGoal,
        workoutsCompleted: _todayProgress.workoutsCompleted,
        workoutsPlanned: _todayProgress.workoutsPlanned,
        mealsLogged: _todayProgress.mealsLogged + 1,
      );
      notifyListeners();
      onDataUpdated?.call(); // Notify to invalidate related providers
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> logWorkout({
    required int userId,
    required int exerciseId,
    required int duration,
    double? caloriesBurned,
  }) async {
    try {
      // Log to API
      await _repository.logExercise(
        userId: userId,
        exerciseId: exerciseId,
        duration: duration,
        caloriesBurned: caloriesBurned,
      );

      // Update local state
      _todayProgress = DailyProgress(
        date: _todayProgress.date,
        caloriesConsumed: _todayProgress.caloriesConsumed,
        caloriesBurned: _todayProgress.caloriesBurned + (caloriesBurned ?? 0),
        caloriesGoal: _todayProgress.caloriesGoal,
        protein: _todayProgress.protein,
        proteinGoal: _todayProgress.proteinGoal,
        carbs: _todayProgress.carbs,
        carbsGoal: _todayProgress.carbsGoal,
        fat: _todayProgress.fat,
        fatGoal: _todayProgress.fatGoal,
        workoutsCompleted: _todayProgress.workoutsCompleted + 1,
        workoutsPlanned: _todayProgress.workoutsPlanned,
        mealsLogged: _todayProgress.mealsLogged,
      );
      notifyListeners();
      onDataUpdated?.call(); // Notify to invalidate related providers
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
