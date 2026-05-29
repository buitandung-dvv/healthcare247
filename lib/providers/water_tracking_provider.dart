import 'package:flutter/foundation.dart';
import '../data/models/tracking_model.dart';
import '../core/repositories/tracking_repository.dart';

/// Water Tracking Provider - Quản lý theo dõi lượng nước uống
class WaterTrackingProvider extends ChangeNotifier {
  final TrackingRepository _repository;

  WaterTrackingProvider({TrackingRepository? repository})
    : _repository = repository ?? TrackingRepository();

  DailyWaterIntake _dailyIntake = const DailyWaterIntake();
  List<WaterTracking> _todayHistory = [];
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = false;
  String? _errorMessage;

  DailyWaterIntake get dailyIntake => _dailyIntake;
  List<WaterTracking> get todayHistory => _todayHistory;
  List<Map<String, dynamic>> get weeklyData => _weeklyData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tải dữ liệu nước uống hôm nay
  Future<void> loadTodayWaterIntake(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getDailyWaterIntake(userId: userId),
        _repository.getWaterHistory(
          userId: userId,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          limit: 20,
        ),
        _repository.getWeeklyWaterSummary(userId: userId),
      ]);

      final daily = results[0] as DailyWaterIntake?;
      final history = results[1] as List<WaterTracking>;
      final weekly = results[2] as List<Map<String, dynamic>>;

      if (daily != null) {
        _dailyIntake = daily;
      }
      _todayHistory = history;
      _weeklyData = weekly;
    } catch (e) {
      debugPrint('❌ Load water intake error: $e');
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Ghi nhận uống nước
  Future<bool> logWater({
    required int userId,
    required int amountMl,
    String? notes,
  }) async {
    try {
      final result = await _repository.logWater(
        userId: userId,
        amountMl: amountMl,
        notes: notes,
      );

      if (result != null) {
        // Cập nhật local state
        _dailyIntake = DailyWaterIntake(
          totalMl: _dailyIntake.totalMl + amountMl,
          entries: _dailyIntake.entries + 1,
          goalMl: _dailyIntake.goalMl,
          progress: (_dailyIntake.totalMl + amountMl) / _dailyIntake.goalMl,
        );
        _todayHistory = [result, ..._todayHistory];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Log water error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Thêm nhanh một ly nước (250ml)
  Future<bool> addGlass(int userId) async {
    return logWater(userId: userId, amountMl: 250);
  }

  /// Thêm nhanh nửa lít (500ml)
  Future<bool> addHalfLiter(int userId) async {
    return logWater(userId: userId, amountMl: 500);
  }

  /// Xóa entry nước uống
  Future<bool> deleteEntry(int trackingId, {DateTime? trackedAt}) async {
    try {
      final success = await _repository.deleteWaterEntry(
        trackingId: trackingId,
        trackedAt: trackedAt,
      );
      if (success) {
        final entry = _todayHistory.firstWhere(
          (e) => e.trackingId == trackingId || e.trackedAt == trackedAt,
          orElse: () => WaterTracking(
            userId: 0,
            amountMl: 0,
            trackedAt: DateTime.now(),
          ),
        );

        _dailyIntake = DailyWaterIntake(
          totalMl: (_dailyIntake.totalMl - entry.amountMl).clamp(0, 99999),
          entries: (_dailyIntake.entries - 1).clamp(0, 999),
          goalMl: _dailyIntake.goalMl,
          progress: ((_dailyIntake.totalMl - entry.amountMl) /
                  _dailyIntake.goalMl)
              .clamp(0, 1),
        );
        _todayHistory.removeWhere(
          (e) => e.trackingId == trackingId || e.trackedAt == trackedAt,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Delete water entry error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
