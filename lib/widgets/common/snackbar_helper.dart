import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// SnackBar helpers - Display beautiful toast-like messages
class AppSnackBar {
  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: AppColors.success,
    );
  }

  /// Show error message
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show warning message
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: AppColors.warning,
    );
  }

  /// Show info message
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: AppColors.info,
    );
  }

  /// Show loading message with progress indicator
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showLoading(
    BuildContext context,
    String message,
  ) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      duration: const Duration(minutes: 5), // Long duration
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Hide current snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Internal show method
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: duration,
      action: action,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show error with retry action
  static void showErrorWithRetry(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
    String retryLabel = 'Retry',
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: retryLabel,
        textColor: Colors.white,
        onPressed: onRetry,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Extension on BuildContext for easy access
extension SnackBarExtension on BuildContext {
  void showSuccessSnack(String message) =>
      AppSnackBar.showSuccess(this, message);
  void showErrorSnack(String message) => AppSnackBar.showError(this, message);
  void showWarningSnack(String message) =>
      AppSnackBar.showWarning(this, message);
  void showInfoSnack(String message) => AppSnackBar.showInfo(this, message);
}
