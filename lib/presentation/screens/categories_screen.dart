import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/dialogs/move_wallet_dialog.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/widgets/categories/categories_header.dart';
import 'package:kanakkan/presentation/widgets/categories/category_section.dart';
import 'package:kanakkan/presentation/widgets/categories/salary_wallet_setup_sheet.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
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
          // Crown button — always visible, opens setup/management sheet
          IconButton(
            icon: Icon(
              Icons.workspace_premium,
              // Amber when designated, muted when not
              color: provider.hasSalaryWallet
                  ? Colors.amber
                  : AppTheme.accent.withValues(alpha: 0.5),
              size: 28,
            ),
            tooltip: provider.hasSalaryWallet
                ? 'Manage Salary Wallet'
                : 'Set up Salary Wallet',
            onPressed: () => SalaryWalletSetupSheet.show(context),
          ),
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
                  // Pass flag so section can show amber banner
                  showSalaryWalletBanner:
                      !provider.hasSalaryWallet &&
                      provider.incomeCategories.isNotEmpty,
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
