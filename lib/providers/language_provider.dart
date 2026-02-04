import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Callback type for language change events
typedef LanguageChangeCallback = void Function(int languageId);

/// Language Provider - Quản lý đa ngôn ngữ (EN/VI)
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'preferred_language';
  static const String defaultLanguage = 'en';

  String _currentLanguage = defaultLanguage;
  int _languageId = 1; // 1 = EN, 2 = VI

  // Callbacks to notify when language changes
  final List<LanguageChangeCallback> _onLanguageChangedCallbacks = [];

  String get currentLanguage => _currentLanguage;
  int get languageId => _languageId;

  bool get isEnglish => _currentLanguage == 'en';
  bool get isVietnamese => _currentLanguage == 'vi';

  LanguageProvider() {
    _loadLanguage();
  }

  /// Register callback to be called when language changes
  void addLanguageChangeListener(LanguageChangeCallback callback) {
    _onLanguageChangedCallbacks.add(callback);
  }

  /// Remove callback
  void removeLanguageChangeListener(LanguageChangeCallback callback) {
    _onLanguageChangedCallbacks.remove(callback);
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? defaultLanguage;
    _languageId = _currentLanguage == 'vi' ? 2 : 1;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'vi') return;
    if (languageCode == _currentLanguage) return; // No change

    _currentLanguage = languageCode;
    _languageId = languageCode == 'vi' ? 2 : 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    // Notify all registered callbacks to reload data
    for (final callback in _onLanguageChangedCallbacks) {
      callback(_languageId);
    }

    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == 'en' ? 'vi' : 'en';
    await setLanguage(newLanguage);
  }

  /// Get localized text from "EN | VI" format
  String getLocalizedText(String text) {
    if (text.isEmpty) return text;
    final parts = text.split('|').map((e) => e.trim()).toList();
    if (_currentLanguage == 'vi' && parts.length > 1) {
      return parts[1];
    }
    return parts[0];
  }

  /// Get text based on language
  String getText({required String en, required String vi}) {
    return _currentLanguage == 'vi' ? vi : en;
  }
}

/// I18n Helper Functions
class I18n {
  static String parseMultiLang(String text, String languageCode) {
    if (text.isEmpty) return text;
    final parts = text.split('|').map((e) => e.trim()).toList();
    if (languageCode == 'vi' && parts.length > 1) {
      return parts[1];
    }
    return parts[0];
  }

  /// Get display name for day of week
  static String getDayName(int weekday, String languageCode) {
    final daysEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final daysVi = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];

    final index = (weekday - 1) % 7;
    return languageCode == 'vi' ? daysVi[index] : daysEn[index];
  }

  /// Get display name for month
  static String getMonthName(int month, String languageCode) {
    final monthsEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthsVi = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];

    final index = (month - 1) % 12;
    return languageCode == 'vi' ? monthsVi[index] : monthsEn[index];
  }

  /// Format number with locale
  static String formatNumber(num number, String languageCode) {
    if (languageCode == 'vi') {
      return number
          .toStringAsFixed(number.truncateToDouble() == number ? 0 : 1)
          .replaceAll('.', ',');
    }
    return number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 1);
  }
}
