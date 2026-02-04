import 'package:flutter/material.dart';

/// App Animation Utilities - Shared animation constants and helpers
class AppAnimations {
  AppAnimations._();

  // Duration constants
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Curve constants
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutQuart;

  // Stagger delay
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Check if animations should be reduced
  static bool shouldReduceAnimations(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration based on user preferences
  static Duration getDuration(BuildContext context, Duration duration) {
    return shouldReduceAnimations(context) ? Duration.zero : duration;
  }
}

/// Fade In Animation - Widget hiện ra với fade effect
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.shouldReduceAnimations(context)) {
      return widget.child;
    }

    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

/// Slide In Animation - Widget trượt vào với fade
class SlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;

  const SlideIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.1),
  });

  /// Slide from left
  factory SlideIn.fromLeft({
    Key? key,
    required Widget child,
    Duration duration = AppAnimations.normal,
    Duration delay = Duration.zero,
  }) {
    return SlideIn(
      key: key,
      duration: duration,
      delay: delay,
      beginOffset: const Offset(-0.2, 0),
      child: child,
    );
  }

  /// Slide from right
  factory SlideIn.fromRight({
    Key? key,
    required Widget child,
    Duration duration = AppAnimations.normal,
    Duration delay = Duration.zero,
  }) {
    return SlideIn(
      key: key,
      duration: duration,
      delay: delay,
      beginOffset: const Offset(0.2, 0),
      child: child,
    );
  }

  /// Slide from bottom
  factory SlideIn.fromBottom({
    Key? key,
    required Widget child,
    Duration duration = AppAnimations.normal,
    Duration delay = Duration.zero,
  }) {
    return SlideIn(
      key: key,
      duration: duration,
      delay: delay,
      beginOffset: const Offset(0, 0.2),
      child: child,
    );
  }

  @override
  State<SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<SlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.shouldReduceAnimations(context)) {
      return widget.child;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Scale In Animation - Widget zoom in với fade
class ScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double beginScale;

  const ScaleIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutBack,
    this.beginScale = 0.8,
  });

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.shouldReduceAnimations(context)) {
      return widget.child;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

/// Stagger List Animation - Animate list items với stagger delay
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDuration = AppAnimations.normal,
    this.staggerDelay = AppAnimations.staggerDelay,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: List.generate(children.length, (index) {
        return SlideIn.fromBottom(
          duration: itemDuration,
          delay: staggerDelay * index,
          child: children[index],
        );
      }),
    );
  }
}

/// Pulse Animation - Widget nhấp nháy
class Pulse extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const Pulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppAnimations.shouldReduceAnimations(context)) {
      return widget.child;
    }

    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Shake Animation - Widget rung lắc (for errors)
class Shake extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final VoidCallback? onComplete;

  const Shake({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 10,
    this.onComplete,
  });

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticIn));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue = _animation.value * 3.14159 * 4;
        return Transform.translate(
          offset: Offset(
            widget.offset *
                (sineValue).abs() %
                1 *
                (_animation.value > 0.5 ? -1 : 1),
            0,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
