import 'package:flutter/material.dart';
import 'package:kanakkan/providers/budget_provider.dart';
import 'package:kanakkan/providers/category_balance_provider.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:kanakkan/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/widgets/app_initializer.dart';
import 'package:provider/provider.dart';

import 'providers/ledger_provider.dart';
import 'providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        /// ---------------- CATEGORY ----------------
        ChangeNotifierProvider(create: (_) => CategoryProvider()),

        /// ---------------- BALANCES ----------------
        ChangeNotifierProvider(create: (_) => CategoryBalanceProvider()),

        /// ---------------- LEDGER ----------------
        ChangeNotifierProxyProvider<CategoryBalanceProvider, LedgerProvider>(
          create: (context) =>
              LedgerProvider(context.read<CategoryBalanceProvider>()),
          update: (_, balanceProvider, previous) {
            if (previous == null) {
              // first time; return fresh provider
              return LedgerProvider(balanceProvider);
            }
            // reuse existing instance and update its dependency
            previous.updateBalanceProvider(balanceProvider);
            return previous;
          },
        ),

        /// ---------------- BUDGET ----------------
        ChangeNotifierProxyProvider<CategoryBalanceProvider, BudgetProvider>(
          create: (context) =>
              BudgetProvider(context.read<CategoryBalanceProvider>()),
          update: (_, balanceProvider, previous) {
            if (previous == null) {
              return BudgetProvider(balanceProvider);
            }
            previous.updateBalanceProvider(balanceProvider);
            return previous;
          },
        ),
        /// App auth / lock state
        ChangeNotifierProvider(create: (_) => AppStateProvider()..initialize()),
      ],
      child: const KanakkanApp(),
    ),
  );
}

class KanakkanApp extends StatelessWidget {
  const KanakkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kanakkan',

      /// Root decides which screen to show
      home: const AppInitializer(),
    );
  }
}
