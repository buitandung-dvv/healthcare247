import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../../data/models/user_model.dart';

/// Auth Repository - Xác thực và quản lý người dùng
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient.instance;

  /// Đăng nhập - returns (user, token) record
  Future<({User? user, String? token})> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.auth}/login',
        data: {'email': email, 'password': password},
      );

      if (response.data != null) {
        // API trả về: {"success":true,"data":{"user":{...},"token":"..."}}
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null && data['user'] != null) {
          final token = data['token'] as String?;
          // Lưu token nếu có
          if (token != null) {
            _apiClient.setAuthToken(token);
          }
          return (user: User.fromJson(data['user']), token: token);
        }
      }
      return (user: null, token: null);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Đăng ký - returns (user, token) record
  Future<({User? user, String? token})> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.auth}/register',
        data: {'username': username, 'email': email, 'password': password},
      );

      if (response.data != null) {
        // API trả về: {"success":true,"data":{"user":{...},"token":"..."}}
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null && data['user'] != null) {
          final token = data['token'] as String?;
          if (token != null) {
            _apiClient.setAuthToken(token);
          }
          return (user: User.fromJson(data['user']), token: token);
        }
      }
      return (user: null, token: null);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await _apiClient.post('${ApiConfig.auth}/logout');
      _apiClient.clearAuthToken();
    } catch (e) {
      _apiClient.clearAuthToken();
    }
  }

  /// Lấy thông tin user hiện tại
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConfig.auth}/me',
      );

      debugPrint('[AuthRepository] getCurrentUser response: ${response.data}');

      if (response.data != null) {
        final data = response.data!;
        // Handle wrapped response format { success, data: {...} }
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          return User.fromJson(data['data'] as Map<String, dynamic>);
        }
        // Direct user object
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('[AuthRepository] getCurrentUser error: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  /// Cập nhật thông tin user
  Future<User?> updateUser({
    String? username,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? goal,
    String? bodyGoals,
    String? activityLevel,
    int? preferredLanguageId,
    bool? onboardingCompleted,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConfig.auth}/me',
        data: {
          if (username != null) 'username': username,
          if (gender != null) 'gender': gender,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String(),
          if (height != null) 'height': height,
          if (weight != null) 'weight': weight,
          if (goal != null) 'goal': goal,
          if (bodyGoals != null) 'body_goals': bodyGoals,
          if (activityLevel != null) 'activity_level': activityLevel,
          if (preferredLanguageId != null)
            'preferred_language_id': preferredLanguageId,
          if (onboardingCompleted != null)
            'onboarding_completed': onboardingCompleted,
        },
      );

      debugPrint('[AuthRepository] updateUser response: ${response.data}');

      if (response.data != null) {
        final responseData = response.data!;
        debugPrint('[AuthRepository] responseData keys: ${responseData.keys}');

        // Handle wrapped response format { success: true, data: {...} }
        if (responseData.containsKey('data') &&
            responseData['data'] is Map<String, dynamic>) {
          debugPrint('[AuthRepository] Found data key, parsing user from data');
          final user = User.fromJson(
            responseData['data'] as Map<String, dynamic>,
          );
          debugPrint(
            '[AuthRepository] Parsed user: ${user.username}, gender: ${user.gender}',
          );
          return user;
        }
        // Handle wrapped response format { user: {...} }
        if (responseData.containsKey('user') &&
            responseData['user'] is Map<String, dynamic>) {
          debugPrint('[AuthRepository] Found user key, parsing user');
          return User.fromJson(responseData['user'] as Map<String, dynamic>);
        }
        // Direct user object (has user_id)
        if (responseData.containsKey('user_id')) {
          debugPrint('[AuthRepository] Found user_id key, parsing directly');
          return User.fromJson(responseData);
        }

        debugPrint('[AuthRepository] Unknown response format: $responseData');
      }
      return null;
    } catch (e) {
      debugPrint('[AuthRepository] updateUser error: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  /// Social login - đăng nhập qua Google/Facebook
  Future<({User? user, String? token})> socialLogin({
    required String provider,
    required String email,
    required String name,
    String? providerId,
    String? photoUrl,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConfig.auth}/social',
        data: {
          'provider': provider,
          'provider_id': providerId ?? '',
          'email': email,
          'name': name,
          if (photoUrl != null) 'photo_url': photoUrl,
        },
      );

      debugPrint('[AuthRepository] socialLogin response: ${response.data}');

      if (response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null && data['user'] != null) {
          final token = data['token'] as String?;
          if (token != null) {
            _apiClient.setAuthToken(token);
          }
          return (user: User.fromJson(data['user']), token: token);
        }
      }
      return (user: null, token: null);
    } catch (e) {
      debugPrint('[AuthRepository] socialLogin error: $e');
      throw Exception('Social login failed: $e');
    }
  }
}
