import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

/// Network Connectivity Provider - Theo dõi trạng thái kết nối mạng
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _isChecking = false;
  Timer? _checkTimer;

  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnectivity();
    });
    // Initial check
    checkConnectivity();
  }

  Future<void> checkConnectivity() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    } on SocketException catch (_) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    } on TimeoutException catch (_) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    } finally {
      _isChecking = false;
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

/// Offline Banner Widget
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, required this.isOffline, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isOffline ? 40 : 0,
      color: Colors.red[700],
      child:
          isOffline
              ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Không có kết nối mạng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (onRetry != null) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white70),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Thử lại',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}

/// Network Aware Widget - Hiển thị offline state khi mất kết nối
class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder - in real app, use Provider to get ConnectivityProvider
    return child;
  }
}
