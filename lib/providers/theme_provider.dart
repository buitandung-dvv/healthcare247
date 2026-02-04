import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Provider - Quản lý Light/Dark Mode
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  
  /// Kiểm tra xem đang ở dark mode không
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  /// Kiểm tra xem đang ở light mode không
  bool get isLightMode => _themeMode == ThemeMode.light;
  
  /// Kiểm tra xem đang theo system không
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themeKey);
      
      if (savedMode != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      debugPrint('Failed to load theme mode: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Thay đổi theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  /// Toggle giữa light và dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Đặt về chế độ theo hệ thống
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Đặt chế độ sáng
  Future<void> useLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Đặt chế độ tối
  Future<void> useDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
}
