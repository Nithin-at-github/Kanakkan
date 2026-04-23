import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/screens/root/root_screen.dart';
import 'package:provider/provider.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future _initFuture;

  @override
  void initState() {
    super.initState();
    // Defer until after the first frame so the IME/window layout settles
    // before any notifyListeners() calls hit the render pipeline.
    _initFuture = Future.microtask(_initializeApp);
  }

  Future<void> _initializeApp() async {
    final ledger = context.read<LedgerProvider>();
    final categories = context.read<CategoryProvider>();

    // Run concurrently — halves init time and produces a single
    // combined notify burst instead of two sequential ones.
    await Future.wait([ledger.initialize(), categories.initialize()]);
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
