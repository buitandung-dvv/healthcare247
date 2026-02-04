import 'package:flutter/foundation.dart';
import '../core/repositories/goals_repository.dart';
import '../data/models/goals_model.dart';

/// Goals Provider - Quản lý mục tiêu sức khỏe và thể hình của người dùng
class GoalsProvider extends ChangeNotifier {
  final GoalsRepository _repository;

  UserGoals? _userGoals;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  GoalsProvider({GoalsRepository? repository})
    : _repository = repository ?? GoalsRepository();

  // Getters
  UserGoals? get userGoals => _userGoals;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  /// Load user goals
  Future<void> loadUserGoals(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userGoals = await _repository.getUserGoals(userId);
      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load goals: $e';
      if (kDebugMode) print(_errorMessage);
    }
    notifyListeners();
  }

  /// Update user goals
  Future<bool> updateUserGoals({
    required int userId,
    double? caloriesGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    int? waterGoalMl,
    int? workoutsPerWeek,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedGoals = await _repository.updateUserGoals(
        userId: userId,
        caloriesGoal: caloriesGoal,
        proteinGoal: proteinGoal,
        carbsGoal: carbsGoal,
        fatGoal: fatGoal,
        waterGoalMl: waterGoalMl,
        workoutsPerWeek: workoutsPerWeek,
      );

      if (updatedGoals != null) {
        _userGoals = updatedGoals;
        _isUpdating = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isUpdating = false;
      _errorMessage = 'Failed to update goals: $e';
      if (kDebugMode) print(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Set calorie goal
  Future<bool> setCalorieGoal(int userId, double caloriesGoal) async {
    return await updateUserGoals(userId: userId, caloriesGoal: caloriesGoal);
  }

  /// Set macro goals (protein, carbs, fat)
  Future<bool> setMacroGoals(
    int userId, {
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
  }) async {
    return await updateUserGoals(
      userId: userId,
      proteinGoal: proteinGoal,
      carbsGoal: carbsGoal,
      fatGoal: fatGoal,
    );
  }

  /// Set water intake goal
  Future<bool> setWaterGoal(int userId, int waterGoalMl) async {
    return await updateUserGoals(userId: userId, waterGoalMl: waterGoalMl);
  }

  /// Set workouts per week goal
  Future<bool> setWorkoutsGoal(int userId, int workoutsPerWeek) async {
    return await updateUserGoals(
      userId: userId,
      workoutsPerWeek: workoutsPerWeek,
    );
  }

  /// Calculate calorie progress for today
  double getCalorieProgress(double consumedCalories) {
    if (_userGoals == null || _userGoals!.caloriesGoal <= 0) return 0;
    return (consumedCalories / _userGoals!.caloriesGoal).clamp(0, 1.5);
  }

  /// Calculate water progress for today
  double getWaterProgress(int consumedMl) {
    if (_userGoals == null || _userGoals!.waterGoalMl <= 0) return 0;
    return (consumedMl / _userGoals!.waterGoalMl).clamp(0, 1.5);
  }

  /// Calculate macro progress (protein/carbs/fat)
  Map<String, double> getMacroProgress({
    required double protein,
    required double carbs,
    required double fat,
  }) {
    if (_userGoals == null) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }
    return {
      'protein':
          _userGoals!.proteinGoal > 0
              ? (protein / _userGoals!.proteinGoal).clamp(0, 1.5)
              : 0,
      'carbs':
          _userGoals!.carbsGoal > 0
              ? (carbs / _userGoals!.carbsGoal).clamp(0, 1.5)
              : 0,
      'fat':
          _userGoals!.fatGoal > 0
              ? (fat / _userGoals!.fatGoal).clamp(0, 1.5)
              : 0,
    };
  }

  /// Clear error message
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh goals
  Future<void> refreshGoals(int userId) async {
    await loadUserGoals(userId);
  }
}
