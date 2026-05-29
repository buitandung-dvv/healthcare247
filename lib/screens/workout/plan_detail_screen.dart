import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_config.dart';
import '../../data/models/plan_model.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_plan_provider.dart';
import '../../providers/exercise_provider.dart';
import 'workout_session_screen.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure exercises are loaded for thumbnails
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exerciseProvider = context.read<ExerciseProvider>();
      if (exerciseProvider.exercises.isEmpty) {
        exerciseProvider.loadExercises();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    // Watch ExerciseProvider to rebuild when exercises load
    context.watch<ExerciseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.plan.name ?? widget.plan.planType ?? 'Plan Detail',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF0F172A),
                size: 20,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: const Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description if exists
          if (widget.plan.description != null &&
              widget.plan.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.plan.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ),

          // Exercise list - show all exercises (allow duplicates for interleaved workouts)
          Expanded(
            child: Builder(
              builder: (context) {
                final allDetails = widget.plan.details;

                if (allDetails.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang.getText(
                            en: 'No exercises in this plan',
                            vi: 'Chưa có bài tập nào',
                          ),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: allDetails.length,
                  itemBuilder: (context, index) {
                    final detail = allDetails[index];
                    return _buildExerciseCard(context, detail, index, lang);
                  },
                );
              },
            ),
          ),

          // Start button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => _startWorkout(context),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      lang.getText(en: 'Start Workout', vi: 'Bắt đầu tập'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    PlanDetail detail,
    int index,
    LanguageProvider lang,
  ) {
    // Get exercise slug for thumbnail
    final exerciseProvider = context.read<ExerciseProvider>();
    String? thumbnailUrl;

    // Try to find matching exercise - handle both int and string comparison
    final detailExerciseId = detail.exerciseId;
    for (final exercise in exerciseProvider.exercises) {
      if (exercise.exerciseId == detailExerciseId) {
        thumbnailUrl =
            '${ApiConfig.imageBaseUrl}/images/exercises/${exercise.slug}/0.jpg';
        debugPrint('Found exercise: ${exercise.slug}, URL: $thumbnailUrl');
        break;
      }
    }

    debugPrint(
      'Detail exerciseId: $detailExerciseId, thumbnailUrl: $thumbnailUrl, total exercises: ${exerciseProvider.exercises.length}',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Index badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${(detail.orderIndex ?? index) + 1}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Exercise thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  thumbnailUrl != null
                      ? Image.network(
                        thumbnailUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.fitness_center,
                                color: Colors.grey[400],
                                size: 24,
                              ),
                            ),
                      )
                      : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
            ),
            const SizedBox(width: 12),

            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.exerciseName ?? 'Exercise',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${detail.sets ?? 3} sets × ${detail.reps ?? 10} reps · ${detail.restDuration ?? 60}s rest',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final provider = context.read<WorkoutPlanProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    debugPrint('Starting workout with planId: ${widget.plan.planId}');

    final success = await provider.startSession(
      planId: widget.plan.planId,
      name: widget.plan.name ?? widget.plan.planType,
    );

    // Hide loading
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (!context.mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WorkoutSessionScreen()),
      );
    } else {
      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                lang.getText(
                  en: 'Failed to start workout. Please try again.',
                  vi: 'Không thể bắt đầu tập. Vui lòng thử lại.',
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
