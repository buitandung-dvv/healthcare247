import 'package:flutter/material.dart';

/// App Sizes - 4px grid system
class AppSizes {
  AppSizes._();

  // Base unit (4px grid)
  static const double unit = 4.0;

  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Padding
  static const EdgeInsets paddingXs = EdgeInsets.all(4);
  static const EdgeInsets paddingSm = EdgeInsets.all(8);
  static const EdgeInsets paddingMd = EdgeInsets.all(16);
  static const EdgeInsets paddingLg = EdgeInsets.all(24);
  static const EdgeInsets paddingXl = EdgeInsets.all(32);

  // Horizontal Padding
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(
    horizontal: 8,
  );
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: 24,
  );

  // Vertical Padding
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: 16,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: 24,
  );

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusCard = 20.0; // Stitch card radius
  static const double radiusFull = 999.0;

  // Icon Sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Font Sizes
  static const double fontXs = 10.0;
  static const double fontSm = 12.0;
  static const double fontMd = 14.0;
  static const double fontLg = 16.0;
  static const double fontXl = 18.0;
  static const double fontXxl = 20.0;
  static const double fontHeading = 24.0;
  static const double fontTitle = 28.0;
  static const double fontDisplay = 32.0;

  // Card Sizes
  static const double cardHeightSm = 100.0;
  static const double cardHeightMd = 150.0;
  static const double cardHeightLg = 200.0;

  // Button Heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 52.0;

  // Input Heights
  static const double inputHeight = 48.0;

  // Avatar Sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  // Bottom Navigation
  static const double bottomNavHeight = 60.0;

  // App Bar
  static const double appBarHeight = 56.0;

  // Max Width for content
  static const double maxContentWidth = 600.0;
}
