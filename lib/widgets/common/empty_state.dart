import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../buttons/animated_button.dart';

/// Empty State Widget - Hiển thị khi không có dữ liệu
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.iconSize = 80,
  });

  /// Empty state cho workout
  factory EmptyState.workout({
    Key? key,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.fitness_center_outlined,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      iconColor: AppColors.primary,
    );
  }

  /// Empty state cho meals
  factory EmptyState.meals({
    Key? key,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.restaurant_outlined,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      iconColor: AppColors.secondary,
    );
  }

  /// Empty state cho search
  factory EmptyState.search({
    Key? key,
    required String title,
    String? subtitle,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.search_off_outlined,
      title: title,
      subtitle: subtitle,
      iconColor: AppColors.textHint,
    );
  }

  /// Empty state cho network error
  factory EmptyState.networkError({
    Key? key,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.wifi_off_outlined,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onRetry,
      iconColor: AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon container
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: iconSize + 40,
                height: iconSize + 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (iconColor ?? AppColors.primary).withAlpha(
                    26,
                  ), // 0.1 opacity
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.fontXl,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppSizes.fontMd,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppSizes.xl),
              AnimatedButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Widget - Hiển thị khi có lỗi
class ErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryText;

  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryText = 'Thử lại',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState.networkError(
      title: title,
      subtitle: message,
      buttonText: onRetry != null ? retryText : null,
      onRetry: onRetry,
    );
  }
}

/// Success State Widget - Hiển thị khi thành công
class SuccessState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const SuccessState({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.check_circle_outline,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      iconColor: AppColors.success,
    );
  }
}
