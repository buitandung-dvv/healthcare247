import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/workout_plan_provider.dart';
import 'providers/water_tracking_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/food_provider.dart';
import 'providers/goals_provider.dart';
import 'screens/main/main_navigation_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  // Tối ưu: Chạy các tác vụ khởi tạo song song
  await Future.wait([
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
    // Preload fonts/assets if needed
    _preloadAssets(),
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HealthCareApp());
}

/// Preload assets để tránh jank khi hiển thị lần đầu
Future<void> _preloadAssets() async {
  // Có thể preload images, fonts ở đây nếu cần
}

/// HealthCare App - Ứng dụng theo dõi và chăm sóc sức khỏe
class HealthCareApp extends StatelessWidget {
  const HealthCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider - Load ngay để áp dụng theme
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Language Provider - Load ngay vì cần cho UI
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        // Auth Provider - Load ngay vì cần kiểm tra đăng nhập
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Connectivity Provider - Monitor network status
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        // Lazy load các provider khác - chỉ tạo khi cần
        ChangeNotifierProvider(create: (_) => DashboardProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ExerciseProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => RecipeProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => ProgressProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => FoodProvider(), lazy: true),
        ChangeNotifierProvider(
          create: (_) => WaterTrackingProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (_) => WorkoutPlanProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(create: (_) => FavoritesProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => GoalsProvider(), lazy: true),
      ],
      child: const _AppContent(),
    );
  }
}

/// App Content - Quản lý theme và language với data reload
class _AppContent extends StatefulWidget {
  const _AppContent();

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> {
  @override
  void initState() {
    super.initState();
    // Register callbacks after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerLanguageChangeCallback();
      _registerDataUpdateCallback();
    });
  }

  void _registerLanguageChangeCallback() {
    final languageProvider = context.read<LanguageProvider>();
    languageProvider.addLanguageChangeListener(_onLanguageChanged);
  }

  void _registerDataUpdateCallback() {
    final dashboardProvider = context.read<DashboardProvider>();
    dashboardProvider.onDataUpdated = _onDashboardDataUpdated;
  }

  void _onLanguageChanged(int languageId) {
    // Reload data in all providers with new language
    final exerciseProvider = context.read<ExerciseProvider>();
    final recipeProvider = context.read<RecipeProvider>();

    exerciseProvider.reloadForLanguage(languageId);
    recipeProvider.reloadForLanguage(languageId);
  }

  void _onDashboardDataUpdated() {
    // Invalidate ProgressProvider so it reloads fresh data next time
    context.read<ProgressProvider>().invalidate();
    debugPrint('🔄 Dashboard data updated → ProgressProvider invalidated');
  }

  @override
  void dispose() {
    // Remove callbacks when disposing
    try {
      final languageProvider = context.read<LanguageProvider>();
      languageProvider.removeLanguageChangeListener(_onLanguageChanged);
      final dashboardProvider = context.read<DashboardProvider>();
      dashboardProvider.onDataUpdated = null;
    } catch (_) {
      // Provider might already be disposed
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme and language changes
    final themeProvider = context.watch<ThemeProvider>();
    // Language provider for future i18n support
    context.watch<LanguageProvider>();

    // Update system UI overlay style based on theme
    final isDark = themeProvider.isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? AppColors.darkBackground : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'HealthCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Localization support for Vietnamese
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppWrapper(),
      // Tối ưu: Sử dụng builder để cache MediaQuery
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling, // Cố định text scale
          ),
          child: child!,
        );
      },
    );
  }
}

/// App Wrapper - Kiểm tra trạng thái đăng nhập và onboarding
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Show loading while checking auth status
    if (authProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/app_icon.png', width: 80, height: 80),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Đang tải HealthCare...'),
            ],
          ),
        ),
      );
    }

    // Nếu chưa đăng nhập, hiển thị màn hình đăng nhập
    if (!authProvider.isLoggedIn) {
      return const LoginScreen();
    }

    // Nếu đã đăng nhập nhưng chưa hoàn thành onboarding, hiển thị onboarding
    if (!authProvider.onboardingCompleted) {
      return const OnboardingFlowScreen();
    }

    // Đã đăng nhập và đã hoàn thành onboarding, hiển thị màn hình chính
    return const MainNavigationScreen();
  }
}
