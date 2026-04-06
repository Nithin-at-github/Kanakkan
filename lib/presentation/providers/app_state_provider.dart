import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';

enum AppLockStatus { loading, noPin, locked, unlocked }

class AppStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SecurityService _security = SecurityService();

  AppLockStatus _status = AppLockStatus.loading;
  DateTime? _pausedAt;

  AppLockStatus get status => _status;

  /// Initialize app state
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);

    final hasPin = await _security.hasPin();

    if (!hasPin) {
      _status = AppLockStatus.noPin;
      notifyListeners();
      return;
    }

    final biometric = await _security.authenticateBiometric();

    _status = biometric ? AppLockStatus.unlocked : AppLockStatus.locked;

    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only set _pausedAt once when the app is first leaving the foreground.
    // This prevents the "resume" transition (inactive -> resumed) from
    // overwriting the original timestamp and resetting the idle timer.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsedSeconds = DateTime.now().difference(_pausedAt!).inSeconds;
        // Lock after 1 minute (60 seconds)
        if (elapsedSeconds >= 60 && _status == AppLockStatus.unlocked) {
          lockApp();
        }
      }
      _pausedAt = null;
    }
  }

  void lockApp() {
    _status = AppLockStatus.locked;
    notifyListeners();
  }

  void unlockApp() {
    _status = AppLockStatus.unlocked;
    notifyListeners();
  }

  void pinCreated() {
    _status = AppLockStatus.unlocked;
    notifyListeners();
  }
}
