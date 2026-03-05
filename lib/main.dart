import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/budget_provider.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/widgets/app_initializer.dart';
import 'package:kanakkan/presentation/providers/salary_allocation_provider.dart';
import 'package:provider/provider.dart';

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
        ChangeNotifierProvider(create: (_) => CategoryBalanceProvider()),

        /// IMPORTANT: Ledger and Budget depend on CategoryBalanceProvider, so we use ProxyProvider to ensure they get the updated balances when they change.
        ChangeNotifierProvider(
          create: (_) {
            final provider = CategoryBalanceProvider();
            provider.loadBalances(); // IMPORTANT
            return provider;
          },
        ),

         // ---------------- SALARY ALLOCATION ----------------
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
          create: (_) =>
              LedgerProvider(CategoryProvider(), CategoryBalanceProvider()),
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
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.background,
        // canvasColor: AppTheme.background,
      ),
      debugShowCheckedModeBanner: false,
      title: 'Kanakkan',

      /// Root decides which screen to show
      home: const AppInitializer(),
    );
  }
}
