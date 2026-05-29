import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/tracking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/water_tracking_provider.dart';

/// Water Tracking Screen — Stitch Design
/// Theo dõi nước uống với circular progress, quick-add, lịch sử, và chart 7 ngày
class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  int _selectedQuickAdd = 1;
  bool _showAllHistory = false;
  int? _selectedBarIndex; // tooltip trên chart

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final waterProvider = context.read<WaterTrackingProvider>();
    await waterProvider.loadTodayWaterIntake(authProvider.userId);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _addWater(int amount) async {
    final authProvider = context.read<AuthProvider>();
    final waterProvider = context.read<WaterTrackingProvider>();
    final success = await waterProvider.logWater(
      userId: authProvider.userId,
      amountMl: amount,
    );
    if (success) {
      _animController.forward(from: 0);
    }
  }

  Future<void> _removeLog(WaterTracking log) async {
    final lang = context.read<LanguageProvider>();
    final isVi = lang.currentLanguage == 'vi';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isVi ? 'Xác nhận xóa' : 'Confirm Delete',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          isVi
              ? 'Bạn có chắc chắn muốn xóa ${log.amountMl} ml không?'
              : 'Are you sure you want to delete ${log.amountMl} ml?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isVi ? 'Hủy' : 'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              isVi ? 'Xóa' : 'Delete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final waterProvider = context.read<WaterTrackingProvider>();
    final success = await waterProvider.deleteEntry(
      log.trackingId ?? 0,
      trackedAt: log.trackedAt,
    );
    if (success && mounted) {
      _animController.forward(from: 0);
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVi
                ? 'Xóa thất bại, vui lòng thử lại'
                : 'Delete failed, please try again',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    final waterProvider = context.watch<WaterTrackingProvider>();
    final dailyIntake = waterProvider.dailyIntake;
    final todayHistory = waterProvider.todayHistory;
    final progress = dailyIntake.goalMl > 0
        ? (dailyIntake.totalMl / dailyIntake.goalMl).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lang),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildCircularProgress(
                      progress,
                      dailyIntake.totalMl,
                      dailyIntake.goalMl,
                    ),
                    const SizedBox(height: 40),
                    _buildQuickAddSection(lang),
                    const SizedBox(height: 40),
                    _buildHistorySection(lang, todayHistory),
                    const SizedBox(height: 40),
                    _buildWeeklyChart(lang),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          _circleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  lang.getText(en: 'Water Tracking', vi: 'Theo dõi nước uống'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang.getText(en: 'TODAY', vi: 'HÔM NAY'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          _circleButton(icon: Icons.more_horiz, onTap: () {}),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  // ── Circular Progress ──
  Widget _buildCircularProgress(double progress, int totalDrunk, int goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final remaining = (goal - totalDrunk).clamp(0, goal);

    return Center(
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (context, child) {
          return Column(
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _WaterRingPainter(
                        progress: clampedProgress * _progressAnim.value,
                      ),
                    ),
                    // Glass container
                    Container(
                      width: 110,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade300,
                          width: 3,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      child: Stack(
                        children: [
                          // Water fill
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height:
                                  150 * clampedProgress * _progressAnim.value,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF42A5F5),
                                    Color(0xFF1E88E5),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(13),
                                  bottomRight: Radius.circular(13),
                                ),
                              ),
                            ),
                          ),
                          // Percentage
                          Center(
                            child: Text(
                              '${(clampedProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Amount text
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$totalDrunk ml ',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: '/ $goal ml',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextHint
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Còn lại $remaining ml để đạt mục tiêu',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Quick Add ──
  Widget _buildQuickAddSection(LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amounts = [150, 250, 350, 500];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.getText(en: 'Quick Add', vi: 'Thêm nhanh'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(amounts.length, (i) {
            final isSelected = _selectedQuickAdd == i;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedQuickAdd = i);
                _addWater(amounts[i]);
              },
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: isSelected
                          ? AppColors.primary
                          : const Color(0xFF42A5F5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${amounts[i]} ml',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── History ──
  Widget _buildHistorySection(LanguageProvider lang, List todayHistory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maxVisible = 5;
    final displayList = _showAllHistory
        ? todayHistory
        : todayHistory.take(maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.getText(en: "Today's Log", vi: 'Lịch sử hôm nay'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            if (todayHistory.length > maxVisible)
              GestureDetector(
                onTap: () => setState(() => _showAllHistory = !_showAllHistory),
                child: Text(
                  _showAllHistory
                      ? lang.getText(en: 'Show less', vi: 'Thu gọn')
                      : '${lang.getText(en: 'View all', vi: 'Xem tất cả')} (${todayHistory.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (todayHistory.isEmpty)
          _buildEmptyHistory(lang)
        else
          ...List.generate(displayList.length, (i) {
            final log = displayList[i] as WaterTracking;
            final timeStr = DateFormat('hh:mm a').format(log.trackedAt);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.opacity,
                        color: Color(0xFF42A5F5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${log.amountMl} ml',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextHint
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _removeLog(log),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyHistory(LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade100,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 48,
              color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              lang.getText(
                en: 'No water logged today',
                vi: 'Chưa ghi nhận nước hôm nay',
              ),
              style: TextStyle(
                color: isDark ? AppColors.darkTextHint : Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Weekly Chart ──
  Widget _buildWeeklyChart(LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterProvider = context.watch<WaterTrackingProvider>();
    final weeklyData = waterProvider.weeklyData;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    // Calculate max for normalization
    int maxMl = 1;
    for (final day in weeklyData) {
      final ml = (day['totalMl'] as num?)?.toInt() ?? 0;
      if (ml > maxMl) maxMl = ml;
    }

    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.getText(en: '7-Day Trend', vi: 'Xu hướng 7 ngày'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
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
          child: SizedBox(
            height: 200,
            child: weeklyData.isEmpty
                ? Center(
                    child: Text(
                      lang.getText(en: 'No data yet', vi: 'Chưa có dữ liệu'),
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(weeklyData.length, (i) {
                      final day = weeklyData[i];
                      final dateStr = day['date'] as String? ?? '';
                      final totalMl = (day['totalMl'] as num?)?.toInt() ?? 0;
                      final isToday = dateStr == todayStr;
                      final heightFraction = totalMl / maxMl;

                      // Get day label from date
                      String label = '';
                      try {
                        final dt = DateTime.parse(dateStr);
                        final weekday = dt.weekday; // 1=Mon..7=Sun
                        label = dayLabels[weekday - 1];
                      } catch (_) {
                        label = '?';
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedBarIndex = _selectedBarIndex == i
                                ? null
                                : i;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Tooltip
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _selectedBarIndex == i && totalMl > 0
                                      ? OverflowBox(
                                          key: ValueKey('tip_$i'),
                                          maxWidth: 100,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isToday
                                                  ? AppColors.primary
                                                  : const Color(0xFF1A1A2E),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '$totalMl ml',
                                              textAlign: TextAlign.center,
                                              softWrap: false,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(
                                          key: ValueKey('empty'),
                                          height: 0,
                                        ),
                                ),
                                // Bar
                                Flexible(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: (110 * heightFraction).clamp(
                                      4.0,
                                      110.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedBarIndex == i
                                          ? (isToday
                                                ? AppColors.primary
                                                : const Color(0xFF1A1A2E))
                                          : isToday
                                          ? AppColors.primary
                                          : AppColors.primary.withValues(
                                              alpha:
                                                  0.15 + heightFraction * 0.4,
                                            ),
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: _selectedBarIndex == i
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        isToday || _selectedBarIndex == i
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isToday || _selectedBarIndex == i
                                        ? AppColors.primary
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Custom Painters ──

class _WaterRingPainter extends CustomPainter {
  final double progress;

  _WaterRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterRingPainter old) =>
      old.progress != progress;
}
