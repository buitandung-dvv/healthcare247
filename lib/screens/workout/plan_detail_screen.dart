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
        title: Text(widget.plan.name ?? widget.plan.planType ?? 'Plan Detail'),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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

          // Exercise list
          Expanded(
            child:
                widget.plan.details.isEmpty
                    ? Center(
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
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: widget.plan.details.length,
                      itemBuilder: (context, index) {
                        final detail = widget.plan.details[index];
                        return _buildExerciseCard(context, detail, index, lang);
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
            child: ElevatedButton.icon(
              onPressed: () => _startWorkout(context),
              icon: const Icon(Icons.play_arrow, size: 24),
              label: Text(
                lang.getText(en: 'Start Workout', vi: 'Bắt đầu tập'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
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
    final provider = context.read<WorkoutPlanProvider>();
    final success = await provider.startSession(
      planId: widget.plan.planId,
      name: widget.plan.name ?? widget.plan.planType,
    );

    if (!context.mounted || !success) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutSessionScreen()),
    );
  }
}
