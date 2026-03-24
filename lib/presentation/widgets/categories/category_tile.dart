import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/dialogs/edit_category_dialog.dart';
import 'package:kanakkan/presentation/widgets/categories/salary_wallet_setup_sheet.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/dialogs/subcategory_dialog.dart';

class CategoryTile extends StatelessWidget {
  final Category category;
  final Color accent;

  const CategoryTile({super.key, required this.category, required this.accent});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CategoryProvider>();
    final ledger = context.read<LedgerProvider>(); // Added for unusual choice check
    final balances = context.watch<CategoryBalanceProvider>();
    final subcategories = provider.subcategoriesOf(category.id!);
    final isSalaryWallet = category.isSalaryWallet;

    return ListTile(
      onTap: () => showDialog(
        context: context,
        builder: (_) => SubcategoryDialog(parent: category, accent: accent),
      ),

      // ── LEADING — neutral label icon + crown badge for salary wallet ──
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Icon(
              Icons.label_outline,
              color: accent,
              size: 18,
            ),
          ),
          if (isSalaryWallet)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),

      // ── TITLE — salary wallet pill ──
      title: Row(
        children: [
          Text(
            category.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (isSalaryWallet) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Salary Wallet',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),

      subtitle: subcategories.isNotEmpty
          ? Text(
              '${subcategories.length} subcategor${subcategories.length == 1 ? 'y' : 'ies'}',
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            )
          : null,

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${formatAmt(balances.getBalance(category.id!), decimals: false)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              if (value == 'set_salary') {
                final confirmed = await confirmWalletChange(
                  context: context,
                  categoryProvider: provider,
                  ledgerProvider: ledger,
                  tappedCategory: category,
                );
                if (confirmed) await provider.setSalaryWallet(category.id!);
              } else if (value == 'clear_salary') {
                final confirmed = await confirmWalletChange(
                  context: context,
                  categoryProvider: provider,
                  ledgerProvider: ledger,
                  tappedCategory: category,
                );
                if (confirmed) await provider.clearSalaryWallet();
              } else if (value == 'edit') {
                editCategoryDialog(context, category);
              } else if (value == 'delete') {
                final confirm = await ConfirmDeleteDialog.show(
                  context: context,
                  title: 'Delete Category',
                  message: subcategories.isNotEmpty
                      ? 'This will also delete all ${subcategories.length} subcategories permanently.'
                      : 'This will remove the category permanently.',
                );

                if (!confirm) return;

                await provider.deleteCategory(category.id!);

                if (provider.lastError != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.lastError!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Category deleted',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              // Any main category can become the salary wallet (no type guard)
              if (!isSalaryWallet)
                const PopupMenuItem(
                  value: 'set_salary',
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 18,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 10),
                      Text('Set as Salary Wallet'),
                    ],
                  ),
                ),
              if (isSalaryWallet)
                const PopupMenuItem(
                  value: 'clear_salary',
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        size: 18,
                        color: Colors.black45,
                      ),
                      SizedBox(width: 10),
                      Text('Remove Salary Wallet'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    SizedBox(width: 10),
                    Text('Delete', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
