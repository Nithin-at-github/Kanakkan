import 'package:flutter/material.dart';
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

    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    final ledger = context.read<LedgerProvider>();

    final categories = context.read<CategoryProvider>();

    await ledger.initialize();
    await categories.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const RootScreen();
      },
    );
  }
}
