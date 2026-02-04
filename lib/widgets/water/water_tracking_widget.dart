import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/water_tracking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../cards/glass_card.dart';

/// Water Tracking Widget - Hiển thị và quản lý lượng nước uống
class WaterTrackingWidget extends StatefulWidget {
  const WaterTrackingWidget({super.key});

  @override
  State<WaterTrackingWidget> createState() => _WaterTrackingWidgetState();
}

class _WaterTrackingWidgetState extends State<WaterTrackingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAnimation(double newProgress) {
    if (newProgress != _previousProgress) {
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
      _previousProgress = newProgress;
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final waterColor = const Color(0xFF4FC3F7); // Light blue for water
    final lang = context.watch<LanguageProvider>();

    return Consumer2<WaterTrackingProvider, AuthProvider>(
      builder: (context, waterProvider, authProvider, _) {
        final intake = waterProvider.dailyIntake;
        final userId = authProvider.currentUser?.userId;

        // Update animation when progress changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateAnimation(intake.progress.clamp(0, 1));
        });

        return GlassCard(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: waterColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      color: waterColor,
                      size: AppSizes.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.getText(en: 'Water Intake', vi: 'Lượng nước uống'),
                        style: TextStyle(
                          fontSize: AppSizes.fontMd,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        lang.getText(
                          en:
                              '${intake.glassesConsumed}/${intake.glassesGoal} glasses',
                          vi:
                              '${intake.glassesConsumed}/${intake.glassesGoal} ly',
                        ),
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
                  const Spacer(),
                  // Amount display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(intake.totalMl / 1000).toStringAsFixed(1)}L',
                        style: TextStyle(
                          fontSize: AppSizes.fontXl,
                          fontWeight: FontWeight.bold,
                          color: waterColor,
                        ),
                      ),
                      Text(
                        lang.getText(
                          en: 'of ${(intake.goalMl / 1000).toStringAsFixed(1)}L',
                          vi: 'trên ${(intake.goalMl / 1000).toStringAsFixed(1)}L',
                        ),
                        style: TextStyle(
                          fontSize: AppSizes.fontSm,
                          color:
                              isDark
                                  ? AppColors.darkTextHint
                                  : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.md),

              // Progress bar with animation
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 12,
                          backgroundColor:
                              isDark
                                  ? Colors.white.withAlpha(26)
                                  : Colors.grey.withAlpha(51),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            intake.progress >= 1
                                ? AppColors.success
                                : waterColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(intake.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.w500,
                              color:
                                  intake.progress >= 1
                                      ? AppColors.success
                                      : waterColor,
                            ),
                          ),
                          if (intake.remainingMl > 0)
                            Text(
                              lang.getText(
                                en: '${intake.remainingMl}ml remaining',
                                vi: 'Còn ${intake.remainingMl}ml',
                              ),
                              style: TextStyle(
                                fontSize: AppSizes.fontSm,
                                color:
                                    isDark
                                        ? AppColors.darkTextHint
                                        : AppColors.textHint,
                              ),
                            )
                          else
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lang.getText(
                                    en: 'Goal reached!',
                                    vi: 'Đạt mục tiêu!',
                                  ),
                                  style: TextStyle(
                                    fontSize: AppSizes.fontSm,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppSizes.md),

              // Quick add buttons
              Row(
                children: [
                  Expanded(
                    child: _QuickAddButton(
                      label: '+250ml',
                      icon: Icons.local_drink,
                      onTap:
                          userId != null && !waterProvider.isLoading
                              ? () => waterProvider.addGlass(userId)
                              : null,
                      color: waterColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _QuickAddButton(
                      label: '+500ml',
                      icon: Icons.water_drop,
                      onTap:
                          userId != null && !waterProvider.isLoading
                              ? () => waterProvider.addHalfLiter(userId)
                              : null,
                      color: waterColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _QuickAddButton(
                      label: lang.getText(en: 'Custom', vi: 'Tùy chọn'),
                      icon: Icons.edit,
                      onTap:
                          userId != null && !waterProvider.isLoading
                              ? () =>
                                  _showCustomAmountDialog(context, userId, lang)
                              : null,
                      color: waterColor,
                      isOutlined: true,
                    ),
                  ),
                ],
              ),

              // Loading indicator
              if (waterProvider.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.sm),
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: waterColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomAmountDialog(
    BuildContext context,
    int userId,
    LanguageProvider lang,
  ) {
    final controller = TextEditingController();
    final waterProvider = context.read<WaterTrackingProvider>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(lang.getText(en: 'Add Water', vi: 'Thêm nước')),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: lang.getText(en: 'Amount (ml)', vi: 'Lượng (ml)'),
                hintText: lang.getText(en: 'e.g. 300', vi: 'VD: 300'),
                suffixText: 'ml',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.getText(en: 'Cancel', vi: 'Hủy')),
              ),
              FilledButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    waterProvider.logWater(userId: userId, amountMl: amount);
                    Navigator.pop(context);
                  }
                },
                child: Text(lang.getText(en: 'Add', vi: 'Thêm')),
              ),
            ],
          ),
    );
  }
}

/// Quick Add Button for water tracking
class _QuickAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool isOutlined;

  const _QuickAddButton({
    required this.label,
    required this.icon,
    this.onTap,
    required this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isOutlined ? Colors.transparent : color.withAlpha(26),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.sm,
            horizontal: AppSizes.xs,
          ),
          decoration:
              isOutlined
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(color: color.withAlpha(128), width: 1),
                  )
                  : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: FontWeight.w500,
                  color:
                      onTap != null
                          ? color
                          : (isDark
                              ? AppColors.darkTextHint
                              : AppColors.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
