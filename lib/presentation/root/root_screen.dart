import 'package:flutter/material.dart';
import 'package:kanakkan/providers/app_state_provider.dart';
import 'package:kanakkan/presentation/root/root_scaffold.dart';
import 'package:kanakkan/presentation/screens/create_pin_screen.dart';
import 'package:kanakkan/presentation/screens/lock_screen.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

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
        return const RootScaffold();
    }
  }
}
