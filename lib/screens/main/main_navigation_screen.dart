import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/food_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/goals_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../exercises/exercise_list_screen.dart';
import '../meals/my_meals_screen.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';

/// Main Navigation Shell với Bottom Navigation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Cache for visited screens - only build when first visited
  final Map<int, Widget> _cachedScreens = {};

  /// Switch to a specific tab programmatically
  void switchToTab(int index) {
    if (index >= 0 && index < 5) {
      _onTabChanged(index);
    }
  }

  /// Handle tab change - trigger lazy loading for target tab
  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _loadDataForTab(index);
  }

  /// Load data for the selected tab (lazy loading)
  void _loadDataForTab(int index) {
    final userId = context.read<AuthProvider>().currentUser?.userId;
    final langId = context.read<LanguageProvider>().languageId;

    switch (index) {
      case 0: // Dashboard - handled by DashboardScreen itself
        break;
      case 1: // Bài tập
        context.read<ExerciseProvider>().loadIfNeeded(languageId: langId);
        break;
      case 2: // Thực phẩm
        context.read<RecipeProvider>().loadIfNeeded(languageId: langId);
        context.read<FoodProvider>().loadIfNeeded(languageId: langId);
        break;
      case 3: // Tiến độ
        if (userId != null) {
          context.read<ProgressProvider>().loadIfNeeded(userId);
        }
        break;
      case 4: // Hồ sơ
        if (userId != null) {
          context.read<GoalsProvider>().loadIfNeeded(userId);
        }
        break;
    }
  }

  // Build screen lazily - only when first visited
  Widget _buildScreen(int index) {
    if (!_cachedScreens.containsKey(index)) {
      _cachedScreens[index] = _createScreen(index);
    }
    return _cachedScreens[index]!;
  }

  Widget _createScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ExerciseListScreen();
      case 2:
        return const MyMealsScreen();
      case 3:
        return const ProgressScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Use lazy builder instead of IndexedStack
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? AppColors.darkShadow.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: lang.getText(en: 'Home', vi: 'Trang chủ'),
                  isActive: _currentIndex == 0,
                  onTap: () => _onTabChanged(0),
                ),
                _NavItem(
                  icon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center,
                  label: lang.getText(en: 'Exercises', vi: 'Bài tập'),
                  isActive: _currentIndex == 1,
                  onTap: () => _onTabChanged(1),
                ),
                _NavItem(
                  icon: Icons.lunch_dining_outlined,
                  activeIcon: Icons.lunch_dining,
                  label: lang.getText(en: 'Food', vi: 'Thực phẩm'),
                  isActive: _currentIndex == 2,
                  onTap: () => _onTabChanged(2),
                ),
                _NavItem(
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up,
                  label: lang.getText(en: 'Progress', vi: 'Tiến độ'),
                  isActive: _currentIndex == 3,
                  onTap: () => _onTabChanged(3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: lang.getText(en: 'Profile', vi: 'Hồ sơ'),
                  isActive: _currentIndex == 4,
                  onTap: () => _onTabChanged(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with gradient when active
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 16 : 8,
                  vertical: isActive ? 8 : 4,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isActive
                          ? (isDark
                              ? AppColors.darkPrimaryGradient
                              : AppColors.primaryGradient)
                          : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color:
                      isActive
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isActive
                          ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
