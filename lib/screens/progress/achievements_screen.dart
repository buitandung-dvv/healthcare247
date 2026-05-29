import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/achievement_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/progress_provider.dart';

/// Achievements Screen — Stitch Design
/// Thành tựu với level system, XP progress, và badge grid
/// Dữ liệu từ ProgressProvider (DB), không hardcode
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    // Load data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    if (userId > 0) {
      await context.read<ProgressProvider>().loadIfNeeded(userId);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    final progressProvider = context.watch<ProgressProvider>();

    final achievements = progressProvider.achievements;
    final streak = progressProvider.currentStreak;
    final totalWorkouts = progressProvider.totalWorkoutsCompleted;
    final earnedCount = achievements.where((a) => a.isUnlocked).length;

    // Calculate level from total achievements progress
    final level = _calculateLevel(totalWorkouts, streak);
    final levelTitle = _getLevelTitle(level, lang);
    final currentXP = _calculateXP(totalWorkouts, streak, earnedCount);
    final nextLevelXP = _nextLevelXPThreshold(level);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lang),
            if (progressProvider.isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final authProvider = context.read<AuthProvider>();
                    final userId = authProvider.userId;
                    if (userId > 0) {
                      context.read<ProgressProvider>().invalidate();
                      await context.read<ProgressProvider>().loadIfNeeded(
                        userId,
                      );
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLevelCard(
                          level,
                          levelTitle,
                          currentXP,
                          nextLevelXP,
                        ),
                        const SizedBox(height: 20),
                        _buildStatsRow(
                          lang,
                          streak,
                          totalWorkouts,
                          earnedCount,
                          achievements.length,
                        ),
                        const SizedBox(height: 24),
                        _buildBadgeGrid(lang, achievements),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Level Calculation ──
  int _calculateLevel(int totalWorkouts, int streak) {
    // Simple level formula based on workouts and streak
    final score = totalWorkouts * 10 + streak * 5;
    if (score >= 5000) return 20;
    if (score >= 3000) return 15;
    if (score >= 2000) return 12;
    if (score >= 1500) return 10;
    if (score >= 1000) return 8;
    if (score >= 500) return 6;
    if (score >= 200) return 4;
    if (score >= 50) return 2;
    return 1;
  }

  String _getLevelTitle(int level, LanguageProvider lang) {
    if (level >= 15) return lang.getText(en: 'Legend', vi: 'Huyền thoại');
    if (level >= 10) return lang.getText(en: 'Warrior', vi: 'Chiến binh');
    if (level >= 6) return lang.getText(en: 'Fighter', vi: 'Chiến sĩ');
    if (level >= 3) return lang.getText(en: 'Trainee', vi: 'Tập sự');
    return lang.getText(en: 'Beginner', vi: 'Mới bắt đầu');
  }

  int _calculateXP(int totalWorkouts, int streak, int earnedCount) {
    return totalWorkouts * 10 + streak * 5 + earnedCount * 100;
  }

  int _nextLevelXPThreshold(int level) {
    return (level + 1) * 500;
  }

  // ── Header ──
  Widget _buildHeader(LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                size: 20,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              lang.getText(en: 'Achievements', vi: 'Thành tựu'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 40), // balance
        ],
      ),
    );
  }

  // ── Level Card ──
  Widget _buildLevelCard(
    int level,
    String levelTitle,
    int currentXP,
    int nextLevelXP,
  ) {
    final xpProgress = (currentXP / nextLevelXP).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (context, _) {
          return Column(
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Cấp $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                levelTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              // XP Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: xpProgress * _progressAnim.value,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currentXP XP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$nextLevelXP XP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow(
    LanguageProvider lang,
    int streak,
    int totalWorkouts,
    int earnedCount,
    int totalAchievements,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: '$streak',
            label: lang.getText(en: 'Day Streak', vi: 'Ngày streak'),
            color: const Color(0xFFFF6B35),
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            icon: Icons.fitness_center,
            value: '$totalWorkouts',
            label: lang.getText(en: 'Workouts', vi: 'Tổng bài tập'),
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            icon: Icons.emoji_events,
            value: '$earnedCount/$totalAchievements',
            label: lang.getText(en: 'Achievements', vi: 'Thành tựu'),
            color: const Color(0xFFFFB74D),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Badge Grid ──
  Widget _buildBadgeGrid(
    LanguageProvider lang,
    List<Achievement> achievements,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (achievements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                lang.getText(
                  en: 'No achievements yet',
                  vi: 'Chưa có thành tựu nào',
                ),
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                lang.getText(
                  en: 'Keep exercising to unlock achievements!',
                  vi: 'Hãy tiếp tục tập luyện để mở khóa thành tựu!',
                ),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.getText(en: 'All Badges', vi: 'Tất cả huy hiệu'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) => _buildBadgeCard(achievements[i], lang),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Achievement achievement, LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = lang.getText(
      en: achievement.titleEn,
      vi: achievement.titleVi,
    );
    final desc = lang.getText(
      en: achievement.descriptionEn,
      vi: achievement.descriptionVi,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: achievement.isUnlocked
                ? achievement.color.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: achievement.isUnlocked
                  ? LinearGradient(
                      colors: [
                        achievement.color,
                        achievement.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: achievement.isUnlocked ? null : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked
                  ? Colors.white
                  : Colors.grey.shade400,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked
                  ? AppColors.textPrimary
                  : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Description
          Text(
            desc,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Status
          if (achievement.isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: achievement.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: achievement.color),
                  const SizedBox(width: 4),
                  Text(
                    achievement.unlockedAt != null
                        ? '${achievement.unlockedAt!.day.toString().padLeft(2, '0')}/${achievement.unlockedAt!.month.toString().padLeft(2, '0')}/${achievement.unlockedAt!.year}'
                        : lang.getText(en: 'Earned', vi: 'Đã đạt'),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: achievement.color,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                lang.getText(en: 'Locked', vi: 'Chưa đạt'),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextHint : Colors.grey.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
