import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Social Auth Service - Xử lý đăng nhập bằng Google/Facebook
/// Updated for google_sign_in v7.2.0 API
class SocialAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  /// Singleton instance
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  /// Initialize GoogleSignIn (required for v7.x)
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  /// Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // Trigger the authentication flow (v7.x uses authenticate())
      // authenticate() throws GoogleSignInException on failure
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // In v7.x, idToken is accessed via authentication getter
      final idToken = googleUser.authentication.idToken;

      // Create a new credential with idToken
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      // Sign in to Firebase with the Google credential
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Đăng nhập bằng Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      debugPrint('[FacebookAuth] Starting Facebook login...');

      // Trigger the Facebook login flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      debugPrint('[FacebookAuth] Login status: ${result.status}');
      debugPrint('[FacebookAuth] Message: ${result.message}');

      if (result.status == LoginStatus.cancelled) {
        // User cancelled the sign-in
        debugPrint('[FacebookAuth] User cancelled login');
        return null;
      }

      if (result.status == LoginStatus.failed) {
        debugPrint('[FacebookAuth] Login failed: ${result.message}');
        throw Exception('Facebook login failed: ${result.message}');
      }

      // Get the access token
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        debugPrint('[FacebookAuth] Access token is null');
        throw Exception('Failed to get Facebook access token');
      }

      debugPrint(
        '[FacebookAuth] Got access token, creating Firebase credential...',
      );

      // Create a credential from the access token
      final OAuthCredential facebookCredential =
          FacebookAuthProvider.credential(accessToken.tokenString);

      // Sign in to Firebase with the Facebook credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        facebookCredential,
      );
      debugPrint(
        '[FacebookAuth] Firebase sign-in successful: ${userCredential.user?.email}',
      );

      return userCredential;
    } catch (e) {
      debugPrint('[FacebookAuth] Error: $e');
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  /// Đăng xuất Google
  Future<void> signOutGoogle() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.disconnect();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Đăng xuất Facebook
  Future<void> signOutFacebook() async {
    try {
      await FacebookAuth.instance.logOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Facebook sign out failed: $e');
    }
  }

  /// Đăng xuất tất cả
  Future<void> signOutAll() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.disconnect();
      await FacebookAuth.instance.logOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Kiểm tra đã đăng nhập chưa
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Lấy user hiện tại
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream để theo dõi trạng thái auth
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Gửi email reset mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Không tìm thấy tài khoản với email này');
        case 'invalid-email':
          throw Exception('Email không hợp lệ');
        default:
          throw Exception('Gửi email thất bại: ${e.message}');
      }
    } catch (e) {
      throw Exception('Gửi email thất bại: $e');
    }
  }
}
