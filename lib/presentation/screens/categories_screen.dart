import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/dialogs/merge_categories_dialog.dart';
import 'package:kanakkan/presentation/dialogs/move_wallet_dialog.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
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
    final balances = context.watch<CategoryBalanceProvider>();

    // Calculate filtered metrics
    MapEntry<int, double>? topEntry;
    double totalWallet = 0;
    for (final entry in balances.balances.entries) {
      if (provider.isExcluded(entry.key)) continue;

      totalWallet += entry.value;
      if (topEntry == null || entry.value > topEntry.value) {
        topEntry = entry;
      }
    }

    final topCategory =
        topEntry != null ? provider.resolveCategory(topEntry.key) : null;
    final topCategoryName = topCategory?.name ?? 'None';
    final topCategoryAmount = topEntry?.value ?? 0.0;

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
            icon: Icon(
              Icons.call_merge,
              color: AppTheme.accent,
              size: 28,
            ),
            tooltip: 'Merge Categories',
            onPressed: () => MergeCategoriesDialog.show(context),
          ),
          IconButton(
            icon: Icon(
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
          CategoriesHeader(
            totalWallet: totalWallet,
            topCategoryName: topCategoryName,
            topCategoryAmount: topCategoryAmount,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                CategorySection(
                  title: 'Categories',
                  categories: provider.mainCategories,
                  accent: AppTheme.accent,
                  showSalaryWalletBanner:
                      !provider.hasSalaryWallet &&
                      provider.mainCategories.isNotEmpty,
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
