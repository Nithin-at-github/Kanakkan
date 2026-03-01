import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/utils/smart_create_handler.dart';
import 'package:kanakkan/providers/navigation_provider.dart';
import 'package:kanakkan/ui/screens/accounts_screen.dart';
import 'package:kanakkan/ui/screens/analysis_screen.dart';
import 'package:kanakkan/ui/screens/budget_screen.dart';
import 'package:kanakkan/ui/screens/categories_screen.dart';
import 'package:kanakkan/ui/screens/dashboard_screen.dart';
import 'package:kanakkan/ui/widgets/universal_create_sheet.dart';
import 'package:provider/provider.dart';

class RootScaffold extends StatelessWidget {
  const RootScaffold({super.key});

  @override
  Widget build(BuildContext context) {

    final nav = context.watch<NavigationProvider>();

    final pages = const [
      DashboardScreen(),   // index 0
      AnalysisScreen(),    // index 1
      BudgetScreen(),      // index 2
      AccountsScreen(),    // index 3
      CategoriesScreen(),  // index 4
    ];

    return Scaffold(

      floatingActionButton: GestureDetector(
        onLongPress: () {
          /// LONG PRESS → Universal creator
          UniversalCreateSheet.show(context);
        },

        child: FloatingActionButton.extended(
          backgroundColor: AppTheme.accent,
          elevation: 6,
          icon: const Icon(Icons.add),
          label: Text(_fabLabel(nav.currentIndex)),

          /// SHORT PRESS → Smart action
          onPressed: () {
            SmartCreateHandler.handle(context, nav.currentIndex);
          },
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      body: IndexedStack(
        index: nav.currentIndex,
        children: pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: nav.currentIndex,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          context.read<NavigationProvider>().setIndex(index);
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "Records",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "Analysis",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Budget",
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
  
  String _fabLabel(int index) {
    switch (index) {
      case 0:
        return "Transaction";
      case 1:
        return "Transaction";
      case 2:
        return "Budget";
      case 3:
        return "Account";
      case 4:
        return "Category";
      default:
        return "Create";
    }
  }
}