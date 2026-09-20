import 'dart:async';
import 'dart:developer' as dev;
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps connectivity_plus to provide simple online/offline detection
/// and offline→online transition events.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _wasOffline = false;
  bool _isOnline = true;

  /// Callback triggered when connectivity transitions from offline → online.
  void Function()? onOnline;

  /// Callback triggered whenever connectivity status changes (or initializes).
  void Function(bool isOnline)? onConnectivityChange;

  ConnectivityService();

  /// Whether the device is currently online.
  bool get isOnline => _isOnline;

  /// Check the current connectivity state (one-shot).
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);
    onConnectivityChange?.call(_isOnline);
    return _isOnline;
  }

  /// Start listening for connectivity changes.
  /// Calls [onOnline] when transitioning from offline → online.
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final nowOnline = _hasConnection(results);

      if (nowOnline && _wasOffline) {
        dev.log('[ConnectivityService] Transition: offline → online');
        onOnline?.call();
      }

      _wasOffline = !nowOnline;
      final statusChanged = _isOnline != nowOnline;
      _isOnline = nowOnline;
      dev.log('[ConnectivityService] Status: ${nowOnline ? "online" : "offline"}');

      if (statusChanged) {
        onConnectivityChange?.call(nowOnline);
      }
    });

    // Initialize _wasOffline with current state
    checkConnectivity().then((online) {
      _wasOffline = !online;
      onConnectivityChange?.call(online);
    });
  }

  /// Stop listening for connectivity changes.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Returns true if any of the results indicate a usable connection.
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }
}
