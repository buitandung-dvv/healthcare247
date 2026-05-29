import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Welcome step - Stitch Design: centered illustration, title, subtitle, gradient button
class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Illustration container — Stitch design rounded image area
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background gradient circle
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF42A5F5).withValues(alpha: 0.3),
                        const Color(0xFF1565C0).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
                // Icon illustration
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.self_improvement_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Decorative elements
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: const Color(0xFF66BB6A).withValues(alpha: 0.6),
                          size: 32,
                        ),
                        const SizedBox(width: 60),
                        Icon(
                          Icons.eco_rounded,
                          color: const Color(0xFF66BB6A).withValues(alpha: 0.4),
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Title — Stitch style
          Text(
            'Chào mừng đến với\nHealthCare247',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Ứng dụng theo dõi sức khỏe toàn diện -\ntập luyện, dinh dưỡng, và lối sống lành mạnh',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color:
                  isDark
                      ? AppColors.darkTextSecondary
                      : const Color(0xFF64748B),
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),

          // Gradient "Tiếp theo" button — Stitch Style
          GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Tiếp theo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
