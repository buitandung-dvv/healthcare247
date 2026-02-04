import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Gradient promotional banner card
/// Dùng cho challenges, premium features, promotions
class GradientBannerCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Widget? trailing;
  final double height;
  final EdgeInsets margin;

  const GradientBannerCard({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.onTap,
    this.gradient,
    this.trailing,
    this.height = 140,
    this.margin = const EdgeInsets.symmetric(horizontal: AppSizes.md),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient =
        isDark ? AppColors.darkPrimaryGradient : AppColors.heroGradient;

    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? defaultGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: (gradient?.colors.first ?? AppColors.primary).withValues(
              alpha: 0.3,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXl,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: AppSizes.fontSm,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (buttonText != null) ...[
                        const SizedBox(height: AppSizes.md),
                        _BannerButton(
                          text: buttonText!,
                          onPressed: onButtonPressed,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSizes.md),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const _BannerButton({required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Challenge banner with image background
class ChallengeBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? buttonText;
  final VoidCallback? onTap;
  final Color? overlayColor;

  const ChallengeBannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.buttonText,
    this.onTap,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        gradient: LinearGradient(
          colors: [
            overlayColor ?? AppColors.primary,
            (overlayColor ?? AppColors.accent).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (overlayColor ?? AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  subtitle.toUpperCase(),
                  style: TextStyle(
                    fontSize: AppSizes.fontXs,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontXxl,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                if (buttonText != null) ...[
                  const SizedBox(height: AppSizes.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      buttonText!,
                      style: TextStyle(
                        fontSize: AppSizes.fontSm,
                        fontWeight: FontWeight.w600,
                        color: overlayColor ?? AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
