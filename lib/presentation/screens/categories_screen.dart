import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/widgets/categories/categories_headet.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
import 'package:kanakkan/presentation/dialogs/move_wallet_dialog.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/widgets/categories/category_section.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final ledger = context.watch<LedgerProvider>();

    final totalIncome = ledger.transactions
        .where((t) => t.type == "income")
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = ledger.transactions
        .where((t) => t.type == "expense")
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ReusableAppBar(
        actions: [
          IconButton(
            icon: const Icon(
              Icons.swap_horiz,
              color: AppTheme.accent,
              size: 35,
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const MoveWalletDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          CategoriesHeader(income: totalIncome, expense: totalExpense),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                CategorySection(
                  title: "Income Categories",
                  categories: provider.incomeCategories,
                  accent: AppTheme.success,
                ),
                CategorySection(
                  title: "Expense Categories",
                  categories: provider.expenseCategories,
                  accent: AppTheme.error,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
