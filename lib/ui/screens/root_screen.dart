import 'package:flutter/material.dart';
import 'package:kanakkan/core/security/app_lock_manager.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/providers/app_state_provider.dart';
import 'package:kanakkan/ui/screens/create_pin_screen.dart';
import 'package:kanakkan/ui/screens/dashboard_screen.dart';
import 'package:kanakkan/ui/screens/lock_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {

  late AppLockManager _lockManager;

  @override
  void initState() {
    super.initState();

    _lockManager = AppLockManager(context);
    _lockManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    switch (appState.status) {
      case AppLockStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AppLockStatus.noPin:
        return const CreatePinScreen();

      case AppLockStatus.locked:
        return const LockScreen();

      case AppLockStatus.unlocked:
        return const DashboardScreen();
    }
  }
}
