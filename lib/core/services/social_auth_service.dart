import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Social Auth Service - Xử lý đăng nhập bằng Google/Facebook
class SocialAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Singleton instance
  static final SocialAuthService _instance = SocialAuthService._internal();
  factory SocialAuthService() => _instance;
  SocialAuthService._internal();

  /// Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Đăng nhập bằng Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the Facebook login flow
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        // User cancelled the sign-in
        return null;
      }

      if (result.status == LoginStatus.failed) {
        throw Exception('Facebook login failed: ${result.message}');
      }

      // Get the access token
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      // Create a credential from the access token
      final OAuthCredential facebookCredential =
          FacebookAuthProvider.credential(accessToken.tokenString);

      // Sign in to Firebase with the Facebook credential
      return await _firebaseAuth.signInWithCredential(facebookCredential);
    } catch (e) {
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  /// Đăng xuất Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
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
      await _googleSignIn.signOut();
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
