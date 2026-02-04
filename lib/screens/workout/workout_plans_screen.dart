import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkoutPlanProvider>().loadUserPlans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<WorkoutPlanProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.getText(en: 'My Plans', vi: 'Kế hoạch tập luyện')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          planProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : planProvider.userPlans.isEmpty
              ? _buildEmptyState(context, lang)
              : ListView.builder(
                padding: const EdgeInsets.all(AppSizes.md),
                itemCount: planProvider.userPlans.length,
                itemBuilder: (context, index) {
                  final plan = planProvider.userPlans[index];
                  return _buildPlanCard(context, plan, lang);
                },
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
        icon: const Icon(Icons.add),
        label: Text(lang.getText(en: 'Create Plan', vi: 'Tạo kế hoạch')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
          const SizedBox(height: AppSizes.lg),
          Text(
            lang.getText(
              en: 'No workout plans yet',
              vi: 'Chưa có kế hoạch tập luyện',
            ),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            lang.getText(
              en: 'Create a plan to get started!',
              vi: 'Tạo kế hoạch để bắt đầu!',
            ),
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    Plan plan,
    LanguageProvider lang,
  ) {
    // Generate gradient colors based on plan name hash
    final nameHash = (plan.name ?? plan.planType ?? 'Plan').hashCode;
    final hue1 = (nameHash % 360).toDouble();
    final hue2 = ((nameHash ~/ 360) % 360).toDouble();
    final color1 = HSLColor.fromAHSL(1.0, hue1, 0.6, 0.5).toColor();
    final color2 = HSLColor.fromAHSL(1.0, hue2, 0.5, 0.6).toColor();

    // Get exercise thumbnails from provider
    final exerciseProvider = context.read<ExerciseProvider>();
    final exerciseImages = <String>[];
    for (final detail in plan.details.take(4)) {
      final exercise = exerciseProvider.exercises.firstWhere(
        (e) => e.exerciseId == detail.exerciseId,
        orElse:
            () =>
                exerciseProvider.exercises.isNotEmpty
                    ? exerciseProvider.exercises.first
                    : throw Exception('No exercises'),
      );
      final imageUrl =
          '${ApiConfig.imageBaseUrl}/images/exercises/${exercise.slug}/0.jpg';
      exerciseImages.add(imageUrl);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanDetailScreen(plan: plan),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Gradient container with 2x2 grid of thumbnails
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color1, color2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        exerciseImages.isEmpty
                            ? Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 28,
                            )
                            : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImageGrid(exerciseImages),
                            ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name ?? plan.planType ?? 'Workout Plan',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (plan.description != null)
                          Text(
                            plan.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text(lang.getText(en: 'Edit', vi: 'Sửa')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
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
                ],
              ),
              const SizedBox(height: AppSizes.md),
              const Divider(),
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${plan.details.length} ${lang.getText(en: 'Exercises', vi: 'Bài tập')}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _startWorkout(plan);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(lang.getText(en: 'Start', vi: 'Bắt đầu')),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build 2x2 grid of exercise thumbnails
  Widget _buildImageGrid(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return const Icon(Icons.fitness_center, color: Colors.white, size: 28);
    }

    // Only show grid if 4 or more exercises, otherwise show single image
    if (imageUrls.length < 4) {
      return Image.network(
        imageUrls[0],
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) => const Icon(
              Icons.fitness_center,
              color: Colors.white70,
              size: 24,
            ),
      );
    }

    // For 4+ images, create 2x2 grid
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children:
          imageUrls.take(4).map((url) {
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    color: Colors.white24,
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
            );
          }).toList(),
    );
  }

  void _editPlan(Plan plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutPlanScreen(existingPlan: plan),
      ),
    );
    // Refresh plans after returning from edit screen
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
            title: Text(lang.getText(en: 'Delete Plan', vi: 'Xóa kế hoạch')),
            content: Text(
              lang.getText(
                en:
                    'Are you sure you want to delete "${plan.name ?? plan.planType}"?',
                vi: 'Bạn có chắc chắn muốn xóa "${plan.name ?? plan.planType}"?',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.getText(en: 'Cancel', vi: 'Hủy')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            content: Text(
              success
                  ? lang.getText(en: 'Plan deleted', vi: 'Đã xóa kế hoạch')
                  : lang.getText(
                    en: 'Failed to delete plan',
                    vi: 'Lỗi khi xóa kế hoạch',
                  ),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        // Reload plans to sync with server
        if (success) {
          await provider.loadUserPlans(languageId: lang.isVietnamese ? 2 : 1);
        }
      }
    }
  }
}
