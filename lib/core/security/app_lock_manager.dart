import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class AppLockManager extends WidgetsBindingObserver {
  final BuildContext context;

  AppLockManager(this.context);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lockApp();
    }

    // Optional: also lock when inactive
    if (state == AppLifecycleState.inactive) {
      _lockApp();
    }
  }

  void _lockApp() {
    final appState = context.read<AppStateProvider>();

    // Only lock if currently unlocked
    if (appState.status == AppLockStatus.unlocked) {
      appState.lockApp();
    }
  }
}
