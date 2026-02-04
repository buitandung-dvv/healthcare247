/// Greeting Helper - Tạo lời chào dựa trên thời gian trong ngày
class GreetingHelper {
  GreetingHelper._();

  /// Get greeting based on current hour
  static String getGreeting({bool isVietnamese = false}) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return isVietnamese ? 'Chào buổi sáng' : 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return isVietnamese ? 'Chào buổi chiều' : 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return isVietnamese ? 'Chào buổi tối' : 'Good evening';
    } else {
      return isVietnamese ? 'Chào khuya' : 'Good night';
    }
  }

  /// Get greeting with username
  static String getPersonalizedGreeting(
    String? username, {
    bool isVietnamese = false,
  }) {
    final greeting = getGreeting(isVietnamese: isVietnamese);
    final name = username ?? (isVietnamese ? 'bạn' : 'there');
    return '$greeting, $name! 👋';
  }

  /// Get motivational message based on time
  static String getMotivationalMessage({bool isVietnamese = false}) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 9) {
      return isVietnamese
          ? 'Hãy bắt đầu ngày mới với năng lượng tích cực!'
          : 'Start your day with positive energy!';
    } else if (hour >= 9 && hour < 12) {
      return isVietnamese
          ? 'Giữ vững tinh thần và tiếp tục phấn đấu!'
          : 'Stay focused and keep pushing!';
    } else if (hour >= 12 && hour < 14) {
      return isVietnamese
          ? 'Đừng quên nghỉ ngơi và ăn trưa nhé!'
          : "Don't forget to rest and have lunch!";
    } else if (hour >= 14 && hour < 17) {
      return isVietnamese
          ? 'Buổi chiều năng động, kết quả tuyệt vời!'
          : 'Productive afternoon leads to great results!';
    } else if (hour >= 17 && hour < 20) {
      return isVietnamese
          ? 'Thời gian hoàn hảo để tập luyện!'
          : 'Perfect time for a workout!';
    } else {
      return isVietnamese
          ? 'Nghỉ ngơi tốt để ngày mai tràn đầy năng lượng!'
          : 'Rest well for an energetic tomorrow!';
    }
  }

  /// Get icon for current time of day
  static String getTimeEmoji() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return '🌅'; // Morning
    } else if (hour >= 12 && hour < 17) {
      return '☀️'; // Afternoon
    } else if (hour >= 17 && hour < 21) {
      return '🌆'; // Evening
    } else {
      return '🌙'; // Night
    }
  }

  /// Get workout suggestion based on time
  static String getWorkoutSuggestion({bool isVietnamese = false}) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 9) {
      return isVietnamese
          ? 'Cardio buổi sáng giúp tỉnh táo cả ngày'
          : 'Morning cardio boosts your day';
    } else if (hour >= 9 && hour < 12) {
      return isVietnamese
          ? 'Giãn cơ và tập luyện nhẹ nhàng'
          : 'Stretching and light exercise';
    } else if (hour >= 12 && hour < 14) {
      return isVietnamese
          ? 'Tập nhẹ 15 phút sau bữa trưa'
          : '15-min light workout after lunch';
    } else if (hour >= 14 && hour < 17) {
      return isVietnamese
          ? 'Thời điểm lý tưởng để tập tạ'
          : 'Ideal time for strength training';
    } else if (hour >= 17 && hour < 20) {
      return isVietnamese
          ? 'HIIT hoặc tập gym sau giờ làm'
          : 'HIIT or gym session after work';
    } else {
      return isVietnamese
          ? 'Yoga và thư giãn trước khi ngủ'
          : 'Yoga and relaxation before bed';
    }
  }
}
