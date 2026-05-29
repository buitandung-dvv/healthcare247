import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/water_tracking_provider.dart';
import '../../providers/workout_plan_provider.dart';
import '../../providers/progress_provider.dart';

/// Notifications Screen — Stitch Design
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedCategory = 'all';

  /// Build notifications dynamically from provider data
  List<_NotificationItem> _buildNotifications(LanguageProvider lang) {
    final dashboard = context.read<DashboardProvider>();
    final waterProvider = context.read<WaterTrackingProvider>();
    final workoutPlanProvider = context.read<WorkoutPlanProvider>();
    final progressProvider = context.read<ProgressProvider>();

    final progress = dashboard.todayProgress;
    final waterIntake = waterProvider.dailyIntake;
    final plans = workoutPlanProvider.userPlans;
    final streak = progressProvider.currentStreak;

    final List<_NotificationItem> notifications = [];

    // 1. Workout reminder — based on user's actual plans
    if (plans.isNotEmpty) {
      final plan = plans.first;
      final exerciseCount = plan.details.length;
      notifications.add(
        _NotificationItem(
          icon: Icons.fitness_center,
          iconColor: const Color(0xFFFF7043),
          bgColor: const Color(0xFFFFF3E0),
          title: lang.getText(en: 'Time to workout!', vi: 'Đến giờ tập luyện!'),
          body: lang.getText(
            en: '${plan.name ?? "Workout Plan"} is waiting. $exerciseCount exercises',
            vi: '${plan.name ?? "Kế hoạch tập"} đang chờ bạn. $exerciseCount bài tập',
          ),
          time: lang.getText(en: 'Today', vi: 'Hôm nay'),
          isUnread: progress.workoutsCompleted == 0,
          category: 'workout',
        ),
      );
    }

    // 2. Water reminder — based on actual water intake
    final waterRemaining = waterIntake.goalMl - waterIntake.totalMl;
    if (waterRemaining > 0) {
      notifications.add(
        _NotificationItem(
          icon: Icons.water_drop,
          iconColor: const Color(0xFF42A5F5),
          bgColor: const Color(0xFFE3F2FD),
          title: lang.getText(en: 'Drink water!', vi: 'Uống nước thôi!'),
          body: lang.getText(
            en: 'You need ${waterRemaining}ml more to reach your ${waterIntake.goalMl}ml goal.',
            vi: 'Bạn cần uống thêm ${waterRemaining}ml để đạt mục tiêu ${waterIntake.goalMl}ml.',
          ),
          time: lang.getText(en: 'Today', vi: 'Hôm nay'),
          isUnread: waterIntake.totalMl < waterIntake.goalMl * 0.5,
          category: 'nutrition',
        ),
      );
    } else {
      notifications.add(
        _NotificationItem(
          icon: Icons.water_drop,
          iconColor: const Color(0xFF42A5F5),
          bgColor: const Color(0xFFE3F2FD),
          title: lang.getText(
            en: 'Water goal reached! 🎉',
            vi: 'Đạt mục tiêu nước! 🎉',
          ),
          body: lang.getText(
            en: 'Great job! You drank ${waterIntake.totalMl}ml today.',
            vi: 'Tuyệt vời! Bạn đã uống ${waterIntake.totalMl}ml hôm nay.',
          ),
          time: lang.getText(en: 'Today', vi: 'Hôm nay'),
          isUnread: false,
          category: 'nutrition',
        ),
      );
    }

    // 3. Meal logging reminder — based on actual meals logged
    if (progress.mealsLogged < 3) {
      notifications.add(
        _NotificationItem(
          icon: Icons.restaurant_menu,
          iconColor: const Color(0xFF66BB6A),
          bgColor: const Color(0xFFE8F5E9),
          title: lang.getText(en: 'Log your meals', vi: 'Ghi chép bữa ăn'),
          body: lang.getText(
            en: 'You have logged ${progress.mealsLogged}/3 meals. ${progress.caloriesConsumed.toInt()} kcal recorded.',
            vi: 'Bạn đã ghi ${progress.mealsLogged}/3 bữa ăn. Đã nạp ${progress.caloriesConsumed.toInt()} kcal.',
          ),
          time: lang.getText(en: 'Today', vi: 'Hôm nay'),
          isUnread: progress.mealsLogged == 0,
          category: 'nutrition',
        ),
      );
    }

    // 4. Streak achievement — based on actual streak
    if (streak > 0) {
      notifications.add(
        _NotificationItem(
          icon: Icons.emoji_events,
          iconColor: const Color(0xFFFFA726),
          bgColor: const Color(0xFFFFF8E1),
          title: lang.getText(
            en: 'Streak: $streak days! 🔥',
            vi: 'Chuỗi: $streak ngày! 🔥',
          ),
          body: lang.getText(
            en: 'Congratulations! Keep up the great work with your $streak-day streak.',
            vi: 'Chúc mừng! Tiếp tục phát huy chuỗi $streak ngày liên tiếp nhé.',
          ),
          time: lang.getText(en: 'This week', vi: 'Tuần này'),
          isUnread: false,
          category: 'system',
        ),
      );
    }

    // 5. Calorie goal status — based on actual calorie progress
    final calProgress = progress.caloriesProgress;
    if (calProgress >= 0.9 && calProgress <= 1.1) {
      notifications.add(
        _NotificationItem(
          icon: Icons.check_circle,
          iconColor: const Color(0xFF66BB6A),
          bgColor: const Color(0xFFE8F5E9),
          title: lang.getText(
            en: 'Calorie goal on track!',
            vi: 'Đạt mục tiêu calo!',
          ),
          body: lang.getText(
            en: '${progress.caloriesConsumed.toInt()} / ${progress.caloriesGoal.toInt()} kcal consumed today.',
            vi: 'Đã nạp ${progress.caloriesConsumed.toInt()} / ${progress.caloriesGoal.toInt()} kcal hôm nay.',
          ),
          time: lang.getText(en: 'Today', vi: 'Hôm nay'),
          isUnread: false,
          category: 'nutrition',
        ),
      );
    }

    // 6. Workout completion — if workouts were done today
    if (progress.workoutsCompleted > 0) {
      notifications.add(
        _NotificationItem(
          icon: Icons.fitness_center,
          iconColor: const Color(0xFF66BB6A),
          bgColor: const Color(0xFFE8F5E9),
          title: lang.getText(
            en: 'Workout completed! 💪',
            vi: 'Đã hoàn thành tập! 💪',
          ),
          body: lang.getText(
            en: '${progress.workoutsCompleted} workout(s) done. Burned ${progress.caloriesBurned.toInt()} kcal.',
            vi: '${progress.workoutsCompleted} buổi tập hoàn thành. Đốt ${progress.caloriesBurned.toInt()} kcal.',
          ),
          time: lang.getText(en: 'Today', vi: 'Hôm nay'),
          isUnread: false,
          category: 'workout',
        ),
      );
    }

    // If no notifications were generated, show a welcome message
    if (notifications.isEmpty) {
      notifications.add(
        _NotificationItem(
          icon: Icons.favorite,
          iconColor: const Color(0xFFEF5350),
          bgColor: const Color(0xFFFCE4EC),
          title: lang.getText(
            en: 'Welcome to HealthCare247!',
            vi: 'Chào mừng đến HealthCare247!',
          ),
          body: lang.getText(
            en: 'Start tracking your meals, workouts, and water to see personalized notifications.',
            vi: 'Bắt đầu ghi nhận bữa ăn, bài tập và nước uống để xem thông báo cá nhân hóa.',
          ),
          time: lang.getText(en: 'Just now', vi: 'Vừa xong'),
          isUnread: true,
          category: 'system',
        ),
      );
    }

    return notifications;
  }

  late List<_NotificationItem> _notifications;

  List<_NotificationItem> get _filteredNotifications {
    if (_selectedCategory == 'all') return _notifications;
    return _notifications
        .where((n) => n.category == _selectedCategory)
        .toList();
  }

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n.isUnread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    _notifications = _buildNotifications(lang);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
        centerTitle: false,
        title: Row(
          children: [
            Text(
              lang.getText(en: 'Notifications', vi: 'Thông báo'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount ${lang.getText(en: 'new', vi: 'mới')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              lang.getText(en: 'Read all', vi: 'Đọc tất cả'),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'all',
                    lang.getText(en: 'All', vi: 'Tất cả'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'workout',
                    lang.getText(en: 'Workout', vi: 'Tập luyện'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'nutrition',
                    lang.getText(en: 'Nutrition', vi: 'Dinh dưỡng'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'system',
                    lang.getText(en: 'System', vi: 'Hệ thống'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.getText(
                            en: 'No notifications',
                            vi: 'Chưa có thông báo',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                        _filteredNotifications[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationItem notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: notification.isUnread
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                notification.icon,
                color: notification.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: notification.isUnread
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.isUnread)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String body;
  final String time;
  bool isUnread;
  final String category;

  _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.category,
  });
}
