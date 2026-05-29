import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../core/repositories/auth_repository.dart';
import '../core/services/social_auth_service.dart';
import '../core/network/api_client.dart';

/// Auth Provider - Quản lý xác thực và thông tin người dùng
class AuthProvider extends ChangeNotifier {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _tokenKey = 'auth_token';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  final AuthRepository _authRepository;
  User? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  int get userId => _currentUser?.userId ?? 0;
  String? get token => _token;

  AuthProvider({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      _token = prefs.getString(_tokenKey);

      if (_isLoggedIn && _token != null) {
        // Set token on ApiClient for authenticated requests
        ApiClient.instance.setAuthToken(_token!);

        // Try to get current user from API to validate token
        try {
          final user = await _authRepository.getCurrentUser();
          if (user != null) {
            _currentUser = user;
            // Cache onboarding status locally
            _localOnboardingCompleted = user.onboardingCompleted;
            await prefs.setBool(
              _onboardingCompletedKey,
              user.onboardingCompleted,
            );
          } else {
            // Fallback to cached data
            _loadCachedUser(prefs);
          }
        } catch (e) {
          // Check if error is 401 (unauthorized) - token expired/invalid
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
            // Token is invalid, force logout
            await prefs.clear();
            ApiClient.instance.clearAuthToken();
            _currentUser = null;
            _isLoggedIn = false;
            _token = null;
            _errorMessage = 'Session expired. Please login again.';
          } else {
            // Other API error, use cached data
            _loadCachedUser(prefs);
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _loadCachedUser(SharedPreferences prefs) {
    final userId = prefs.getInt(_userIdKey) ?? 0;
    final cachedOnboarding = prefs.getBool(_onboardingCompletedKey) ?? false;
    _currentUser = User(
      userId: userId,
      username: prefs.getString(_usernameKey) ?? '',
      email: prefs.getString(_emailKey) ?? '',
      onboardingCompleted: cachedOnboarding,
    );
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call real API
      final result = await _authRepository.login(email, password);

      if (result.user != null) {
        _currentUser = result.user;
        _token = result.token;

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setInt(_userIdKey, result.user!.userId);
        await prefs.setString(_usernameKey, result.user!.username);
        await prefs.setString(_emailKey, result.user!.email);
        if (result.token != null) {
          await prefs.setString(_tokenKey, result.token!);
          // Set token on ApiClient immediately
          ApiClient.instance.setAuthToken(result.token!);
        }

        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login failed. Please check your credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final socialAuth = SocialAuthService();
      final credential = await socialAuth.signInWithGoogle();

      if (credential != null && credential.user != null) {
        final firebaseUser = credential.user!;

        // Call backend API to register/login user and get JWT token
        final result = await _authRepository.socialLogin(
          provider: 'google',
          email: firebaseUser.email ?? '',
          name:
              firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'User',
          providerId: firebaseUser.uid,
          photoUrl: firebaseUser.photoURL,
        );

        if (result.user != null && result.token != null) {
          _currentUser = result.user;
          _token = result.token;

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_isLoggedInKey, true);
          await prefs.setInt(_userIdKey, result.user!.userId);
          await prefs.setString(_usernameKey, result.user!.username);
          await prefs.setString(_emailKey, result.user!.email);
          await prefs.setString(_tokenKey, result.token!);

          // Set token on ApiClient for authenticated requests
          ApiClient.instance.setAuthToken(result.token!);

          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();
          debugPrint(
            '[AuthProvider] Google login success: ${result.user!.email}',
          );
          return true;
        } else {
          _errorMessage = 'Failed to authenticate with server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Google sign-in was cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng nhập bằng Facebook
  Future<bool> loginWithFacebook() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final socialAuth = SocialAuthService();
      final credential = await socialAuth.signInWithFacebook();

      if (credential != null && credential.user != null) {
        final firebaseUser = credential.user!;

        // Call backend API to register/login user and get JWT token
        final result = await _authRepository.socialLogin(
          provider: 'facebook',
          email: firebaseUser.email ?? '',
          name:
              firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'User',
          providerId: firebaseUser.uid,
          photoUrl: firebaseUser.photoURL,
        );

        if (result.user != null && result.token != null) {
          _currentUser = result.user;
          _token = result.token;

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_isLoggedInKey, true);
          await prefs.setInt(_userIdKey, result.user!.userId);
          await prefs.setString(_usernameKey, result.user!.username);
          await prefs.setString(_emailKey, result.user!.email);
          await prefs.setString(_tokenKey, result.token!);

          // Set token on ApiClient for authenticated requests
          ApiClient.instance.setAuthToken(result.token!);

          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();
          debugPrint(
            '[AuthProvider] Facebook login success: ${result.user!.email}',
          );
          return true;
        } else {
          _errorMessage = 'Failed to authenticate with server';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Facebook sign-in was cancelled';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call real API
      final result = await _authRepository.register(
        username: username,
        email: email,
        password: password,
      );

      if (result.user != null) {
        _currentUser = result.user;
        _token = result.token;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setInt(_userIdKey, result.user!.userId);
        await prefs.setString(_usernameKey, result.user!.username);
        await prefs.setString(_emailKey, result.user!.email);
        if (result.token != null) {
          await prefs.setString(_tokenKey, result.token!);
        }

        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear token from ApiClient
      ApiClient.instance.clearAuthToken();

      _currentUser = null;
      _isLoggedIn = false;
      _token = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? goal,
    int? preferredLanguageId,
  }) async {
    if (_currentUser == null) {
      debugPrint('[AuthProvider] updateProfile: No current user');
      return;
    }

    debugPrint('[AuthProvider] updateProfile called with:');
    debugPrint('  username: $username');
    debugPrint('  gender: $gender');
    debugPrint('  height: $height');
    debugPrint('  weight: $weight');

    // Note: Don't set isLoading here to avoid triggering AppWrapper rebuild
    // which would reset MainNavigationScreen to index 0

    try {
      // Call real API
      final updatedUser = await _authRepository.updateUser(
        username: username,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
        weight: weight,
        goal: goal,
        preferredLanguageId: preferredLanguageId,
      );

      debugPrint('[AuthProvider] updateProfile response: $updatedUser');

      if (updatedUser != null) {
        _currentUser = updatedUser;
        debugPrint('[AuthProvider] Profile updated successfully');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_usernameKey, updatedUser.username);
        notifyListeners(); // Only notify to update user data in UI
      } else {
        debugPrint('[AuthProvider] updateProfile: updatedUser is null');
      }
    } catch (e) {
      debugPrint('[AuthProvider] updateProfile error: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final socialAuth = SocialAuthService();
      await socialAuth.sendPasswordResetEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if user has completed onboarding
  bool get onboardingCompleted =>
      _currentUser?.onboardingCompleted ?? _localOnboardingCompleted;
  bool _localOnboardingCompleted = false;

  /// Quick update user goal from profile
  Future<bool> updateUserGoal(String goal) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = await _authRepository.updateUser(goal: goal);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] updateUserGoal error: $e');
      return false;
    }
  }

  /// Complete onboarding - save user data and mark as completed
  Future<bool> completeOnboarding({
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? activityLevel,
    String? goal,
    String? bodyGoals,
  }) async {
    debugPrint('[AuthProvider] completeOnboarding called');
    debugPrint('[AuthProvider] currentUser: $_currentUser');

    if (_currentUser == null) {
      debugPrint('[AuthProvider] ERROR: currentUser is null, returning false');
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[AuthProvider] Calling updateUser with:');
      debugPrint('  gender: $gender');
      debugPrint('  dateOfBirth: $dateOfBirth');
      debugPrint('  height: $height');
      debugPrint('  weight: $weight');
      debugPrint('  activityLevel: $activityLevel');
      debugPrint('  goal: $goal');
      debugPrint('  bodyGoals: $bodyGoals');

      final updatedUser = await _authRepository.updateUser(
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
        goal: goal,
        bodyGoals: bodyGoals,
        onboardingCompleted: true,
      );

      debugPrint('[AuthProvider] updateUser result: $updatedUser');

      if (updatedUser != null) {
        _currentUser = updatedUser;
        // Persist onboarding completed locally as safety net
        _localOnboardingCompleted = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardingCompletedKey, true);
        _isLoading = false;
        notifyListeners();
        debugPrint(
          '[AuthProvider] SUCCESS: User updated, onboardingCompleted=${updatedUser.onboardingCompleted}',
        );
        return true;
      } else {
        // Even if API response is null, mark locally as completed so user isn't stuck
        _localOnboardingCompleted = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_onboardingCompletedKey, true);
        _isLoading = false;
        notifyListeners();
        debugPrint(
          '[AuthProvider] WARNING: updatedUser is null but marking completed locally',
        );
        return true;
      }
    } catch (e) {
      debugPrint('[AuthProvider] EXCEPTION: $e');
      // Even on error, mark completed locally so user isn't stuck in loop
      _localOnboardingCompleted = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return true; // Return true so user can proceed
    }
  }

  /// Refresh current user data from server
  Future<void> refreshUser() async {
    if (_currentUser == null) return;

    try {
      final updatedUser = await _authRepository.getCurrentUser();
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
        debugPrint(
          '[AuthProvider] User refreshed - weight: ${updatedUser.weight}',
        );
      }
    } catch (e) {
      debugPrint('[AuthProvider] refreshUser error: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
