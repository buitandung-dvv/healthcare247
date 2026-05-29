import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../data/models/meal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/common_widgets.dart';
import 'my_meals_screen.dart';

/// Add Meal Screen - Thêm bữa ăn mới với tìm kiếm food
class AddMealScreen extends StatefulWidget {
  final String mealType;
  final DateTime date;
  final Food? initialFood;

  const AddMealScreen({
    super.key,
    required this.mealType,
    required this.date,
    this.initialFood,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '100',
  );

  List<Food> _searchResults = [];
  List<Food> _allFoods = [];
  Food? _selectedFood;
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFood != null) {
      // Pre-select food → skip search list, show detail directly
      _selectedFood = widget.initialFood;
      _searchController.text = widget.initialFood!.name;
      _isLoading = false;
      // No need to load full food list
    } else {
      // Load foods after first frame to access context
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialFoods();
      });
    }
  }

  int? _lastLanguageId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload foods when language changes
    final lang = context.read<LanguageProvider>();
    if (_lastLanguageId != null && _lastLanguageId != lang.languageId) {
      _loadInitialFoods();
    }
    _lastLanguageId = lang.languageId;
  }

  Future<void> _loadInitialFoods() async {
    final lang = context.read<LanguageProvider>();
    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        ApiConfig.foods,
        queryParameters: {
          'limit': '500',
          'language_id': lang.languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        final foods =
            (response.data!['data'] as List)
                .map((e) => Food.fromJson(e as Map<String, dynamic>))
                .toList();
        setState(() {
          _allFoods = foods;
          _searchResults = foods;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Load foods error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _mealTypeName(LanguageProvider lang) {
    switch (widget.mealType) {
      case 'breakfast':
        return lang.getText(en: 'Breakfast', vi: 'Bữa sáng');
      case 'lunch':
        return lang.getText(en: 'Lunch', vi: 'Bữa trưa');
      case 'dinner':
        return lang.getText(en: 'Dinner', vi: 'Bữa tối');
      case 'snack':
        return lang.getText(en: 'Snack', vi: 'Ăn vặt');
      default:
        return widget.mealType;
    }
  }

  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = _allFoods);
      return;
    }
    if (query.length < 2) {
      // Filter from loaded list for quick response
      setState(
        () =>
            _searchResults =
                _allFoods
                    .where(
                      (f) => f.name.toLowerCase().contains(query.toLowerCase()),
                    )
                    .toList(),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final lang = context.read<LanguageProvider>();
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '${ApiConfig.foods}/search',
        queryParameters: {
          'q': query,
          'limit': '20',
          'language_id': lang.languageId.toString(),
        },
      );

      if (response.data != null && response.data!['data'] != null) {
        final foods =
            (response.data!['data'] as List)
                .map((e) => Food.fromJson(e as Map<String, dynamic>))
                .toList();
        setState(() => _searchResults = foods);
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectFood(Food food) {
    setState(() {
      _selectedFood = food;
      _searchController.text = food.name;
      _searchResults = [];
    });
  }

  double get _quantity => double.tryParse(_quantityController.text) ?? 100;

  double get _calculatedCalories =>
      ((_selectedFood?.calories ?? 0) * _quantity / 100);

  double get _calculatedProtein =>
      ((_selectedFood?.protein ?? 0) * _quantity / 100);

  double get _calculatedCarbs =>
      ((_selectedFood?.carbs ?? 0) * _quantity / 100);

  double get _calculatedFat => ((_selectedFood?.fat ?? 0) * _quantity / 100);

  double get _calculatedFiber =>
      ((_selectedFood?.fiber ?? 0) * _quantity / 100);

  double get _calculatedCholesterol =>
      ((_selectedFood?.cholesterol ?? 0) * _quantity / 100);

  double get _calculatedCalcium =>
      ((_selectedFood?.calcium ?? 0) * _quantity / 100);

  double get _calculatedIron => ((_selectedFood?.iron ?? 0) * _quantity / 100);

  double get _calculatedSodium =>
      ((_selectedFood?.sodium ?? 0) * _quantity / 100);

  double get _calculatedPotassium =>
      ((_selectedFood?.potassium ?? 0) * _quantity / 100);

  double get _calculatedPhosphorus =>
      ((_selectedFood?.phosphorus ?? 0) * _quantity / 100);

  double get _calculatedVitaminA =>
      ((_selectedFood?.vitaminA ?? 0) * _quantity / 100);

  double get _calculatedVitaminB1 =>
      ((_selectedFood?.vitaminB1 ?? 0) * _quantity / 100);

  double get _calculatedVitaminC =>
      ((_selectedFood?.vitaminC ?? 0) * _quantity / 100);

  Future<void> _saveMeal() async {
    if (_selectedFood == null) return;

    setState(() => _isSaving = true);

    final lang = context.read<LanguageProvider>();
    final auth = context.read<AuthProvider>();
    final dashboard = context.read<DashboardProvider>();

    final entry = MealEntry(
      name: _selectedFood!.name,
      mealType: widget.mealType,
      quantity: _quantity,
      calories: _calculatedCalories,
      protein: _calculatedProtein,
      carbs: _calculatedCarbs,
      fat: _calculatedFat,
      foodId: _selectedFood!.foodId,
    );

    try {
      // Lưu lên API trực tiếp
      await dashboard.logMeal(
        userId: auth.userId,
        mealType: widget.mealType,
        mealName: entry.name,
        calories: entry.calories,
        protein: entry.protein,
        carbs: entry.carbs,
        fat: entry.fat,
        quantity: entry.quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.getText(
                en: 'Added ${entry.name} (${entry.calories.toInt()} kcal)',
                vi: 'Đã thêm ${entry.name} (${entry.calories.toInt()} kcal)',
              ),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, entry);
      }
    } catch (e) {
      debugPrint('❌ Save meal error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.getText(
                en: 'Failed to save. Please try again.',
                vi: 'Lưu thất bại. Vui lòng thử lại.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: CustomAppBar(
        title: lang.getText(
          en: 'Add to ${_mealTypeName(lang)}',
          vi: 'Thêm vào ${_mealTypeName(lang)}',
        ),
      ),
      body: Column(
        children: [
          // Search Bar — chỉ hiện khi không có initialFood
          if (widget.initialFood == null)
            Padding(
              padding: AppSizes.paddingMd,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: lang.getText(
                    en: 'Search foods...',
                    vi: 'Tìm thực phẩm...',
                  ),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.search,
                      color: const Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  suffixIcon:
                      _isSearching
                          ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF42A5F5),
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) => _searchFoods(value),
              ),
            ),

          // Search Results or Selected Food Details
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedFood != null
                    ? _buildFoodDetails(lang)
                    : _searchResults.isNotEmpty
                        ? _buildSearchResults()
                        : _buildEmptyState(lang),
          ),

          // Add Button
          if (_selectedFood != null)
            Padding(
              padding: AppSizes.paddingMd,
              child: GestureDetector(
                onTap: _isSaving ? null : _saveMeal,
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
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.getText(
                          en: 'Add ${_calculatedCalories.toInt()} kcal',
                          vi: 'Thêm ${_calculatedCalories.toInt()} kcal',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: AppSizes.paddingHorizontalMd,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return ListTile(
          title: Text(food.name),
          subtitle: Text(
            '${food.calories?.toInt() ?? 0} kcal / 100g • ${food.categoryName ?? ''}',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          trailing: Icon(Icons.add_circle_outline, color: AppColors.primary),
          onTap: () => _selectFood(food),
        );
      },
    );
  }

  Widget _buildFoodDetails(LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: AppSizes.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Food Card
          Container(
            padding: AppSizes.paddingMd,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.card,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.primary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedFood!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        if (widget.initialFood != null) {
                          // Came from food detail sheet → go back
                          Navigator.pop(context);
                        } else {
                          setState(() {
                            _selectedFood = null;
                            _searchController.clear();
                            _searchResults = _allFoods;
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (_selectedFood!.categoryName != null)
                  Text(
                    _selectedFood!.categoryName!,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // Quantity Input
          Text(
            lang.getText(en: 'Quantity (grams)', vi: 'Khối lượng (gram)'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  final current = _quantity;
                  if (current > 10) {
                    _quantityController.text =
                        (current - 10).toInt().toString();
                    setState(() {});
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffix: const Text('g'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  _quantityController.text =
                      (_quantity + 10).toInt().toString();
                  setState(() {});
                },
              ),
            ],
          ),

          // Quick Quantity Buttons
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            children:
                [50, 100, 150, 200, 250].map((q) {
                  return ChoiceChip(
                    label: Text('${q}g'),
                    selected: _quantity == q,
                    onSelected: (selected) {
                      if (selected) {
                        _quantityController.text = q.toString();
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
          ),

          const SizedBox(height: AppSizes.xl),

          // Nutrition Preview
          Text(
            lang.getText(en: 'Nutrition Info', vi: 'Thông tin dinh dưỡng'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.md),
          _buildNutritionGrid(lang),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Macros Section - Large cards
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lang.getText(en: 'Macros', vi: 'Dinh dưỡng chính'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Expanded(
                    child: _buildMacroCard(
                      lang.getText(en: 'Calories', vi: 'Calo'),
                      _calculatedCalories.toInt().toString(),
                      'kcal',
                      AppColors.caloriesColor,
                      Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _buildMacroCard(
                      lang.getText(en: 'Protein', vi: 'Chất đạm'),
                      _calculatedProtein.toStringAsFixed(1),
                      'g',
                      AppColors.proteinColor,
                      Icons.egg_alt,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _buildMacroCard(
                      lang.getText(en: 'Carbs', vi: 'Tinh bột'),
                      _calculatedCarbs.toStringAsFixed(1),
                      'g',
                      AppColors.carbsColor,
                      Icons.bakery_dining,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _buildMacroCard(
                      lang.getText(en: 'Fat', vi: 'Chất béo'),
                      _calculatedFat.toStringAsFixed(1),
                      'g',
                      AppColors.fatColor,
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.md),

        // Minerals Section
        _buildNutritionSection(
          title: lang.getText(en: 'Minerals', vi: 'Khoáng chất'),
          icon: Icons.scatter_plot,
          color: Colors.teal,
          items: [
            _NutritionItem(
              lang.getText(en: 'Fiber', vi: 'Chất xơ'),
              _calculatedFiber.toStringAsFixed(1),
              'g',
              Colors.green,
            ),
            _NutritionItem(
              lang.getText(en: 'Cholest.', vi: 'Cholest.'),
              _calculatedCholesterol.toStringAsFixed(0),
              'mg',
              Colors.purple,
            ),
            _NutritionItem(
              lang.getText(en: 'Calcium', vi: 'Canxi'),
              _calculatedCalcium.toStringAsFixed(0),
              'mg',
              Colors.teal,
            ),
            _NutritionItem(
              lang.getText(en: 'Iron', vi: 'Sắt'),
              _calculatedIron.toStringAsFixed(1),
              'mg',
              Colors.brown,
            ),
          ],
        ),

        const SizedBox(height: AppSizes.sm),

        // Electrolytes Section
        _buildNutritionSection(
          title: lang.getText(en: 'Electrolytes', vi: 'Điện giải'),
          icon: Icons.bolt,
          color: Colors.orange,
          items: [
            _NutritionItem(
              lang.getText(en: 'Sodium', vi: 'Natri'),
              _calculatedSodium.toStringAsFixed(0),
              'mg',
              Colors.orange,
            ),
            _NutritionItem(
              lang.getText(en: 'Potassium', vi: 'Kali'),
              _calculatedPotassium.toStringAsFixed(0),
              'mg',
              Colors.deepOrange,
            ),
            _NutritionItem(
              lang.getText(en: 'Phosph.', vi: 'Phốt pho'),
              _calculatedPhosphorus.toStringAsFixed(0),
              'mg',
              Colors.indigo,
            ),
          ],
        ),

        const SizedBox(height: AppSizes.sm),

        // Vitamins Section
        _buildNutritionSection(
          title: lang.getText(en: 'Vitamins', vi: 'Vitamin'),
          icon: Icons.brightness_7,
          color: Colors.amber,
          items: [
            _NutritionItem(
              lang.getText(en: 'Vit. A', vi: 'Vit. A'),
              _calculatedVitaminA.toStringAsFixed(0),
              'mcg',
              Colors.amber,
            ),
            _NutritionItem(
              lang.getText(en: 'Vit. B1', vi: 'Vit. B1'),
              _calculatedVitaminB1.toStringAsFixed(2),
              'mg',
              Colors.lime.shade700,
            ),
            _NutritionItem(
              lang.getText(en: 'Vit. C', vi: 'Vit. C'),
              _calculatedVitaminC.toStringAsFixed(1),
              'mg',
              Colors.redAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_NutritionItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.border).withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children:
                items.map((item) {
                  return Expanded(
                    child: _buildMiniCard(
                      item.label,
                      item.value,
                      item.unit,
                      item.color,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(
    String label,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            unit,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String label, String value, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            lang.getText(
              en: 'Search for foods to add',
              vi: 'Tìm thực phẩm để thêm',
            ),
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Helper class for nutrition section items
class _NutritionItem {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutritionItem(this.label, this.value, this.unit, this.color);
}
