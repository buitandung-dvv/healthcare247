import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Animated Progress Ring - Circular progress với animation
class AnimatedProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Gradient? gradient;
  final Widget? center;
  final Duration animationDuration;
  final bool showPercentage;
  final bool animate;
  final bool showPulse;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 12,
    this.backgroundColor,
    this.progressColor,
    this.gradient,
    this.center,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.showPercentage = false,
    this.animate = true,
    this.showPulse = false,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Progress animation
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    if (widget.animate) {
      _progressController.forward();
    }

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showPulse && widget.progress >= 1.0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );
      _progressController.forward(from: 0);

      if (widget.showPulse && widget.progress >= 1.0) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        widget.backgroundColor ??
        (isDark ? AppColors.darkBorder : AppColors.border);

    final defaultGradient = LinearGradient(
      colors: [AppColors.primary, AppColors.secondary],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showPulse ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(
                    progress: 1.0,
                    strokeWidth: widget.strokeWidth,
                    color: bgColor,
                  ),
                ),
                // Progress ring
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _GradientRingPainter(
                    progress:
                        widget.animate
                            ? _progressAnimation.value
                            : widget.progress,
                    strokeWidth: widget.strokeWidth,
                    gradient: widget.gradient ?? defaultGradient,
                    progressColor: widget.progressColor,
                  ),
                ),
                // Center content
                if (widget.center != null)
                  widget.center!
                else if (widget.showPercentage)
                  _buildPercentageText(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPercentageText(bool isDark) {
    final percentage =
        (widget.animate ? _progressAnimation.value : widget.progress) * 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${percentage.toInt()}%',
          style: TextStyle(
            fontSize: widget.size * 0.2,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Ring Painter - Vẽ ring đơn sắc
class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Gradient Ring Painter - Vẽ ring với gradient
class _GradientRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient? gradient;
  final Color? progressColor;

  _GradientRingPainter({
    required this.progress,
    required this.strokeWidth,
    this.gradient,
    this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else if (progressColor != null) {
      paint.color = progressColor!;
    } else {
      paint.color = AppColors.primary;
    }

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.gradient != gradient ||
      oldDelegate.progressColor != progressColor;
}

/// Mini Progress Ring - Nhỏ hơn cho inline display
class MiniProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;

  const MiniProgressRing({
    super.key,
    required this.progress,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedProgressRing(
      progress: progress,
      size: size,
      strokeWidth: strokeWidth,
      progressColor: color ?? AppColors.primary,
      animate: false,
    );
  }
}

/// Macro Progress Ring - Cho hiển thị protein/carbs/fat
class MacroProgressRing extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final double size;

  const MacroProgressRing({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedProgressRing(
          progress: progress,
          size: size,
          strokeWidth: size * 0.1,
          progressColor: color,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${current.toInt()}',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                ),
              ),
              Text(
                'g',
                style: TextStyle(
                  fontSize: size * 0.12,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSm,
            fontWeight: FontWeight.w500,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
