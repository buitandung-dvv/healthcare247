import 'package:flutter/foundation.dart';
import '../data/models/tracking_model.dart';
import '../data/models/goals_model.dart';
import '../data/models/achievement_model.dart';
import '../core/repositories/tracking_repository.dart';
import '../core/repositories/goals_repository.dart';
import '../core/constants/app_colors.dart';

/// Progress Provider - Quản lý dữ liệu trang tiến độ
class ProgressProvider extends ChangeNotifier {
  final TrackingRepository _trackingRepository;
  final GoalsRepository _goalsRepository;

  ProgressProvider({
    TrackingRepository? trackingRepository,
    GoalsRepository? goalsRepository,
  }) : _trackingRepository = trackingRepository ?? TrackingRepository(),
       _goalsRepository = goalsRepository ?? GoalsRepository();

  // State
  List<WeightTracking> _weightHistory = [];
  List<DailyProgress> _weeklyProgress = [];
  DailyProgress? _todayProgress;
  UserGoals? _userGoals;
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  String? _errorMessage;

  // User stats for achievements
  int _totalWorkoutsCompleted = 0;
  int _currentStreak = 0;
  int _daysUsingApp = 0;

  // Getters
  List<WeightTracking> get weightHistory => _weightHistory;
  List<DailyProgress> get weeklyProgress => _weeklyProgress;
  DailyProgress? get todayProgress => _todayProgress;
  UserGoals? get userGoals => _userGoals;
  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalWorkoutsCompleted => _totalWorkoutsCompleted;
  int get currentStreak => _currentStreak;

  // Computed properties
  bool get hasWeightData => _weightHistory.isNotEmpty;
  bool get hasMacroData =>
      _todayProgress != null &&
      (_todayProgress!.protein > 0 ||
          _todayProgress!.carbs > 0 ||
          _todayProgress!.fat > 0);
  bool get hasWeeklyData => _weeklyProgress.isNotEmpty;

  double get latestWeight =>
      _weightHistory.isNotEmpty ? _weightHistory.first.weight : 0;
  double? get previousWeight =>
      _weightHistory.length > 1 ? _weightHistory[1].weight : null;
  double get weightChange {
    if (_weightHistory.length < 2) return 0;
    return _weightHistory.first.weight - _weightHistory.last.weight;
  }

  /// Load all progress data
  Future<void> loadProgressData(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load data in parallel
      final results = await Future.wait([
        _trackingRepository.getWeightHistory(userId: userId, limit: 30),
        _trackingRepository.getWeeklyProgress(userId: userId),
        _trackingRepository.getDailyProgress(
          userId: userId,
          date: DateTime.now(),
        ),
        _goalsRepository.getUserGoals(userId),
        _loadUserStats(userId),
      ], eagerError: false);

      _weightHistory = results[0] as List<WeightTracking>;
      _weeklyProgress = results[1] as List<DailyProgress>;
      _todayProgress = results[2] as DailyProgress?;
      _userGoals = results[3] as UserGoals?;

      debugPrint('📊 Progress loaded: ${_weightHistory.length} weight entries');

      // Calculate achievements after loading stats
      _calculateAchievements();
    } catch (e) {
      debugPrint('❌ Progress API error: $e');
      _errorMessage = e.toString();
      // Keep empty state for graceful degradation
      _weightHistory = [];
      _weeklyProgress = [];
      _todayProgress = null;
      _achievements = Achievement.defaultAchievements(
        AppColors.primary,
        AppColors.secondary,
        AppColors.caloriesColor,
        AppColors.info,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Log new weight
  Future<bool> logWeight({
    required int userId,
    required double weight,
    String? notes,
  }) async {
    try {
      final result = await _trackingRepository.logWeight(
        userId: userId,
        weight: weight,
        notes: notes,
      );

      if (result != null) {
        // Add to the beginning of the list (most recent first)
        _weightHistory.insert(0, result);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Load user stats for achievements calculation
  Future<void> _loadUserStats(int userId) async {
    try {
      // Get exercise history to count total workouts
      final exercises = await _trackingRepository.getExerciseHistory(
        userId: userId,
        limit: 100,
      );
      _totalWorkoutsCompleted = exercises.length;

      // Calculate streak from weekly progress
      _currentStreak = _calculateStreak();

      // Calculate days using app (from first weight or exercise entry)
      _daysUsingApp = _calculateDaysUsingApp();
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  int _calculateStreak() {
    if (_weeklyProgress.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < _weeklyProgress.length; i++) {
      final progress = _weeklyProgress[_weeklyProgress.length - 1 - i];
      final expectedDate = today.subtract(Duration(days: i));

      if (progress.date.day == expectedDate.day &&
          progress.date.month == expectedDate.month &&
          (progress.workoutsCompleted > 0 || progress.mealsLogged > 0)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  int _calculateDaysUsingApp() {
    DateTime? earliestDate;

    if (_weightHistory.isNotEmpty) {
      earliestDate = _weightHistory.last.trackedAt;
    }

    if (earliestDate == null) return 0;

    return DateTime.now().difference(earliestDate).inDays + 1;
  }

  void _calculateAchievements() {
    final defaultAchievements = Achievement.defaultAchievements(
      AppColors.primary,
      AppColors.secondary,
      AppColors.caloriesColor,
      AppColors.info,
    );

    _achievements =
        defaultAchievements.map((achievement) {
          bool isUnlocked = false;

          switch (achievement.id) {
            case 'first_week':
              isUnlocked = _daysUsingApp >= 7;
              break;
            case '7_day_streak':
              isUnlocked = _currentStreak >= 7;
              break;
            case '10_workouts':
              isUnlocked = _totalWorkoutsCompleted >= 10;
              break;
            case '30_days':
              isUnlocked = _daysUsingApp >= 30;
              break;
            case 'goal_reached':
              // Check if user reached their weight goal
              if (_weightHistory.isNotEmpty && _userGoals != null) {
                // This would need a target weight in user goals
                // For now, leave as false
                isUnlocked = false;
              }
              break;
          }

          return achievement.copyWith(
            isUnlocked: isUnlocked,
            unlockedAt: isUnlocked ? DateTime.now() : null,
          );
        }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
