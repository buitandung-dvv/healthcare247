import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Horizontal scrolling category/filter chips
/// Dùng cho exercises screen, recipes screen, etc.
class HorizontalCategoryScroll extends StatelessWidget {
  final List<CategoryItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsets padding;
  final double spacing;
  final bool showIcons;

  const HorizontalCategoryScroll({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSizes.md),
    this.spacing = AppSizes.sm,
    this.showIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return _CategoryChip(
            item: item,
            isSelected: isSelected,
            isDark: isDark,
            showIcon: showIcons && item.icon != null,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryItem item;
  final bool isSelected;
  final bool isDark;
  final bool showIcon;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.showIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark ? AppColors.darkPrimary : AppColors.primary;
    final unselectedBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final selectedText = isDark ? AppColors.darkBackground : Colors.white;
    final unselectedText =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: showIcon ? AppSizes.md : AppSizes.lg,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected ? selectedBg : borderColor,
              width: 1.5,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: selectedBg.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected ? selectedText : unselectedText,
                ),
                const SizedBox(width: AppSizes.xs),
              ],
              Text(
                item.label,
                style: TextStyle(
                  fontSize: AppSizes.fontSm,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? selectedText : unselectedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model for category item
class CategoryItem {
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final dynamic value;

  const CategoryItem({
    required this.label,
    this.icon,
    this.imageUrl,
    this.value,
  });
}
