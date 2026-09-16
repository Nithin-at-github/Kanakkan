import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/backup_settings_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/screens/root/root_screen.dart';
import 'package:provider/provider.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> with WidgetsBindingObserver {
  late Future _initFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer until after the first frame so the IME/window layout settles
    // before any notifyListeners() calls hit the render pipeline.
    _initFuture = Future.microtask(_initializeApp);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A second, independent check to when the app resumes from background —
    // covers the case where the app is kept alive for a long time without a
    // cold start. Fire-and-forget, same as the cold-start check below.
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<BackupSettingsProvider>().maybeRunAutoBackup());
    }
  }

  Future<void> _initializeApp() async {
    final ledger = context.read<LedgerProvider>();
    final categories = context.read<CategoryProvider>();
    final backupSettings = context.read<BackupSettingsProvider>();

    // Run concurrently — halves init time and produces a single
    // combined notify burst instead of two sequential ones.
    await Future.wait([ledger.initialize(), categories.initialize()]);

    // Fire-and-forget — must not delay showing RootScreen. Errors land in
    // BackupSettingsProvider.lastBackupError for Settings to surface later.
    unawaited(backupSettings.maybeRunAutoBackup());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        return const RootScreen();
      },
    );
  }
}
