import 'package:flutter/material.dart';
import 'package:kanakkan/providers/budget_provider.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:kanakkan/providers/navigation_provider.dart';
import 'package:kanakkan/ui/root/root_screen.dart';
import 'package:provider/provider.dart';

import 'providers/ledger_provider.dart';
import 'providers/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        
        ChangeNotifierProvider(create: (_) => NavigationProvider()),

        /// Financial state
        ChangeNotifierProvider(create: (_) => LedgerProvider()),

        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..loadCategories(),
        ),

        ChangeNotifierProvider(create: (_) => BudgetProvider()..loadBudgets()),

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
      home: const RootScreen(),
    );
  }
}
