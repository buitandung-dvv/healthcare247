import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../data/models/exercise_model.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_plan_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../workout/workout_session_screen.dart';

/// Exercise Detail Screen - Chi tiết bài tập
class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final bool hideActions; // Ẩn buttons khi xem từ màn hình tạo plan

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.hideActions = false,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  int _currentImageIndex = 0;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    if (widget.exercise.images.length >= 2) {
      _startImageAnimation();
    }
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startImageAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 800), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % widget.exercise.images.length;
        });
      }
    });
  }

  void _showWorkoutTimer(LanguageProvider langProvider) async {
    // Navigate to new Workout Session Screen
    final provider = context.read<WorkoutPlanProvider>();
    final success = await provider.startSession(
      exerciseId: widget.exercise.exerciseId,
      name: widget.exercise.name,
    );

    if (!mounted || !success) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutSessionScreen()),
    );
  }

  void _showAddToPlanDialog(
    BuildContext context,
    LanguageProvider langProvider,
  ) {
    final planProvider = context.read<WorkoutPlanProvider>();

    // Load plans if not loaded
    if (planProvider.userPlans.isEmpty && !planProvider.isLoading) {
      planProvider.loadUserPlans(languageId: langProvider.languageId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => _AddToPlanSheet(
            exercise: widget.exercise,
            langProvider: langProvider,
            planProvider: planProvider,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final exercise = widget.exercise;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Animated Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  exercise.images.isNotEmpty
                      ? _AnimatedHeaderImage(
                        images: exercise.images,
                        currentIndex: _currentImageIndex,
                      )
                      : Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: AppColors.textWhite,
                        ),
                      ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(AppSizes.xs),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Play/Pause animation button
              if (exercise.images.length >= 2)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(AppSizes.xs),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _animationTimer?.isActive == true
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      if (_animationTimer?.isActive == true) {
                        _animationTimer?.cancel();
                      } else {
                        _startImageAnimation();
                      }
                    });
                  },
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSizes.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Level
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      LevelBadge(level: exercise.level),
                      const SizedBox(width: AppSizes.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: Text(
                          exercise.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Description
                  if (exercise.description != null) ...[
                    Text(
                      langProvider.getText(en: 'Description', vi: 'Mô tả'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      exercise.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  // Info Cards
                  _buildInfoCards(context, langProvider),
                  const SizedBox(height: AppSizes.lg),

                  // Primary Muscles
                  if (exercise.primaryMuscles.isNotEmpty) ...[
                    _buildMuscleSection(
                      context,
                      title: langProvider.getText(
                        en: 'Primary Muscles',
                        vi: 'Nhóm cơ chính',
                      ),
                      muscles: exercise.primaryMuscles,
                      isPrimary: true,
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],

                  // Secondary Muscles
                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    _buildMuscleSection(
                      context,
                      title: langProvider.getText(
                        en: 'Secondary Muscles',
                        vi: 'Nhóm cơ phụ',
                      ),
                      muscles: exercise.secondaryMuscles,
                      isPrimary: false,
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  // Exercise Images Gallery
                  if (exercise.images.length > 1) ...[
                    Text(
                      langProvider.getText(
                        en: 'Exercise Images',
                        vi: 'Hình ảnh bài tập',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: exercise.images.length,
                        itemBuilder: (context, index) {
                          return _ExerciseImageCard(
                            imageUrl: exercise.images[index],
                            index: index,
                            total: exercise.images.length,
                            onTap:
                                () => _showImageViewer(
                                  context,
                                  exercise.images,
                                  index,
                                ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  // Instructions
                  if (exercise.instructions.isNotEmpty) ...[
                    Text(
                      langProvider.getText(
                        en: 'Instructions',
                        vi: 'Hướng dẫn thực hiện',
                      ),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    ...exercise.instructions.asMap().entries.map((entry) {
                      return _InstructionStep(
                        stepNumber: entry.key + 1,
                        instruction: entry.value,
                      );
                    }),
                    const SizedBox(height: AppSizes.lg),
                  ],

                  // Action Buttons - Ẩn khi xem từ màn hình tạo plan
                  if (!widget.hideActions) ...[
                    // Start button full width
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: langProvider.getText(en: 'Start', vi: 'Bắt đầu'),
                        icon: Icons.play_arrow,
                        onPressed: () => _showWorkoutTimer(langProvider),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    // Add to plan button full width
                    SizedBox(
                      width: double.infinity,
                      child: SecondaryButton(
                        text: langProvider.getText(
                          en: 'Add to Plan',
                          vi: 'Thêm vào kế hoạch',
                        ),
                        icon: Icons.add,
                        onPressed:
                            () => _showAddToPlanDialog(context, langProvider),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context, LanguageProvider langProvider) {
    final exercise = widget.exercise;
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.sports_gymnastics,
            title: langProvider.getText(en: 'Equipment', vi: 'Thiết bị'),
            value:
                exercise.equipment ??
                langProvider.getText(en: 'Body only', vi: 'Không cần'),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _InfoCard(
            icon: Icons.repeat,
            title: langProvider.getText(en: 'Mechanic', vi: 'Cơ chế'),
            value: exercise.mechanic ?? '-',
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _InfoCard(
            icon: Icons.arrow_forward,
            title: langProvider.getText(en: 'Force', vi: 'Lực'),
            value: exercise.force ?? '-',
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleSection(
    BuildContext context, {
    required String title,
    required List<String> muscles,
    required bool isPrimary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children:
              muscles.map((muscle) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isPrimary
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.background,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                      color: isPrimary ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    muscle,
                    style: TextStyle(
                      color:
                          isPrimary
                              ? AppColors.primary
                              : AppColors.textSecondary,
                      fontWeight:
                          isPrimary ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showImageViewer(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                _ImageViewerScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

class _ExerciseImageCard extends StatelessWidget {
  final String imageUrl;
  final int index;
  final int total;
  final VoidCallback onTap;

  const _ExerciseImageCard({
    required this.imageUrl,
    required this.index,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 280,
                height: 200,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      width: 280,
                      height: 200,
                      color: AppColors.background,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      width: 280,
                      height: 200,
                      color: AppColors.background,
                      child: const Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                    ),
              ),
            ),
            // Image counter badge
            Positioned(
              right: AppSizes.sm,
              bottom: AppSizes.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '${index + 1}/$total',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageViewerScreen({required this.images, required this.initialIndex});

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                errorWidget:
                    (context, url, error) => const Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: Colors.white54,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSizes.paddingSm,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
          const SizedBox(height: AppSizes.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int stepNumber;
  final String instruction;

  const _InstructionStep({required this.stepNumber, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated Header Image for Exercise Detail
class _AnimatedHeaderImage extends StatelessWidget {
  final List<String> images;
  final int currentIndex;

  const _AnimatedHeaderImage({
    required this.images,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Animated image switching
        ...images.asMap().entries.map((entry) {
          final isVisible = entry.key == currentIndex;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isVisible ? 1.0 : 0.0,
            child: CachedNetworkImage(
              imageUrl: entry.value,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    color: AppColors.background,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
            ),
          );
        }),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),

        // Image indicator
        if (images.length >= 2)
          Positioned(
            bottom: AppSizes.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_filled,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        '${currentIndex + 1}/${images.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WorkoutTimerSheet extends StatefulWidget {
  final String exerciseName;
  final LanguageProvider langProvider;

  const _WorkoutTimerSheet({
    required this.exerciseName,
    required this.langProvider,
  });

  @override
  State<_WorkoutTimerSheet> createState() => _WorkoutTimerSheetState();
}

class _WorkoutTimerSheetState extends State<_WorkoutTimerSheet> {
  int _sets = 0;
  int _reps = 0;
  int _seconds = 0;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _seconds++);
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _finishWorkout() {
    _timer?.cancel();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.langProvider.getText(
            en: 'Workout completed! $_sets sets, $_reps reps',
            vi: 'Hoàn thành tập! $_sets hiệp, $_reps lần',
          ),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.langProvider;
    return Container(
      padding: AppSizes.paddingMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.exerciseName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.lg),
          Container(
            padding: AppSizes.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              _formatTime(_seconds),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CounterWidget(
                label: lang.getText(en: 'Sets', vi: 'Hiệp'),
                value: _sets,
                onIncrement: () => setState(() => _sets++),
                onDecrement:
                    () => setState(() {
                      if (_sets > 0) _sets--;
                    }),
              ),
              _CounterWidget(
                label: lang.getText(en: 'Reps', vi: 'Lần'),
                value: _reps,
                onIncrement: () => setState(() => _reps++),
                onDecrement:
                    () => setState(() {
                      if (_reps > 0) _reps--;
                    }),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    _isRunning
                        ? lang.getText(en: 'Pause', vi: 'Tạm dừng')
                        : lang.getText(en: 'Start', vi: 'Bắt đầu'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _finishWorkout,
                  icon: const Icon(Icons.check),
                  label: Text(lang.getText(en: 'Finish', vi: 'Hoàn thành')),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }
}

class _CounterWidget extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CounterWidget({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSizes.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.primary,
            ),
            Text(
              '$value',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottom Sheet để chọn kế hoạch thêm bài tập
class _AddToPlanSheet extends StatefulWidget {
  final Exercise exercise;
  final LanguageProvider langProvider;
  final WorkoutPlanProvider planProvider;

  const _AddToPlanSheet({
    required this.exercise,
    required this.langProvider,
    required this.planProvider,
  });

  @override
  State<_AddToPlanSheet> createState() => _AddToPlanSheetState();
}

class _AddToPlanSheetState extends State<_AddToPlanSheet> {
  final _newPlanController = TextEditingController();
  bool _isCreatingNew = false;
  int? _selectedPlanId; // Kế hoạch đang xem chi tiết
  final Set<int> _selectedDays =
      {}; // Các ngày được chọn cho kế hoạch mới (1-7)

  @override
  void dispose() {
    _newPlanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.langProvider;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_selectedPlanId != null)
                      IconButton(
                        onPressed: () => setState(() => _selectedPlanId = null),
                        icon: const Icon(Icons.arrow_back),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (_selectedPlanId != null) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedPlanId != null
                            ? _getSelectedPlanName()
                            : lang.getText(
                              en: 'Add to Plan',
                              vi: 'Thêm vào kế hoạch',
                            ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child:
                    _selectedPlanId != null
                        ? _buildPlanDetailView(scrollController)
                        : _buildMainView(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSelectedPlanName() {
    final plan = widget.planProvider.userPlans.firstWhere(
      (p) => p.planId == _selectedPlanId,
      orElse: () => widget.planProvider.userPlans.first,
    );
    return plan.name ?? 'Unnamed';
  }

  Widget _buildMainView(ScrollController scrollController) {
    final lang = widget.langProvider;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Exercise info với hình ảnh thực tế
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Hình ảnh bài tập
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    widget.exercise.images.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: widget.exercise.images.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                width: 60,
                                height: 60,
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.primary,
                                ),
                              ),
                        )
                        : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.fitness_center,
                            color: AppColors.primary,
                          ),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.exercise.category,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Create new plan section
        Text(
          lang.getText(en: 'Create New', vi: 'Tạo mới'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _isCreatingNew = !_isCreatingNew),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  lang.getText(en: 'Create New Plan', vi: 'Tạo kế hoạch mới'),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(
                  _isCreatingNew
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        // New plan input - Card style
        if (_isCreatingNew) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  AppColors.secondary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name input
                TextField(
                  controller: _newPlanController,
                  decoration: InputDecoration(
                    hintText: lang.getText(
                      en: 'Enter plan name',
                      vi: 'Nhập tên kế hoạch',
                    ),
                    prefixIcon: const Icon(Icons.edit_outlined, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Day selector label
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lang.getText(en: 'Training days', vi: 'Chọn ngày tập'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Day chips in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                    final isSelected = _selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedDays.remove(day);
                          } else {
                            _selectedDays.add(day);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient:
                              isSelected
                                  ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.transparent
                                    : AppColors.border,
                            width: 1.5,
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Center(
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        widget.planProvider.isLoading
                            ? null
                            : _createNewPlanAndAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon:
                        widget.planProvider.isLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(
                      lang.getText(
                        en: 'Create & Add Exercise',
                        vi: 'Tạo và thêm bài tập',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Existing plans section
        Text(
          lang.getText(en: 'Existing Plans', vi: 'Kế hoạch có sẵn'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        ListenableBuilder(
          listenable: widget.planProvider,
          builder: (context, _) {
            if (widget.planProvider.isLoading &&
                widget.planProvider.userPlans.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (widget.planProvider.userPlans.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    lang.getText(
                      en: 'No plans yet. Create one above!',
                      vi: 'Chưa có kế hoạch nào',
                    ),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return Column(
              children:
                  widget.planProvider.userPlans.map((plan) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.folder_outlined,
                            color: AppColors.secondary,
                          ),
                        ),
                        title: Text(
                          plan.name ?? 'Unnamed',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${plan.details.length} ${lang.getText(en: 'exercises', vi: 'bài tập')}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                        onTap:
                            () => setState(() => _selectedPlanId = plan.planId),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPlanDetailView(ScrollController scrollController) {
    final lang = widget.langProvider;
    final plan = widget.planProvider.userPlans.firstWhere(
      (p) => p.planId == _selectedPlanId,
      orElse: () => widget.planProvider.userPlans.first,
    );

    return Column(
      children: [
        // Danh sách bài tập trong kế hoạch
        Expanded(
          child:
              plan.details.isEmpty
                  ? Center(
                    child: Text(
                      lang.getText(
                        en: 'No exercises in this plan',
                        vi: 'Chưa có bài tập trong kế hoạch',
                      ),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                  : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: plan.details.length,
                    itemBuilder: (context, index) {
                      final detail = plan.details[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Exercise image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child:
                                  detail.firstImageUrl != null
                                      ? CachedNetworkImage(
                                        imageUrl: detail.firstImageUrl!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              width: 50,
                                              height: 50,
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.fitness_center,
                                                color: AppColors.primary,
                                                size: 24,
                                              ),
                                            ),
                                      )
                                      : Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.exerciseName ?? 'Exercise',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${detail.sets ?? 3} sets × ${detail.reps ?? 10} reps',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Order number
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),

        // Bottom button
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addToPlan(_selectedPlanId!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                lang.getText(
                  en: 'Add to this plan',
                  vi: 'Thêm vào kế hoạch này',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createNewPlanAndAdd() async {
    final name = _newPlanController.text.trim();
    if (name.isEmpty) return;

    final newPlan = await widget.planProvider.createPlan(name);
    if (newPlan != null && mounted) {
      await _addToPlan(newPlan.planId);
    }
  }

  Future<void> _addToPlan(int planId) async {
    final success = await widget.planProvider.addExerciseToPlan(
      planId: planId,
      dayOfWeek: 0, // 0 means not assigned to a specific day
      exerciseId: widget.exercise.exerciseId,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? widget.langProvider.getText(
                  en: 'Added to plan!',
                  vi: 'Đã thêm vào kế hoạch!',
                )
                : widget.langProvider.getText(
                  en: 'Failed to add',
                  vi: 'Thêm thất bại',
                ),
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}
