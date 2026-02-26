import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/ui/screens/accounts_screen.dart';
import 'package:kanakkan/ui/screens/budget_screen.dart';
import 'package:kanakkan/ui/screens/categories_screen.dart';
import 'package:kanakkan/ui/screens/dashboard_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Analysis"));
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int currentIndex = 0;

  final pages = const [
    DashboardScreen(),
    AnalysisScreen(),
    BudgetScreen(),
    AccountsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// IMPORTANT: No AppBar here
      /// Each screen manages its own header
      body: IndexedStack(index: currentIndex, children: pages),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: "Records"),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "Analysis",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: "Budgets",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: "Accounts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Categories",
          ),
        ],
      ),
    );
  }
}
