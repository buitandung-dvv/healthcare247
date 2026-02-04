import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/repositories/tracking_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../recipes/recipe_list_screen.dart';
import 'add_meal_screen.dart';

/// My Meals Screen - Danh sách bữa ăn trong ngày
class MyMealsScreen extends StatefulWidget {
  const MyMealsScreen({super.key});

  @override
  State<MyMealsScreen> createState() => _MyMealsScreenState();
}

class _MyMealsScreenState extends State<MyMealsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  final List<MealEntry> _meals = [];
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final repository = TrackingRepository();

      // Debug: Log the date being queried
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      debugPrint('📅 MyMealsScreen loading meals for date: $dateStr');

      // Fetch logged meals from tracking for selected date
      final mealTrackings = await repository.getMealHistory(
        userId: auth.userId,
        startDate: _selectedDate,
        endDate: _selectedDate,
      );

      debugPrint('📥 Received ${mealTrackings.length} meal trackings');

      // Convert MealTracking to MealEntry
      final entries =
          mealTrackings
              .map(
                (tracking) => MealEntry(
                  name: tracking.mealName ?? tracking.mealType ?? 'Unknown',
                  mealType: tracking.mealType ?? 'snack',
                  quantity: tracking.quantity ?? 100,
                  calories: tracking.calories ?? 0,
                  protein: tracking.protein ?? 0,
                  carbs: tracking.carbs ?? 0,
                  fat: tracking.fat ?? 0,
                ),
              )
              .toList();

      debugPrint('✅ Converted to ${entries.length} MealEntry items');

      setState(() {
        _meals.clear();
        _meals.addAll(entries);
        _isLoading = false;
        _calculateTotals();
      });
    } catch (e) {
      debugPrint('❌ Load meals error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    _totalCalories = 0;
    _totalProtein = 0;
    _totalCarbs = 0;
    _totalFat = 0;

    for (var meal in _meals) {
      _totalCalories += meal.calories;
      _totalProtein += meal.protein;
      _totalCarbs += meal.carbs;
      _totalFat += meal.fat;
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadMeals();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Hôm nay';
    if (selected == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _addMeal(String mealType) async {
    // Read providers before async call to avoid context issues
    final auth = context.read<AuthProvider>();
    final dashboard = context.read<DashboardProvider>();

    final result = await Navigator.push<MealEntry>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddMealScreen(mealType: mealType, date: _selectedDate),
      ),
    );

    if (result != null) {
      // Save to backend via DashboardProvider
      await dashboard.logMeal(
        userId: auth.userId,
        mealType: mealType,
        mealName: result.name,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        quantity: result.quantity,
      );

      // Update local state
      setState(() {
        _meals.add(result);
        _calculateTotals();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã thêm ${result.name} (${result.calories.toInt()} kcal)',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: lang.getText(en: 'Food', vi: 'Thực phẩm')),
      body:
          _isLoading
              ? const LoadingWidget()
              : SingleChildScrollView(
                padding: AppSizes.paddingMd,
                child: Column(
                  children: [
                    // Date Navigator
                    _buildDateNavigator(lang),

                    // Daily Summary
                    _buildDailySummary(lang),

                    const SizedBox(height: AppSizes.md),

                    // Meal Cards
                    ..._buildMealCards(lang),

                    // Recipe Suggestions
                    _buildRecipeSuggestionsCard(lang),
                  ],
                ),
              ),
    );
  }

  void _navigateToRecipes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecipeListScreen()),
    );
  }

  Widget _buildDateNavigator(LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeDate(-1),
        ),
        Text(
          _formatDate(_selectedDate),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              _selectedDate.isBefore(DateTime.now())
                  ? () => _changeDate(1)
                  : null,
        ),
      ],
    );
  }

  Widget _buildDailySummary(LanguageProvider lang) {
    return Container(
      padding: AppSizes.paddingMd,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Text(
            lang.getText(en: 'Today\'s Nutrition', vi: 'Dinh dưỡng hôm nay'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientBadge(
                '${_totalCalories.toInt()}',
                'kcal',
                lang.getText(en: 'Calories', vi: 'Calories'),
              ),
              _buildNutrientBadge(
                '${_totalProtein.toInt()}g',
                '',
                lang.getText(en: 'Protein', vi: 'Protein'),
              ),
              _buildNutrientBadge(
                '${_totalCarbs.toInt()}g',
                '',
                lang.getText(en: 'Carbs', vi: 'Carbs'),
              ),
              _buildNutrientBadge(
                '${_totalFat.toInt()}g',
                '',
                lang.getText(en: 'Fat', vi: 'Fat'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBadge(String value, String unit, String label) {
    return Column(
      children: [
        Text(
          '$value$unit',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMealCards(LanguageProvider lang) {
    final mealTypes = [
      {
        'type': 'breakfast',
        'icon': Icons.free_breakfast,
        'color': Colors.orange,
        'name': lang.getText(en: 'Breakfast', vi: 'Bữa sáng'),
      },
      {
        'type': 'lunch',
        'icon': Icons.lunch_dining,
        'color': Colors.green,
        'name': lang.getText(en: 'Lunch', vi: 'Bữa trưa'),
      },
      {
        'type': 'dinner',
        'icon': Icons.dinner_dining,
        'color': Colors.blue,
        'name': lang.getText(en: 'Dinner', vi: 'Bữa tối'),
      },
      {
        'type': 'snack',
        'icon': Icons.icecream,
        'color': Colors.pink,
        'name': lang.getText(en: 'Snack', vi: 'Ăn vặt'),
      },
    ];

    return mealTypes.map((mealType) {
      final mealsOfType =
          _meals.where((m) => m.mealType == mealType['type']).toList();

      return _buildMealTypeCard(
        mealType['type'] as String,
        mealType['name'] as String,
        mealType['icon'] as IconData,
        mealType['color'] as Color,
        mealsOfType,
        lang,
      );
    }).toList();
  }

  Widget _buildRecipeSuggestionsCard(LanguageProvider lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.lg, top: AppSizes.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToRecipes(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: AppSizes.paddingMd,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.getText(
                          en: 'Recipe Suggestions',
                          vi: 'Gợi ý công thức',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.getText(
                          en: 'Explore delicious recipes to cook',
                          vi: 'Khám phá các công thức nấu ăn ngon',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeCard(
    String type,
    String name,
    IconData icon,
    Color color,
    List<MealEntry> meals,
    LanguageProvider lang,
  ) {
    final totalCalories = meals.fold(0.0, (sum, m) => sum + m.calories);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(name, style: Theme.of(context).textTheme.titleMedium),
            subtitle:
                meals.isEmpty
                    ? Text(
                      lang.getText(en: 'No meals added', vi: 'Chưa có bữa ăn'),
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                    : Text(
                      '${meals.length} ${lang.getText(en: 'items', vi: 'món')} • ${totalCalories.toInt()} kcal',
                    ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () => _addMeal(type),
            ),
          ),

          // Meal Items
          if (meals.isNotEmpty)
            ...meals.map((meal) => _buildMealItem(meal, lang)),
        ],
      ),
    );
  }

  Widget _buildMealItem(MealEntry meal, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${meal.quantity}g',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal.calories.toInt()} kcal',
            style: TextStyle(
              color: AppColors.caloriesColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple meal entry model for UI state
class MealEntry {
  final String name;
  final String mealType;
  final double quantity; // grams
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int? foodId;

  MealEntry({
    required this.name,
    required this.mealType,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.foodId,
  });
}
