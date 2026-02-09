import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/exercise_model.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_plan_provider.dart';
import '../../widgets/common/common_widgets.dart';
import 'workout_session_screen.dart';

/// Start Workout Screen - Exercise selection with filters, presets, and AI suggestions
/// Only ONE method can be active at a time: Preset OR Filter OR AI Suggest
class StartWorkoutScreen extends StatefulWidget {
  const StartWorkoutScreen({super.key});

  @override
  State<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  // Selection mode - 'preset' | 'filter' | 'ai' | null
  String? _selectionMode;

  // Selected exercises
  final Set<int> _selectedExerciseIds = {};

  // Filter state
  String? _selectedLevel;
  String? _selectedMuscle;
  bool _showFilters = false;

  // Active preset
  String? _activePreset;

  // Loading state
  bool _isLoading = false;
  bool _isSuggesting = false;

  @override
  void initState() {
    super.initState();
    // Defer to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExercises();
    });
  }

  Future<void> _loadExercises() async {
    final langProvider = context.read<LanguageProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    if (exerciseProvider.exercises.isEmpty) {
      await exerciseProvider.loadExercises(
        languageId: langProvider.languageId,
        refresh: true,
      );
    }

    if (exerciseProvider.categories.isEmpty) {
      await exerciseProvider.loadFilterOptions(
        languageId: langProvider.languageId,
      );
    }
  }

  // Clear all and switch mode
  void _clearAndSwitchMode(String? mode) {
    _selectedExerciseIds.clear();
    _activePreset = null;
    _selectedLevel = null;
    _selectedMuscle = null;
    _showFilters = false;
    _selectionMode = mode;
  }

  // Preset definitions
  static const Map<String, List<String>> _presetMuscles = {
    'full_body': [],
    'upper_body': [
      'chest',
      'back',
      'shoulders',
      'biceps',
      'triceps',
      'forearms',
    ],
    'lower_body': ['quadriceps', 'hamstrings', 'glutes', 'calves'],
    'core': ['abdominals', 'lower back', 'obliques'],
  };

  void _selectPreset(String preset) {
    setState(() {
      if (_activePreset == preset) {
        // Deselect
        _clearAndSwitchMode(null);
      } else {
        // Clear other modes and switch to preset
        _clearAndSwitchMode('preset');
        _activePreset = preset;
        _applyPreset(preset);
      }
    });
  }

  void _applyPreset(String preset) {
    final exerciseProvider = context.read<ExerciseProvider>();
    final exercises = exerciseProvider.exercises;
    final targetMuscles = _presetMuscles[preset] ?? [];

    if (targetMuscles.isEmpty) {
      // Full body - select 6-8 random exercises
      final shuffled = List<Exercise>.from(exercises)..shuffle();
      for (var i = 0; i < 8 && i < shuffled.length; i++) {
        _selectedExerciseIds.add(shuffled[i].exerciseId);
      }
    } else {
      for (final exercise in exercises) {
        final primaryMuscle =
            exercise.primaryMuscles.isNotEmpty
                ? exercise.primaryMuscles.first.toLowerCase()
                : '';
        if (targetMuscles.any((m) => primaryMuscle.contains(m))) {
          _selectedExerciseIds.add(exercise.exerciseId);
          if (_selectedExerciseIds.length >= 6) break;
        }
      }
    }
  }

  Future<void> _suggestExercises() async {
    setState(() {
      _isSuggesting = true;
      _clearAndSwitchMode('ai');
    });

    try {
      final exerciseProvider = context.read<ExerciseProvider>();
      final exercises = exerciseProvider.exercises;

      final suggested = <Exercise>[];
      final byMuscle = <String, List<Exercise>>{};

      for (final e in exercises) {
        final muscle =
            e.primaryMuscles.isNotEmpty ? e.primaryMuscles.first : 'other';
        byMuscle.putIfAbsent(muscle, () => []).add(e);
      }

      for (final muscle in byMuscle.keys) {
        if (suggested.length >= 6) break;
        final muscleExercises = byMuscle[muscle]!;
        muscleExercises.shuffle();
        if (muscleExercises.isNotEmpty) {
          suggested.add(muscleExercises.first);
        }
      }

      setState(() {
        _selectedExerciseIds.addAll(suggested.map((e) => e.exerciseId));
      });
    } finally {
      setState(() => _isSuggesting = false);
    }
  }

  void _toggleExercise(int exerciseId) {
    setState(() {
      // If in preset/AI mode, clear and switch to filter mode for manual selection
      if (_selectionMode == 'preset' || _selectionMode == 'ai') {
        _clearAndSwitchMode('filter');
        _showFilters = true;
      }
      _selectionMode = 'filter';

      if (_selectedExerciseIds.contains(exerciseId)) {
        _selectedExerciseIds.remove(exerciseId);
      } else {
        _selectedExerciseIds.add(exerciseId);
      }
    });
  }

  void _openFilters() {
    setState(() {
      if (_selectionMode != 'filter') {
        _clearAndSwitchMode('filter');
      }
      _showFilters = !_showFilters;
    });
  }

  Future<void> _startWorkout() async {
    if (_selectedExerciseIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<WorkoutPlanProvider>();

      final success = await provider.startSession(
        exerciseId: _selectedExerciseIds.first,
        name: 'Custom Workout',
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkoutSessionScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Exercise> get _filteredExercises {
    final exerciseProvider = context.read<ExerciseProvider>();
    var exercises = exerciseProvider.exercises;

    if (_selectedLevel != null) {
      exercises =
          exercises
              .where(
                (e) => e.level.toLowerCase() == _selectedLevel!.toLowerCase(),
              )
              .toList();
    }

    if (_selectedMuscle != null) {
      exercises =
          exercises.where((e) {
            final muscle =
                e.primaryMuscles.isNotEmpty ? e.primaryMuscles.first : '';
            return muscle.toLowerCase().contains(
              _selectedMuscle!.toLowerCase(),
            );
          }).toList();
    }

    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();

    final isPresetMode = _selectionMode == 'preset';
    final isAiMode = _selectionMode == 'ai';
    final isFilterMode = _selectionMode == 'filter';

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText(en: 'Start Workout', vi: 'Bắt đầu tập')),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
        actions: [
          if (_selectionMode != null)
            TextButton(
              onPressed: () => setState(() => _clearAndSwitchMode(null)),
              child: Text(
                lang.getText(en: 'Clear', vi: 'Xóa'),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Section header showing active mode
          if (_selectionMode != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                _selectionMode == 'preset'
                    ? lang.getText(en: 'Mode: Preset', vi: 'Chế độ: Preset')
                    : _selectionMode == 'ai'
                    ? lang.getText(
                      en: 'Mode: AI Suggestion',
                      vi: 'Chế độ: AI gợi ý',
                    )
                    : lang.getText(
                      en: 'Mode: Manual Filter',
                      vi: 'Chế độ: Lọc thủ công',
                    ),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Quick Presets - disabled if in AI/Filter mode
          Opacity(
            opacity: isAiMode || isFilterMode ? 0.4 : 1.0,
            child: IgnorePointer(
              ignoring: isAiMode || isFilterMode,
              child: _buildPresetSection(lang),
            ),
          ),

          // AI Suggestion - disabled if in Preset/Filter mode
          Opacity(
            opacity: isPresetMode || isFilterMode ? 0.4 : 1.0,
            child: IgnorePointer(
              ignoring: isPresetMode || isFilterMode,
              child: _buildSuggestionButton(lang),
            ),
          ),

          // Filters - disabled if in Preset/AI mode
          Opacity(
            opacity: isPresetMode || isAiMode ? 0.4 : 1.0,
            child: IgnorePointer(
              ignoring: isPresetMode || isAiMode,
              child: _buildFilterSection(lang, exerciseProvider),
            ),
          ),

          Expanded(child: _buildExerciseList(exerciseProvider, lang)),
          _buildStartButton(lang),
        ],
      ),
    );
  }

  Widget _buildPresetSection(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPresetChip(
              Icons.accessibility_new,
              lang.getText(en: 'Full Body', vi: 'Toàn thân'),
              _activePreset == 'full_body',
              () => _selectPreset('full_body'),
            ),
            const SizedBox(width: AppSizes.sm),
            _buildPresetChip(
              Icons.fitness_center,
              lang.getText(en: 'Upper Body', vi: 'Thân trên'),
              _activePreset == 'upper_body',
              () => _selectPreset('upper_body'),
            ),
            const SizedBox(width: AppSizes.sm),
            _buildPresetChip(
              Icons.directions_walk,
              lang.getText(en: 'Lower Body', vi: 'Thân dưới'),
              _activePreset == 'lower_body',
              () => _selectPreset('lower_body'),
            ),
            const SizedBox(width: AppSizes.sm),
            _buildPresetChip(
              Icons.sports_gymnastics,
              lang.getText(en: 'Core', vi: 'Cơ bụng'),
              _activePreset == 'core',
              () => _selectPreset('core'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionButton(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            onTap: _isSuggesting ? null : _suggestExercises,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSuggesting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    lang.getText(
                      en: 'Suggest exercises for me',
                      vi: 'Gợi ý bài tập cho tôi',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(LanguageProvider lang, ExerciseProvider provider) {
    return Column(
      children: [
        InkWell(
          onTap: _openFilters,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  lang.getText(en: 'Filters', vi: 'Bộ lọc'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (_selectedLevel != null || _selectedMuscle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      '${[_selectedLevel, _selectedMuscle].where((e) => e != null).length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                Icon(_showFilters ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (_showFilters)
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md,
                  0,
                  AppSizes.md,
                  AppSizes.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.getText(en: 'Level', vi: 'Cấp độ'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Wrap(
                      spacing: AppSizes.xs,
                      children:
                          ['beginner', 'intermediate', 'expert'].map((level) {
                            return ChoiceChip(
                              label: Text(level),
                              selected: _selectedLevel == level,
                              onSelected:
                                  (selected) => setState(
                                    () =>
                                        _selectedLevel =
                                            selected ? level : null,
                                  ),
                              backgroundColor:
                                  isDark ? AppColors.darkCard : null,
                              selectedColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              side: BorderSide(
                                color:
                                    _selectedLevel == level
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : Colors.grey.shade300),
                              ),
                              labelStyle: TextStyle(
                                color:
                                    _selectedLevel == level
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.textWhite
                                            : AppColors.textPrimary),
                                fontWeight:
                                    _selectedLevel == level
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      lang.getText(en: 'Muscle', vi: 'Nhóm cơ'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children:
                            provider.muscles.map((muscle) {
                              final name = muscle['name']?.toString() ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSizes.xs,
                                ),
                                child: ChoiceChip(
                                  label: Text(name),
                                  selected: _selectedMuscle == name,
                                  onSelected:
                                      (selected) => setState(
                                        () =>
                                            _selectedMuscle =
                                                selected ? name : null,
                                      ),
                                  backgroundColor:
                                      isDark ? AppColors.darkCard : null,
                                  selectedColor: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  side: BorderSide(
                                    color:
                                        _selectedMuscle == name
                                            ? AppColors.primary
                                            : (isDark
                                                ? AppColors.darkBorder
                                                : Colors.grey.shade300),
                                  ),
                                  labelStyle: TextStyle(
                                    color:
                                        _selectedMuscle == name
                                            ? AppColors.primary
                                            : (isDark
                                                ? AppColors.textWhite
                                                : AppColors.textPrimary),
                                    fontWeight:
                                        _selectedMuscle == name
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildExerciseList(ExerciseProvider provider, LanguageProvider lang) {
    if (provider.isLoading && provider.exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final exercises = _filteredExercises;

    if (exercises.isEmpty) {
      return Center(
        child: Text(
          lang.getText(en: 'No exercises found', vi: 'Không tìm thấy bài tập'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final isSelected = _selectedExerciseIds.contains(exercise.exerciseId);

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          child: InkWell(
            onTap: () => _toggleExercise(exercise.exerciseId),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.sm),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    child:
                        exercise.images.isNotEmpty
                            ? Image.network(
                              exercise.images.first,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                            : _buildPlaceholder(),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${exercise.primaryMuscles.isNotEmpty ? exercise.primaryMuscles.first : ''} • ${exercise.level}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: AppColors.border,
      child: const Icon(Icons.fitness_center, color: AppColors.textHint),
    );
  }

  Widget _buildStartButton(LanguageProvider lang) {
    final count = _selectedExerciseIds.length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            text:
                count > 0
                    ? lang.getText(
                      en: 'Start with $count exercises',
                      vi: 'Bắt đầu với $count bài tập',
                    )
                    : lang.getText(en: 'Select exercises', vi: 'Chọn bài tập'),
            onPressed: count > 0 ? _startWorkout : null,
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}
