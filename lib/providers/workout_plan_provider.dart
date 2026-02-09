import 'package:flutter/foundation.dart';
import '../core/repositories/workout_plan_repository.dart';
import '../core/repositories/workout_session_repository.dart';
import '../data/models/plan_model.dart';
import '../data/models/workout_session_model.dart';

class WorkoutPlanProvider with ChangeNotifier {
  final WorkoutPlanRepository _planRepository = WorkoutPlanRepository();
  final WorkoutSessionRepository _sessionRepository =
      WorkoutSessionRepository();

  List<Plan> _userPlans = [];
  WorkoutSession? _activeSession;
  bool _isLoading = false;
  String? _error;

  List<Plan> get userPlans => _userPlans;
  WorkoutSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession => _activeSession != null;

  /// Load user's workout plans
  Future<void> loadUserPlans({int languageId = 1}) async {
    _setLoading(true);
    try {
      _userPlans = await _planRepository.getUserPlans(languageId: languageId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading plans: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new workout plan
  Future<Plan?> createPlan(
    String name, {
    String? description,
    String? scheduleDays,
  }) async {
    _setLoading(true);
    try {
      final plan = await _planRepository.createPlan(
        name,
        description: description,
        scheduleDays: scheduleDays,
      );
      if (plan != null) {
        _userPlans.insert(0, plan);
        notifyListeners();
      }
      return plan;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing workout plan
  Future<bool> updatePlan(
    int planId, {
    String? name,
    String? description,
    String? scheduleDays,
  }) async {
    _setLoading(true);
    try {
      final success = await _planRepository.updatePlan(
        planId,
        name: name,
        description: description,
        scheduleDays: scheduleDays,
      );
      if (success) {
        // Refresh plans to show update
        await loadUserPlans();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all details from a plan (for edit mode)
  Future<bool> clearPlanDetails(int planId) async {
    try {
      return await _planRepository.clearPlanDetails(planId);
    } catch (e) {
      debugPrint('Error clearing plan details: $e');
      return false;
    }
  }

  /// Add exercise to plan
  Future<bool> addExerciseToPlan({
    required int planId,
    required int exerciseId,
    int sets = 3,
    int reps = 10,
    int restDuration = 60,
    int orderIndex = 0,
  }) async {
    try {
      final detail = await _planRepository.addPlanDetail(
        planId: planId,
        exerciseId: exerciseId,
        sets: sets,
        reps: reps,
        restDuration: restDuration,
        orderIndex: orderIndex,
      );

      // Don't reload plans here - caller should reload once after all exercises added
      return detail != null;
    } catch (e) {
      debugPrint('Error adding exercise to plan: $e');
      return false;
    }
  }

  /// Load active session if any
  Future<void> loadActiveSession() async {
    try {
      _activeSession = await _sessionRepository.getActiveSession();
      if (_activeSession != null) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading active session: $e');
    }
  }

  /// Start a new workout session
  Future<bool> startSession({
    int? planId,
    int? exerciseId,
    String? name,
  }) async {
    _setLoading(true);
    try {
      _activeSession = await _sessionRepository.startSession(
        planId: planId,
        exerciseId: exerciseId,
        name: name,
      );

      if (_activeSession != null) {
        // Fetch full details
        _activeSession = await _sessionRepository.getSessionById(
          _activeSession!.sessionId,
        );
      }

      _error = null;
      return _activeSession != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update exercise progress in current session
  Future<void> updateExerciseProgress(
    int exerciseId,
    int setsCompleted, {
    String? repsCompleted,
    String? weightUsed,
    String? notes,
  }) async {
    if (_activeSession == null) return;

    try {
      final updatedDetail = await _sessionRepository.updateExerciseProgress(
        sessionId: _activeSession!.sessionId,
        exerciseId: exerciseId,
        setsCompleted: setsCompleted,
        repsCompleted: repsCompleted,
        weightUsed: weightUsed,
        notes: notes,
      );

      if (updatedDetail != null) {
        // Update local state
        final index = _activeSession!.details.indexWhere(
          (d) => d.exerciseId == exerciseId,
        );
        if (index != -1) {
          // Create a new list to ensure immutability/notification
          final newDetails = List<WorkoutSessionDetail>.from(
            _activeSession!.details,
          );
          newDetails[index] = updatedDetail;

          // Cannot modify _activeSession directly as it's final fields,
          // usually we would use copyWith but let's just reload for sync safety or create a mutable wrapper
          // For now, re-fetch the session to be safe and simple
          _activeSession = await _sessionRepository.getSessionById(
            _activeSession!.sessionId,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating progress: $e');
    }
  }

  /// Complete current session
  Future<bool> completeSession({String? notes}) async {
    if (_activeSession == null) return false;

    _setLoading(true);
    try {
      final completedSession = await _sessionRepository.completeSession(
        _activeSession!.sessionId,
        notes: notes,
      );

      if (completedSession != null) {
        _activeSession = null; // Clear active session
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel current session
  Future<bool> cancelSession() async {
    if (_activeSession == null) return false;

    _setLoading(true);
    try {
      final success = await _sessionRepository.cancelSession(
        _activeSession!.sessionId,
      );
      if (success) {
        _activeSession = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a workout plan
  Future<bool> deletePlan(int planId) async {
    _setLoading(true);
    try {
      final success = await _planRepository.deletePlan(planId);
      if (success) {
        _userPlans.removeWhere((p) => p.planId == planId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
