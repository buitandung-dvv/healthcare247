import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/workout_plan_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/workout_session_model.dart';
import '../../providers/exercise_provider.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
  // Timer state
  Timer? _timer;
  Timer? _imageAnimationTimer;
  int _currentImageIndex = 0;
  int _seconds = 0;
  bool _isPaused = false;

  // Rest timer state
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _isResting = false;
  int _currentRestTotal = 30;

  // Ready countdown state
  bool _isReady = false;
  int _readySeconds = 0;
  Timer? _readyTimer;

  // Current exercise state
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _wasLastSet =
      false; // Track if we just completed the last set of an exercise

  @override
  void initState() {
    super.initState();
    _startTimer();
    final session = context.read<WorkoutPlanProvider>().activeSession;
    if (session != null && session.details.isNotEmpty) {
      _currentExerciseIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExerciseDetails(session);
        // Start with ready countdown
        _startReadyCountdown();
      });
    }
  }

  Future<void> _loadExerciseDetails(WorkoutSession session) async {
    final exerciseProvider = context.read<ExerciseProvider>();
    final languageProvider = context.read<LanguageProvider>();

    if (exerciseProvider.exercises.isEmpty) {
      await exerciseProvider.loadExercises(
        languageId: languageProvider.languageId,
        refresh: true,
      );
    }

    for (final detail in session.details) {
      final exists = exerciseProvider.exercises.any(
        (e) => e.exerciseId == detail.exerciseId,
      );
      if (!exists) {
        await exerciseProvider.loadExerciseDetail(detail.exerciseId);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imageAnimationTimer?.cancel();
    _restTimer?.cancel();
    _readyTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isResting && !_isReady) {
        setState(() => _seconds++);
      }
    });
  }

  void _startReadyCountdown() {
    setState(() {
      _isReady = true;
      _readySeconds = 10;
    });

    _readyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_readySeconds > 0) {
        setState(() => _readySeconds--);
      } else {
        timer.cancel();
        setState(() => _isReady = false);
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  void _previousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
        _currentSet = 1;
      });
    }
  }

  Future<void> _completeSet(WorkoutSessionDetail detail) async {
    final provider = context.read<WorkoutPlanProvider>();

    await provider.updateExerciseProgress(detail.exerciseId, _currentSet);

    setState(() {
      // Check if this is the last set BEFORE incrementing
      _wasLastSet = _currentSet >= detail.targetSets;

      if (!_wasLastSet) {
        // More sets remaining for current exercise
        _currentSet++;
        _startRest(detail.restDuration);
      } else {
        // Last set completed, move to next exercise
        if (_currentExerciseIndex <
            (provider.activeSession?.details.length ?? 0) - 1) {
          _currentExerciseIndex++;
          _currentSet = 1;
          _startRest(detail.restDuration);
        } else {
          _finishWorkout();
        }
      }
    });
  }

  void _startRest(int duration) {
    setState(() {
      _isResting = true;
      _restSeconds = duration;
      _currentRestTotal = duration;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        _skipRest();
      }
    });
  }

  void _addRestTime(int seconds) {
    setState(() {
      _restSeconds += seconds;
      _currentRestTotal += seconds;
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _isResting = false);
    _startReadyCountdown();
  }

  Future<void> _finishWorkout() async {
    _timer?.cancel();
    final lang = context.read<LanguageProvider>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: AppColors.success,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang.getText(en: 'Workout Complete!', vi: 'Hoàn thành!'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.getText(
                    en: 'Great job! You finished your workout.',
                    vi: 'Tuyệt vời! Bạn đã hoàn thành buổi tập.',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkCard
                            : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${(_seconds ~/ 60)}:${(_seconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () async {
                        final provider = context.read<WorkoutPlanProvider>();
                        final dashboardProvider =
                            context.read<DashboardProvider>();
                        final authProvider = context.read<AuthProvider>();

                        // Check if session still exists
                        if (provider.activeSession == null) {
                          Navigator.pop(context);
                          if (context.mounted) Navigator.pop(context);
                          return;
                        }

                        // Close dialog first
                        Navigator.pop(context);

                        try {
                          final success = await provider.completeSession();
                          if (success) {
                            await dashboardProvider.loadDashboardData(
                              authProvider.userId,
                            );
                          }
                        } catch (e) {
                          debugPrint('Error completing session: $e');
                        }

                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        lang.getText(en: 'Finish', vi: 'Hoàn thành'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutPlanProvider>();
    final session = provider.activeSession;
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (session == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(lang.getText(en: 'Loading...', vi: 'Đang tải...')),
            ],
          ),
        ),
      );
    }

    if (session.details.isEmpty) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.background,
        body: SafeArea(child: _buildFreestyleView(session, lang)),
      );
    }

    final currentDetail = session.details[_currentExerciseIndex];

    // Determine which view to show
    if (_isReady) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        body: SafeArea(child: _buildReadyView(session, currentDetail, lang)),
      );
    }

    if (_isResting) {
      return Scaffold(body: _buildRestView(session, currentDetail, lang));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(child: _buildWorkoutView(session, currentDetail, lang)),
    );
  }

  // ============ READY VIEW ============
  Widget _buildReadyView(
    WorkoutSession session,
    WorkoutSessionDetail detail,
    LanguageProvider lang,
  ) {
    return Column(
      children: [
        // Header
        _buildHeader(transparent: true),

        // Exercise Image
        Expanded(
          flex: 4,
          child: _buildExerciseImage(detail.exerciseId, large: true),
        ),

        // Ready Info - bottom section
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  lang.getText(en: 'GET READY!', vi: 'SẴN SÀNG!'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),

                // Exercise name
                Text(
                  detail.exerciseName ?? 'Exercise',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Sets x Reps info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${detail.targetSets} sets × ${detail.targetReps} reps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Countdown circle with skip button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spacer to push countdown to center
                    const SizedBox(width: 60),

                    // Countdown (larger and centered)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: _readySeconds / 10,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          '$_readySeconds',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    // Skip button (to the right)
                    GestureDetector(
                      onTap: () {
                        _readyTimer?.cancel();
                        setState(() => _isReady = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============ REST VIEW ============
  Widget _buildRestView(
    WorkoutSession session,
    WorkoutSessionDetail detail,
    LanguageProvider lang,
  ) {
    // Use _wasLastSet to determine what to show
    // If _wasLastSet is false: we have more sets, show current exercise with next set
    // If _wasLastSet is true: we completed the last set, show next exercise

    final targetSets = detail.targetSets;

    // Determine what to display
    final WorkoutSessionDetail displayDetail;
    final String labelText;

    if (_wasLastSet) {
      // Just completed last set, now showing next exercise (which is current detail)
      displayDetail = detail;
      labelText =
          '${lang.getText(en: 'NEXT', vi: 'TIẾP THEO')} ${_currentExerciseIndex + 1}/${session.details.length}';
    } else {
      // Still have more sets, show current exercise with next set number
      displayDetail = detail;
      labelText =
          '${lang.getText(en: 'NEXT SET', vi: 'SET TIẾP')} $_currentSet/$targetSets';
    }

    final minutes = (_restSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_restSeconds % 60).toString().padLeft(2, '0');
    final progress =
        _currentRestTotal > 0 ? _restSeconds / _currentRestTotal : 0.0;

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          children: [
            // Top section - Next exercise preview
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildExerciseImage(
                    displayDetail.exerciseId,
                    large: true,
                  ),
                ),
              ),
            ),

            // Next exercise info bar
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              displayDetail.exerciseName ?? 'Exercise',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppColors.textWhite
                                        : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'x ${displayDetail.targetReps}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Rest timer section
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lang.getText(en: 'REST', vi: 'NGHỈ NGƠI'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Circular timer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 6,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '$minutes:$secs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Edit rest time button
                  TextButton(
                    onPressed: () => _showEditRestDialog(lang),
                    child: Text(
                      lang.getText(en: 'Edit time', vi: 'Chỉnh thời gian'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  // +20s button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _addRestTime(20),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        '+20s',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Skip button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _skipRest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        lang.getText(en: 'Skip', vi: 'Bỏ qua'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRestDialog(LanguageProvider lang) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              lang.getText(en: 'Edit Rest Time', vi: 'Chỉnh thời gian nghỉ'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final seconds in [15, 30, 45, 60, 90, 120])
                  ListTile(
                    title: Text(
                      '$seconds ${lang.getText(en: 'seconds', vi: 'giây')}',
                    ),
                    onTap: () {
                      setState(() {
                        _restSeconds = seconds;
                        _currentRestTotal = seconds;
                      });
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
    );
  }

  // ============ WORKOUT VIEW ============
  Widget _buildWorkoutView(
    WorkoutSession session,
    WorkoutSessionDetail detail,
    LanguageProvider lang,
  ) {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        // Header with icons
        _buildHeader(transparent: true),

        // Exercise Image
        Expanded(
          flex: 3,
          child: _buildExerciseImage(detail.exerciseId, large: true),
        ),

        // Exercise info
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    detail.exerciseName ?? 'Exercise',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.help_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Set $_currentSet/${detail.targetSets} • x${detail.targetReps}',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Timer
              Text(
                '$minutes:$secs',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous
              _buildRoundButton(
                icon: Icons.skip_previous,
                onPressed: _currentExerciseIndex > 0 ? _previousExercise : null,
                size: 56,
              ),

              // Pause/Play
              _buildRoundButton(
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                onPressed: _togglePause,
                size: 72,
                isPrimary: true,
              ),

              // Next / Complete
              _buildRoundButton(
                icon: Icons.skip_next,
                onPressed: () => _completeSet(detail),
                size: 56,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required double size,
    bool isPrimary = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary ? AppColors.primary : AppColors.background,
        border:
            isPrimary ? null : Border.all(color: AppColors.border, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            size: size * 0.5,
            color:
                onPressed == null
                    ? AppColors.textHint
                    : isPrimary
                    ? Colors.white
                    : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({bool transparent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: transparent ? AppColors.textPrimary : Colors.white,
            ),
          ),
          const SizedBox(width: 48), // Placeholder for symmetry
        ],
      ),
    );
  }

  Widget _buildExerciseImage(int exerciseId, {bool large = false}) {
    final exerciseProvider = context.watch<ExerciseProvider>();
    final exercise =
        exerciseProvider.exercises
            .where((e) => e.exerciseId == exerciseId)
            .firstOrNull;

    if (exercise == null || exercise.images.isEmpty) {
      if (exercise == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          exerciseProvider.loadExerciseDetail(exerciseId);
        });
      }

      return Container(
        color: AppColors.primarySoft,
        child: Center(
          child: Icon(
            Icons.fitness_center,
            size: large ? 100 : 60,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    // Animate images
    if (exercise.images.length > 1) {
      if (_imageAnimationTimer == null || !_imageAnimationTimer!.isActive) {
        _imageAnimationTimer = Timer.periodic(
          const Duration(milliseconds: 600),
          (timer) {
            if (mounted) {
              setState(() {
                _currentImageIndex =
                    (_currentImageIndex + 1) % exercise.images.length;
              });
            }
          },
        );
      }
    }

    final imageIndex =
        _currentImageIndex < exercise.images.length ? _currentImageIndex : 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: CachedNetworkImage(
        key: ValueKey(exercise.images[imageIndex]),
        imageUrl: exercise.images[imageIndex],
        fit: BoxFit.contain,
        placeholder:
            (context, url) => Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        errorWidget:
            (context, url, error) => Center(
              child: Icon(
                Icons.fitness_center,
                size: large ? 80 : 48,
                color: AppColors.textHint,
              ),
            ),
      ),
    );
  }

  // ============ FREESTYLE VIEW ============
  Widget _buildFreestyleView(WorkoutSession session, LanguageProvider lang) {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
              Text(
                session.name ??
                    lang.getText(en: 'Quick Workout', vi: 'Tập nhanh'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Timer display
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$minutes:$secs',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                Text(
                  _isPaused
                      ? lang.getText(en: 'PAUSED', vi: 'TẠM DỪNG')
                      : lang.getText(en: 'WORKING OUT', vi: 'ĐANG TẬP'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _isPaused ? AppColors.warning : AppColors.success,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isPaused ? Icons.play_arrow : Icons.pause,
                label:
                    _isPaused
                        ? lang.getText(en: 'Resume', vi: 'Tiếp tục')
                        : lang.getText(en: 'Pause', vi: 'Tạm dừng'),
                onTap: _togglePause,
                color: AppColors.primary,
              ),
              _buildControlButton(
                icon: Icons.check,
                label: lang.getText(en: 'Finish', vi: 'Hoàn thành'),
                onTap: () => _finishFreestyleWorkout(lang),
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: onTap,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _finishFreestyleWorkout(LanguageProvider lang) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              lang.getText(en: 'Finish Workout?', vi: 'Kết thúc buổi tập?'),
            ),
            content: Text(
              lang.getText(
                en:
                    'Total time: ${(_seconds ~/ 60)}:${(_seconds % 60).toString().padLeft(2, '0')}',
                vi:
                    'Tổng thời gian: ${(_seconds ~/ 60)}:${(_seconds % 60).toString().padLeft(2, '0')}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.getText(en: 'Cancel', vi: 'Hủy')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final provider = context.read<WorkoutPlanProvider>();
                  final dashboardProvider = context.read<DashboardProvider>();
                  final authProvider = context.read<AuthProvider>();

                  // Check if session exists
                  if (provider.activeSession == null) {
                    Navigator.pop(context);
                    if (context.mounted) Navigator.pop(context);
                    return;
                  }

                  Navigator.pop(context);
                  try {
                    final success = await provider.completeSession();
                    if (success) {
                      await dashboardProvider.loadDashboardData(
                        authProvider.userId,
                      );
                    }
                  } catch (e) {
                    debugPrint('Error completing session: $e');
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(lang.getText(en: 'Finish', vi: 'Kết thúc')),
              ),
            ],
          ),
    );
  }
}
