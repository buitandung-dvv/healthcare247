import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_config.dart';
import '../../providers/workout_plan_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../data/models/plan_model.dart';
import 'workout_session_screen.dart';
import 'create_workout_plan_screen.dart';
import 'plan_detail_screen.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key});

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  int _selectedDay = 0; // 0 = All, 1-7 = Monday to Sunday

  @override
  void initState() {
    super.initState();
    // Set default to today's day
    _selectedDay = DateTime.now().weekday;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkoutPlanProvider>().loadUserPlans();
        final exerciseProvider = context.read<ExerciseProvider>();
        final langProvider = context.read<LanguageProvider>();
        if (exerciseProvider.exercises.isEmpty && !exerciseProvider.isLoading) {
          exerciseProvider.loadExercises(languageId: langProvider.languageId);
        }
      }
    });
  }

  int _countUniqueExercises(List<Plan> plans) {
    final uniqueExerciseIds = <int>{};
    for (final plan in plans) {
      for (final detail in plan.details) {
        if (detail.exerciseId != null) {
          uniqueExerciseIds.add(detail.exerciseId!);
        }
      }
    }
    return uniqueExerciseIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<WorkoutPlanProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
              title: Text(
                lang.getText(en: 'My Plans', vi: 'Kế hoạch của tôi'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                      const Color(0xFF1565C0),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        Icons.fitness_center,
                        size: 180,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.sports_gymnastics,
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  context.read<WorkoutPlanProvider>().loadUserPlans();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          // Stats summary
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.calendar_today,
                    value: '${planProvider.userPlans.length}',
                    label: lang.getText(en: 'Plans', vi: 'Kế hoạch'),
                    color: AppColors.primary,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    icon: Icons.fitness_center,
                    value:
                        _countUniqueExercises(
                          planProvider.userPlans,
                        ).toString(),
                    label: lang.getText(en: 'Exercises', vi: 'Bài tập'),
                    color: Colors.orange,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    icon: Icons.local_fire_department,
                    value: '0',
                    label: lang.getText(en: 'Completed', vi: 'Hoàn thành'),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),

          // Day tabs
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDayTabs(lang),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Plans list
          if (planProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (planProvider.userPlans.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context, lang))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: Builder(
                builder: (context) {
                  // Filter plans by selected day
                  final filteredPlans =
                      _selectedDay == 0
                          ? planProvider.userPlans
                          : planProvider.userPlans.where((plan) {
                            return plan.details.any(
                              (d) => d.dayOfWeek == _selectedDay,
                            );
                          }).toList();

                  if (filteredPlans.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              lang.getText(
                                en: 'No plans for this day',
                                vi: 'Không có kế hoạch cho ngày này',
                              ),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final plan = filteredPlans[index];
                      return _buildPlanCard(context, plan, lang, index);
                    }, childCount: filteredPlans.length),
                  );
                },
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateWorkoutPlanScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: Text(
          lang.getText(en: 'New Plan', vi: 'Tạo mới'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDayTabs(LanguageProvider lang) {
    final dayLabels =
        lang.currentLanguage == 'vi'
            ? ['Tất cả', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
            : ['All', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Get current day of week (1=Mon, 7=Sun)
    final today = DateTime.now().weekday;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(8, (index) {
          final isSelected = _selectedDay == index;
          final isToday = index == today;

          return Padding(
            padding: EdgeInsets.only(right: index < 7 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? LinearGradient(
                            colors: [
                              AppColors.primary,
                              const Color(0xFF667EEA),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color:
                      isSelected
                          ? null
                          : (isToday
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      isToday && !isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : null,
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isToday && index != 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.white : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    Text(
                      dayLabels[index],
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : (isToday
                                    ? AppColors.primary
                                    : Colors.grey[700]),
                        fontWeight:
                            isSelected || isToday
                                ? FontWeight.w600
                                : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 50, width: 1, color: Colors.grey[200]);
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            lang.getText(
              en: 'No workout plans yet',
              vi: 'Chưa có kế hoạch tập luyện',
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.getText(
              en: 'Create your first plan to get started!',
              vi: 'Tạo kế hoạch đầu tiên để bắt đầu!',
            ),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWorkoutPlanScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text(lang.getText(en: 'Create Plan', vi: 'Tạo kế hoạch')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    Plan plan,
    LanguageProvider lang,
    int index,
  ) {
    final exerciseProvider = context.watch<ExerciseProvider>();

    // Get exercise images for hero section
    final List<String> exerciseImageUrls = [];
    String? randomHeroUrl;
    if (exerciseProvider.exercises.isNotEmpty && plan.details.isNotEmpty) {
      // Get up to 4 exercise images for 2x2 grid
      for (final detail in plan.details.take(4)) {
        final exercise = exerciseProvider.exercises.firstWhere(
          (e) => e.exerciseId == detail.exerciseId,
          orElse: () => exerciseProvider.exercises.first,
        );
        exerciseImageUrls.add(
          '${ApiConfig.imageBaseUrl}/images/exercises/${exercise.slug}/0.jpg',
        );
      }

      // For < 4 exercises, pick a random one from the list
      if (plan.details.length < 4 && exerciseImageUrls.isNotEmpty) {
        final random = Random();
        randomHeroUrl =
            exerciseImageUrls[random.nextInt(exerciseImageUrls.length)];
      }
    }
    final bool showGrid = plan.details.length >= 4;

    // Generate accent color based on index
    final colors = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
    ];
    final gradientColors = colors[index % colors.length];

    // Calculate estimated duration (2 min per exercise approx)
    final estimatedMinutes =
        plan.details.length * 2 +
        plan.details.fold<int>(
              0,
              (sum, d) => sum + ((d.sets ?? 3) * (d.restDuration ?? 30)),
            ) ~/
            60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanDetailScreen(plan: plan),
                ),
              );
            },
            child: Column(
              children: [
                // Hero image with gradient overlay
                Stack(
                  children: [
                    // Background image
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child:
                          exerciseImageUrls.isEmpty
                              ? null
                              : showGrid
                              ? _buildImageGrid(
                                exerciseImageUrls.take(4).toList(),
                              )
                              : CachedNetworkImage(
                                imageUrl:
                                    randomHeroUrl ?? exerciseImageUrls.first,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const SizedBox(),
                              ),
                    ),
                    // Gradient overlay
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            gradientColors[0].withValues(alpha: 0.7),
                            gradientColors[1].withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                    // Content overlay
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name ?? plan.planType ?? 'Workout Plan',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black26),
                              ],
                            ),
                          ),
                          if (plan.description != null &&
                              plan.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                plan.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Menu button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      lang.getText(en: 'Edit', vi: 'Chỉnh sửa'),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      lang.getText(en: 'Delete', vi: 'Xóa'),
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editPlan(plan);
                          } else if (value == 'delete') {
                            _deletePlan(context, plan);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Bottom info section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Exercise count
                      Flexible(
                        child: _buildInfoChip(
                          icon: Icons.fitness_center,
                          label: '${plan.details.length}',
                          color: gradientColors[0],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Duration estimate
                      Flexible(
                        child: _buildInfoChip(
                          icon: Icons.timer_outlined,
                          label: '${estimatedMinutes}m',
                          color: gradientColors[1],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Start button
                      ElevatedButton.icon(
                        onPressed: () => _startWorkout(plan),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          lang.getText(en: 'Start', vi: 'Bắt đầu'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gradientColors[0],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build 2x2 grid of exercise thumbnails
  Widget _buildImageGrid(List<String> imageUrls) {
    // Ensure we have exactly 4 images
    final urls = imageUrls.take(4).toList();
    while (urls.length < 4) {
      urls.add(urls.isNotEmpty ? urls.first : '');
    }

    Widget buildImage(String url) {
      return Expanded(
        child:
            url.isEmpty
                ? Container(
                  color: Colors.white24,
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white70,
                    size: 24,
                  ),
                )
                : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget:
                      (_, __, ___) => Container(
                        color: Colors.white24,
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              buildImage(urls[0]),
              const SizedBox(width: 2),
              buildImage(urls[1]),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Row(
            children: [
              buildImage(urls[2]),
              const SizedBox(width: 2),
              buildImage(urls[3]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _editPlan(Plan plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutPlanScreen(existingPlan: plan),
      ),
    );
    if (mounted) {
      context.read<WorkoutPlanProvider>().loadUserPlans();
    }
  }

  void _startWorkout(Plan plan) async {
    final provider = context.read<WorkoutPlanProvider>();
    final success = await provider.startSession(
      planId: plan.planId,
      name: plan.name ?? plan.planType,
    );

    if (!mounted || !success) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutSessionScreen()),
    );
  }

  void _deletePlan(BuildContext context, Plan plan) async {
    final lang = context.read<LanguageProvider>();
    final provider = context.read<WorkoutPlanProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang.getText(en: 'Delete Plan', vi: 'Xóa kế hoạch'),
                  ),
                ),
              ],
            ),
            content: Text(
              lang.getText(
                en:
                    'Are you sure you want to delete "${plan.name ?? plan.planType}"? This action cannot be undone.',
                vi:
                    'Bạn có chắc chắn muốn xóa "${plan.name ?? plan.planType}"? Hành động này không thể hoàn tác.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.getText(en: 'Cancel', vi: 'Hủy')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(lang.getText(en: 'Delete', vi: 'Xóa')),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      final success = await provider.deletePlan(plan.planId);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  success
                      ? lang.getText(
                        en: 'Plan deleted successfully',
                        vi: 'Đã xóa kế hoạch thành công',
                      )
                      : lang.getText(
                        en: 'Failed to delete plan',
                        vi: 'Lỗi khi xóa kế hoạch',
                      ),
                ),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        if (success) {
          await provider.loadUserPlans(languageId: lang.isVietnamese ? 2 : 1);
        }
      }
    }
  }
}
