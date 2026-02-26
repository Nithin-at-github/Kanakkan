import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/security_service.dart';

enum AppLockStatus { loading, noPin, locked, unlocked }

class AppStateProvider extends ChangeNotifier {
  final SecurityService _security = SecurityService();

  AppLockStatus _status = AppLockStatus.loading;

  AppLockStatus get status => _status;

  /// Initialize app state
  Future<void> initialize() async {
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
