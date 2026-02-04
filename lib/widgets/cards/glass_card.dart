import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Glass Card - Modern glassmorphism card với blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurAmount;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool showBorder;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.blurAmount = 10,
    this.backgroundColor,
    this.gradient,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBackgroundColor =
        isDark
            ? AppColors.darkCard.withAlpha(179) // 0.7 opacity
            : Colors.white.withAlpha(204); // 0.8 opacity

    final borderColor =
        isDark
            ? Colors.white.withAlpha(26)
            : Colors.white.withAlpha(128); // 0.1 / 0.5

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: backgroundColor ?? defaultBackgroundColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                showBorder ? Border.all(color: borderColor, width: 1) : null,
            boxShadow: [
              BoxShadow(
                color: isDark ? AppColors.darkShadow : AppColors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

/// Gradient Card - Card với gradient background
class GradientCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool animate;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.gradient,
    this.onTap,
    this.animate = false,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final defaultGradient = LinearGradient(
      colors: [
        AppColors.primary.withAlpha(230), // 0.9 opacity
        AppColors.secondary.withAlpha(230), // 0.9 opacity
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onTap != null ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          gradient: widget.gradient ?? defaultGradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(
                _isPressed ? 51 : 77,
              ), // 0.2 / 0.3
              blurRadius: _isPressed ? 12 : 20,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
        ),
        child: widget.child,
      ),
    );

    if (widget.margin != null) {
      card = Padding(padding: widget.margin!, child: card);
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Stat Card - Card cho hiển thị statistics
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withAlpha(
                    26,
                  ), // 0.1 opacity
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.fontHeading,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: AppSizes.fontSm,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
