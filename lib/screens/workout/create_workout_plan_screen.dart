import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/network/api_config.dart';
import '../../providers/workout_plan_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/plan_model.dart';
import '../exercises/exercise_detail_screen.dart';

class CreateWorkoutPlanScreen extends StatefulWidget {
  final Plan?
  existingPlan; // If passing to edit, but for now we focus on create

  const CreateWorkoutPlanScreen({super.key, this.existingPlan});

  @override
  State<CreateWorkoutPlanScreen> createState() =>
      _CreateWorkoutPlanScreenState();
}

class _CreateWorkoutPlanScreenState extends State<CreateWorkoutPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  // Staging exercises before saving to backend
  // In a real app we might want to save the plan first then add details,
  // or build a local list and save all at once.
  // Given APIs: Create Plan -> Get ID -> Add Details loop.
  // We will assume "Save" creates the plan and adds details.

  final List<_StagedExercise> _stagedExercises = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingPlan?.name ?? widget.existingPlan?.planType ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingPlan?.description ?? '',
    );

    // Load existing exercises when editing plan
    if (widget.existingPlan != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingExercises();
      });
    }
  }

  void _loadExistingExercises() async {
    final exerciseProvider = context.read<ExerciseProvider>();

    // Ensure exercises are loaded
    if (exerciseProvider.exercises.isEmpty) {
      await exerciseProvider.loadExercises();
    }

    if (!mounted) return;

    final details = widget.existingPlan!.details;

    for (final detail in details) {
      if (detail.exerciseId != null) {
        // Find exercise in provider
        final exercise = exerciseProvider.exercises.firstWhere(
          (e) => e.exerciseId == detail.exerciseId,
          orElse:
              () => Exercise(
                exerciseId: detail.exerciseId!,
                name: detail.exerciseName ?? 'Unknown Exercise',
                slug: '',
                level: 'beginner',
                category: 'strength',
              ),
        );

        setState(() {
          _stagedExercises.add(
            _StagedExercise(
              exercise: exercise,
              sets: detail.sets ?? 3,
              reps: detail.reps ?? 10,
              restDuration: detail.restDuration ?? 60,
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final planProvider = context.watch<WorkoutPlanProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingPlan == null
              ? lang.getText(en: 'Create Workout Plan', vi: 'Tạo kế hoạch tập')
              : lang.getText(en: 'Edit Plan', vi: 'Sửa kế hoạch'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: planProvider.isLoading ? null : () => _savePlan(lang),
            child:
                planProvider.isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      lang.getText(en: 'Save', vi: 'Lưu'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: lang.getText(en: 'Plan Name', vi: 'Tên kế hoạch'),
                  hintText: lang.getText(
                    en: 'e.g., Full Body Monday',
                    vi: 'VD: Tập toàn thân thứ 2',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return lang.getText(
                      en: 'Please enter a name',
                      vi: 'Vui lòng nhập tên',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: lang.getText(
                    en: 'Description (Optional)',
                    vi: 'Mô tả (Tùy chọn)',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.getText(en: 'Exercises', vi: 'Bài tập'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showExerciseSelector(context),
                    icon: const Icon(Icons.add),
                    label: Text(
                      lang.getText(en: 'Add Exercise', vi: 'Thêm bài tập'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              if (_stagedExercises.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    lang.getText(
                      en:
                          'No exercises added yet.\nTap "Add Exercise" to start building your plan.',
                      vi:
                          'Chưa có bài tập nào.\nNhấn "Thêm bài tập" để xây dựng kế hoạch.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _stagedExercises.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = _stagedExercises.removeAt(oldIndex);
                      _stagedExercises.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = _stagedExercises[index];
                    return _buildExerciseItem(context, index, item, lang);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(
    BuildContext context,
    int index,
    _StagedExercise item,
    LanguageProvider lang,
  ) {
    // Build thumbnail URL
    final thumbnailUrl =
        '${ApiConfig.imageBaseUrl}/images/exercises/${item.exercise.slug}/0.jpg';

    return Card(
      key: ValueKey(item), // Important for reorderable list
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ExerciseDetailScreen(
                    exercise: item.exercise,
                    hideActions: true, // Ẩn buttons vì đang tạo plan
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Index badge
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  thumbnailUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.grey[400],
                          size: 22,
                        ),
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
                      item.exercise.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.sets} sets × ${item.reps} reps · ${item.restDuration}s rest',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editExerciseConfig(index, item),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _stagedExercises.removeAt(index);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseSelector(BuildContext context) {
    Set<int> selectedIds = {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              // Use StatefulBuilder to manage selection state locally within the sheet
              return StatefulBuilder(
                builder: (context, setSheetState) {
                  // Local state for selected exercises
                  // Note: We need to initialize this. relying on a closure variable
                  // defined *outside* valid scope is risky if we don't define it here.
                  // However, since we can't define variables easily inside build(),
                  // we'll rely on a surrounding variable or just rebuild.
                  // Better approach: Since we can't declare variables here easily without
                  // init state, let's assume we use a Set passed to a custom widget or
                  // just manage it via checking `selectedExercises.contains`.
                  // Actually, simply defining `Set<int> selectedIds = {};` inside `_showExerciseSelector`
                  // before calling `showModalBottomSheet` captures it in closure!
                  // But `StatefulBuilder` is needed to update the UI of the sheet.

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Row(
                            children: [
                              const CloseButton(),
                              Expanded(
                                child: Text(
                                  context.read<LanguageProvider>().getText(
                                    en: 'Select Exercises',
                                    vi: 'Chọn bài tập',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    selectedIds.isEmpty
                                        ? null
                                        : () {
                                          final provider =
                                              context.read<ExerciseProvider>();
                                          final selected =
                                              provider.exercises
                                                  .where(
                                                    (e) => selectedIds.contains(
                                                      e.exerciseId,
                                                    ),
                                                  )
                                                  .toList();

                                          for (var e in selected) {
                                            _addExercise(e);
                                          }
                                          Navigator.pop(context);
                                        },
                                child: Text(
                                  context.read<LanguageProvider>().getText(
                                    en: 'Add (${selectedIds.length})',
                                    vi: 'Thêm (${selectedIds.length})',
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        selectedIds.isEmpty
                                            ? Colors.grey
                                            : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Consumer<ExerciseProvider>(
                            builder: (context, exerciseProvider, child) {
                              if (exerciseProvider.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              return ListView.builder(
                                controller: scrollController,
                                itemCount: exerciseProvider.exercises.length,
                                itemBuilder: (context, index) {
                                  final exercise =
                                      exerciseProvider.exercises[index];
                                  final isSelected = selectedIds.contains(
                                    exercise.exerciseId,
                                  );

                                  // Count how many times this exercise is already in the plan
                                  final existingCount =
                                      _stagedExercises
                                          .where(
                                            (e) =>
                                                e.exercise.exerciseId ==
                                                exercise.exerciseId,
                                          )
                                          .length;

                                  return ListTile(
                                    leading: Stack(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            image:
                                                exercise.images.isNotEmpty
                                                    ? DecorationImage(
                                                      image: NetworkImage(
                                                        exercise.images.first,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                    : null,
                                          ),
                                          child:
                                              exercise.images.isEmpty
                                                  ? const Icon(
                                                    Icons.fitness_center,
                                                    color: Colors.grey,
                                                  )
                                                  : null,
                                        ),
                                        if (isSelected)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.7),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        // Show count badge if already in plan
                                        if (existingCount > 0)
                                          Positioned(
                                            right: -2,
                                            top: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Text(
                                                '$existingCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(exercise.name),
                                    subtitle: Row(
                                      children: [
                                        Text(exercise.category),
                                        if (existingCount > 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Đã thêm $existingCount',
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    onTap: () {
                                      setSheetState(() {
                                        if (isSelected) {
                                          selectedIds.remove(
                                            exercise.exerciseId,
                                          );
                                        } else {
                                          selectedIds.add(exercise.exerciseId);
                                        }
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _stagedExercises.add(_StagedExercise(exercise: exercise));
    });
  }

  void _editExerciseConfig(int index, _StagedExercise item) {
    // Show dialog to edit sets/reps
    // Simplified for now
    showDialog(
      context: context,
      builder: (context) {
        int sets = item.sets;
        int reps = item.reps;
        int rest = item.restDuration;

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text(item.exercise.name),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNumberInput(
                      'Sets',
                      sets,
                      (val) => setState(() => sets = val),
                    ),
                    _buildNumberInput(
                      'Reps',
                      reps,
                      (val) => setState(() => reps = val),
                    ),
                    _buildNumberInput(
                      'Rest (s)',
                      rest,
                      (val) => setState(() => rest = val),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      this.setState(() {
                        _stagedExercises[index] = item.copyWith(
                          sets: sets,
                          reps: reps,
                          restDuration: rest,
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildNumberInput(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onChanged(value > 1 ? value - 1 : 1),
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }

  void _savePlan(LanguageProvider lang) async {
    if (!_formKey.currentState!.validate()) return;
    if (_stagedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.getText(
              en: 'Please add at least one exercise',
              vi: 'Vui lòng thêm ít nhất một bài tập',
            ),
          ),
        ),
      );
      return;
    }

    // Check for at least 2 different exercises
    final uniqueExerciseIds =
        _stagedExercises.map((e) => e.exercise.exerciseId).toSet();
    if (uniqueExerciseIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.getText(
              en: 'Please add at least 2 different exercises',
              vi: 'Vui lòng thêm ít nhất 2 bài tập khác nhau',
            ),
          ),
        ),
      );
      return;
    }

    final provider = context.read<WorkoutPlanProvider>();
    final isEditing = widget.existingPlan != null;

    int planId;

    if (isEditing) {
      // Update existing plan
      planId = widget.existingPlan!.planId;
      final success = await provider.updatePlan(
        planId,
        name: _nameController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang.getText(
                  en: 'Failed to update plan',
                  vi: 'Lỗi khi cập nhật kế hoạch',
                ),
              ),
            ),
          );
        }
        return;
      }

      // Delete old details and add new ones
      await provider.clearPlanDetails(planId);
    } else {
      // Create new plan
      final plan = await provider.createPlan(
        _nameController.text,
        description:
            _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
      );

      if (plan == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang.getText(
                  en: 'Failed to create plan',
                  vi: 'Lỗi khi tạo kế hoạch',
                ),
              ),
            ),
          );
        }
        return;
      }
      planId = plan.planId;
    }

    // Add all exercises to plan
    for (int i = 0; i < _stagedExercises.length; i++) {
      final item = _stagedExercises[i];
      await provider.addExerciseToPlan(
        planId: planId,
        dayOfWeek: 1, // Default to Monday for now
        exerciseId: item.exercise.exerciseId,
        sets: item.sets,
        reps: item.reps,
        restDuration: item.restDuration,
        orderIndex: i,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.getText(
              en:
                  isEditing
                      ? 'Plan updated successfully!'
                      : 'Plan created successfully!',
              vi:
                  isEditing
                      ? 'Đã cập nhật kế hoạch thành công!'
                      : 'Đã tạo kế hoạch thành công!',
            ),
          ),
        ),
      );
    }
  }
}

class _StagedExercise {
  final Exercise exercise;
  final int sets;
  final int reps;
  final int restDuration;

  _StagedExercise({
    required this.exercise,
    this.sets = 3,
    this.reps = 10,
    this.restDuration = 60,
  });

  _StagedExercise copyWith({int? sets, int? reps, int? restDuration}) {
    return _StagedExercise(
      exercise: exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restDuration: restDuration ?? this.restDuration,
    );
  }
}
