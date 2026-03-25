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
import 'package:google_fonts/google_fonts.dart';

import 'presentation/providers/ledger_provider.dart';
import 'presentation/providers/app_state_provider.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.lato().fontFamily,
        textTheme: GoogleFonts.latoTextTheme(),
        scaffoldBackgroundColor: AppTheme.primary,
        canvasColor: Colors.white,
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        colorScheme: ColorScheme.light(
          surface: AppTheme.primary,
          primary: AppTheme.primary,
          secondary: AppTheme.accent,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          surfaceContainer: Colors.white,
          surfaceContainerHigh: Colors.white,
          surfaceContainerHighest: Colors.white,
          onSurface: Colors.black87,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
        popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Kanakkan',
      home: const AppInitializer(),
    );
  }
}
