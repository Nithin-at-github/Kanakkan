import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/analysis_provider.dart';
import 'package:kanakkan/presentation/providers/budget_provider.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/widgets/app_initializer.dart';
import 'package:kanakkan/presentation/providers/salary_allocation_provider.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/ledger_provider.dart';
import 'presentation/providers/app_state_provider.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        /// ---------------- CATEGORY ----------------
        ChangeNotifierProvider(create: (_) => CategoryProvider()),

        /// ---------------- BALANCES ----------------
        /// Single instance — loaded once here, shared by LedgerProvider
        /// and BudgetProvider via ProxyProvider below.
        /// Previously there were TWO CategoryBalanceProvider instances
        /// which caused double notifications and GPU buffer exhaustion.
        ChangeNotifierProvider(
          create: (_) {
            final provider = CategoryBalanceProvider();
            provider.loadBalances();
            return provider;
          },
        ),

        /// ---------------- SALARY ALLOCATION ----------------
        ChangeNotifierProvider(
          create: (_) {
            final provider = SalaryAllocationProvider();
            provider.loadTemplate();
            return provider;
          },
        ),

        /// ---------------- LEDGER ----------------
        ChangeNotifierProxyProvider2<
          CategoryProvider,
          CategoryBalanceProvider,
          LedgerProvider
        >(
          create: (context) => LedgerProvider(
            context.read<CategoryProvider>(),
            context.read<CategoryBalanceProvider>(),
          ),
          update: (_, categoryProvider, balanceProvider, ledger) {
            ledger!.updateDependencies(categoryProvider, balanceProvider);
            return ledger;
          },
        ),

        /// ---------------- BUDGET ----------------
        ChangeNotifierProxyProvider<CategoryBalanceProvider, BudgetProvider>(
          create: (context) =>
              BudgetProvider(context.read<CategoryBalanceProvider>()),
          update: (_, balanceProvider, previous) {
            if (previous == null) return BudgetProvider(balanceProvider);
            previous.updateBalanceProvider(balanceProvider);
            return previous;
          },
        ),

        /// ---------------- ANALYSIS ----------------
        ChangeNotifierProxyProvider2<
          LedgerProvider,
          CategoryProvider,
          AnalysisProvider
        >(
          create: (context) => AnalysisProvider(
            context.read<LedgerProvider>(),
            context.read<CategoryProvider>(),
          ),
          update: (_, ledger, categories, previous) {
            previous!.updateDependencies(ledger, categories);
            return previous;
          },
        ),

        /// App auth / lock state
        ChangeNotifierProvider(create: (_) => AppStateProvider()..initialize()),

        /// Theme State
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
      ],
      child: const KanakkanApp(),
    ),
  );
}

class KanakkanApp extends StatelessWidget {
  const KanakkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    // Sync static AppTheme flag for legacy code that doesn't use context
    final isDark = themeProvider.themeMode == ThemeMode.dark || 
        (themeProvider.themeMode == ThemeMode.system && 
         MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    themeProvider.updateAppThemeStatic(isDark);

    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      title: 'Kanakkan',
      home: const AppInitializer(),
    );
  }
}
