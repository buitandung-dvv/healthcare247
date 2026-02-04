/// Workout Constants - Các hằng số cho workout session
class WorkoutConstants {
  WorkoutConstants._();

  // Default workout settings
  static const int defaultSets = 4;
  static const int defaultReps = 12;
  static const int defaultRestDuration = 60; // seconds

  // Limits
  static const int minSets = 1;
  static const int maxSets = 10;
  static const int minReps = 1;
  static const int maxReps = 30;
  static const int minRestDuration = 15; // seconds
  static const int maxRestDuration = 180; // seconds
  static const int restDurationStep = 15; // seconds

  // Calorie calculation
  /// Average calories burned per minute for strength training
  static const double caloriesPerMinute = 8.0;

  /// Calculate estimated calories burned based on duration
  static double calculateCalories(int durationSeconds) {
    return (durationSeconds / 60) * caloriesPerMinute;
  }

  // Timer
  static const Duration timerInterval = Duration(seconds: 1);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1500);

  // Colors (Strava-inspired)
  static const int primaryColorValue = 0xFFFC4C02; // Strava orange
  static const int secondaryColorValue = 0xFFE64A19;
  static const int backgroundColorValue = 0xFF1A1A2E; // Dark background
  static const int dialogColorValue = 0xFF2A2A4A;
  static const int activeColorValue = 0xFF00E676; // Green for active
}
