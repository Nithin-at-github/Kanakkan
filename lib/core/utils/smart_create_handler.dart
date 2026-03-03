import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/dialogs/add_account_dialog.dart';
import 'package:kanakkan/presentation/dialogs/add_category_dialog.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';
import 'package:kanakkan/presentation/widgets/set_budget_dialog.dart';

class SmartCreateHandler {
  /// Decides what FAB should do
  static void handle(BuildContext context, int tabIndex) {
    switch (tabIndex) {
      /// 0 → Dashboard / Records
      case 0:
        _openTransaction(context);
        break;

      /// 1 → Analysis (still transaction entry)
      case 1:
        _openTransaction(context);
        break;

      /// 2 → Budget tab
      case 2:
        showDialog(context: context, builder: (_) => const SetBudgetDialog());
        break;

      /// 2 → Accounts tab
      case 3:
        AddAccountDialog.show(context);
        break;

      /// 3 → Categories tab
      case 4:
        AddCategoryDialog.show(context);
        break;

      /// 4 → Future Budget tab
      default:
        _openTransaction(context);
    }
  }

  static void _openTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }
}
