import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// API Configuration - Dành cho Emulator/Simulator
class ApiConfig {
  ApiConfig._();

  /// Port của backend server
  static const int _serverPort = 5000;

  /// Server host - Tự động chọn theo platform
  static String get _serverHost {
    // Web: always use localhost
    if (kIsWeb) {
      return 'http://localhost:$_serverPort';
    }

    // Android Emulator: 10.0.2.2 trỏ đến localhost của máy host
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_serverPort';
    }

    // iOS Simulator / Desktop: dùng localhost
    return 'http://localhost:$_serverPort';
  }

  // Base URL for API
  static String get baseUrl => '$_serverHost/api';

  // Base URL for static images
  static String get imageBaseUrl => _serverHost;

  /// Get full URL for an image path
  /// Backend now returns full relative paths (e.g., /images/exercises/...)
  /// Frontend just needs to prepend the server host
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Ensure the path starts with /
    if (!imagePath.startsWith('/')) {
      imagePath = '/$imagePath';
    }
    return '$imageBaseUrl$imagePath';
  }

  // Endpoints
  static const String exercises = '/exercises';
  static const String exerciseDetail = '/exercises/{id}';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipes/{id}';
  static const String foods = '/foods';
  static const String meals = '/meals';
  static const String plans = '/plans';
  static const String tracking = '/tracking';
  static const String auth = '/auth';
  static const String users = '/users';
  static const String favorites = '/favorites';
  static const String workoutSessions = '/workout-sessions';

  // Query Parameters
  static const String languageParam = 'language_id';
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
  static const String searchParam = 'search';

  // Timeouts - Optimized for fast response
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Retry configuration - Reduced for faster failure
  static const int maxRetries = 1;
  static const Duration retryDelay = Duration(milliseconds: 500);
}
