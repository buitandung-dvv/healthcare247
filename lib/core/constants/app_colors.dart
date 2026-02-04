import 'package:flutter/material.dart';

/// App Colors - Bảng màu cho ứng dụng HealthCare
/// Updated with Blue fitness app color palette (matching example UI)
class AppColors {
  AppColors._();

  // Primary Colors - Blue (like example UI)
  static const Color primary = Color(0xFF1E88E5); // Blue 600
  static const Color primaryDark = Color(0xFF1565C0); // Blue 800
  static const Color primaryLight = Color(0xFF64B5F6); // Blue 300
  static const Color primarySoft = Color(0xFFE3F2FD); // Blue 50

  // Secondary Colors - Light Blue/Cyan
  static const Color secondary = Color(0xFF29B6F6); // Light Blue 400
  static const Color secondaryDark = Color(0xFF0288D1); // Light Blue 700
  static const Color secondaryLight = Color(0xFF81D4FA); // Light Blue 200
  static const Color secondarySoft = Color(0xFFE1F5FE); // Light Blue 50

  // Accent Colors - Teal/Cyan for highlights
  static const Color accent = Color(0xFF26C6DA); // Cyan 400
  static const Color accentLight = Color(0xFF80DEEA); // Cyan 200
  static const Color accentSoft = Color(0xFFE0F7FA); // Cyan 50

  // Tertiary - Mint/Xanh lá
  static const Color tertiary = Color(0xFF42D9C8);
  static const Color tertiaryLight = Color(0xFF7FEAD9);
  static const Color tertiarySoft = Color(0xFFE8FBF8);

  // Background Colors
  static const Color background = Color(0xFFF7F8FC);
  static const Color backgroundAlt = Color(0xFFF0F3FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFFAFBFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1D1617);
  static const Color textSecondary = Color(0xFF7B6F72);
  static const Color textHint = Color(0xFFADA4A5);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFFDDDADA);

  // Status Colors
  static const Color success = Color(0xFF42BA96);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF2196F3);

  // Nutrient Colors - Macro tracking (blue tones)
  static const Color proteinColor = Color(0xFF1E88E5); // Blue
  static const Color carbsColor = Color(0xFF26C6DA); // Cyan
  static const Color fatColor = Color(0xFFFFB74D); // Orange
  static const Color caloriesColor = Color(0xFFEF5350); // Red
  static const Color fiberColor = Color(0xFF66BB6A); // Green

  // Level Colors (for exercises)
  static const Color beginnerColor = Color(0xFF42BA96);
  static const Color intermediateColor = Color(0xFFF5A623);
  static const Color expertColor = Color(0xFFFF5252);

  // Border & Divider
  static const Color border = Color(0xFFDDDADA);
  static const Color divider = Color(0xFFF7F8FC);

  // Shadow
  static const Color shadow = Color(0x1A1D1617);
  static const Color shadowLight = Color(0x0D1D1617);

  // Gradients - Blue fitness app gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF26C6DA), Color(0xFF80DEEA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF29B6F6), Color(0xFF4FC3F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category Colors (for recipes/meals)
  static const Map<String, Color> categoryColors = {
    'Beef': Color(0xFFE57373),
    'Chicken': Color(0xFFFFB74D),
    'Dessert': Color(0xFFEEA4CE),
    'Lamb': Color(0xFFA1887F),
    'Pasta': Color(0xFFFFD54F),
    'Seafood': Color(0xFF4FC3F7),
    'Vegetarian': Color(0xFF81C784),
    'Pork': Color(0xFFFFAB91),
    'Breakfast': Color(0xFFFFCC80),
    'Starter': Color(0xFF4DD0E1),
    'Side': Color(0xFFA5D6A7),
    'Vegan': Color(0xFF66BB6A),
    'Miscellaneous': Color(0xFF90A4AE),
  };

  // Muscle Group Colors (for exercises)
  static const Map<String, Color> muscleColors = {
    'chest': Color(0xFFE57373),
    'back': Color(0xFF64B5F6),
    'shoulders': Color(0xFFFFB74D),
    'arms': Color(0xFFBA68C8),
    'legs': Color(0xFF4DB6AC),
    'core': Color(0xFFFF8A65),
    'biceps': Color(0xFF7986CB),
    'triceps': Color(0xFF4DD0E1),
    'abdominals': Color(0xFFFFD54F),
    'quadriceps': Color(0xFF81C784),
    'hamstrings': Color(0xFFA1887F),
    'glutes': Color(0xFFF48FB1),
    'calves': Color(0xFF90CAF9),
    'forearms': Color(0xFFCE93D8),
    'lats': Color(0xFF80DEEA),
    'traps': Color(0xFFFFAB91),
    'lower back': Color(0xFFBCAAA4),
    'middle back': Color(0xFF80CBC4),
    'neck': Color(0xFFC5E1A5),
  };

  // ============================================
  // DARK MODE COLORS
  // ============================================

  // Dark Mode Background Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkCard = Color(0xFF252540);
  static const Color darkCardElevated = Color(0xFF2D2D4A);

  // Dark Mode Text Colors
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFB0B0B8);
  static const Color darkTextHint = Color(0xFF6B6B78);
  static const Color darkTextDisabled = Color(0xFF4A4A58);

  // Dark Mode Primary Colors (brighter blue for dark bg)
  static const Color darkPrimary = Color(0xFF64B5F6); // Blue 300
  static const Color darkPrimaryDark = Color(0xFF42A5F5); // Blue 400
  static const Color darkPrimaryLight = Color(0xFF90CAF9); // Blue 200

  // Dark Mode Secondary Colors
  static const Color darkSecondary = Color(0xFF4FC3F7); // Light Blue 300
  static const Color darkSecondaryDark = Color(0xFF29B6F6); // Light Blue 400
  static const Color darkSecondaryLight = Color(0xFF81D4FA); // Light Blue 200

  // Dark Mode Border & Divider
  static const Color darkBorder = Color(0xFF3A3A4C);
  static const Color darkDivider = Color(0xFF2A2A3C);

  // Dark Mode Shadow
  static const Color darkShadow = Color(0x40000000);
  static const Color darkShadowLight = Color(0x20000000);

  // Dark Mode Gradients
  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [darkPrimary, darkSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [darkCard, darkCardElevated],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
