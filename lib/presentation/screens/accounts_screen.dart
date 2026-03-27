import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final accounts = provider.accounts;

    final totalBalance = accounts.fold(
      0.0,
      (sum, a) => sum + (provider.accountBalances[a.id] ?? 0.0),
    );

    final totalIncome = provider.transactions
        .where(
          (t) =>
              t.type == "income" &&
              t.transferGroupId == null &&
              !categoryProvider.isExcluded(t.categoryId),
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = provider.transactions
        .where(
          (t) =>
              t.type == "expense" &&
              t.transferGroupId == null &&
              !categoryProvider.isExcluded(t.categoryId),
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ReusableAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// TOP HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Accounts",
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Total Balance → ₹${formatAmt(totalBalance)}",
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryColumn(
                        "EXPENSE SO FAR",
                        totalExpense,
                        AppTheme.error,
                      ),
                      _summaryColumn(
                        "INCOME SO FAR",
                        totalIncome,
                        AppTheme.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// WHITE CONTENT CONTAINER
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (accounts.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          "No accounts added",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Accounts",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final acc = accounts[index];
                        final balance = provider.accountBalances[acc.id] ?? 0.0;
                        return _accountTile(context, acc, balance);
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountTile(BuildContext context, Account acc, double balance) {
    final provider = context.read<LedgerProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: .35)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          /// ACCOUNT INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acc.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Balance → ₹${formatAmt(balance)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: balance < 0 ? AppTheme.error : AppTheme.success,
                  ),
                ),
              ],
            ),
          ),

          /// THREE DOT MENU
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: Icon(Icons.more_vert, color: AppTheme.primary),
            onSelected: (value) async {
              if (value == "edit") {
                _editAccount(context, acc);
              } else if (value == "delete") {
                final confirm = await ConfirmDeleteDialog.show(
                  context: context,
                  title: "Delete Account",
                  message:
                      "All related transactions will remain but account will be removed.",
                );
                if (!confirm) return;
                provider.deleteAccount(acc.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Account deleted",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: "edit",
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text("Edit"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    const SizedBox(width: 10),
                    Text("Delete", style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryColumn(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          "₹${formatAmt(amount)}",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _editAccount(BuildContext context, Account account) {
    final controller = TextEditingController(text: account.name);

    showDialog(
      context: context,
      builder: (_) => Consumer<LedgerProvider>(
        builder: (context, ledger, _) {
          return Dialog(
            backgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Edit Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ACCOUNT NAME
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: "Account name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// INITIAL BALANCE — read-only display
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: "Initial balance",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Tooltip(
                        message: "Initial balance cannot be changed",
                        child: Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Colors.black38,
                        ),
                      ),
                    ),
                    child: Text(
                      "₹${formatAmt(account.initialBalance)}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                  /// ERROR MESSAGE
                  if (ledger.lastError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ledger.lastError!,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  /// ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ledger.clearError();
                            Navigator.pop(context);
                          },
                          child: Text("Cancel"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () async {
                            ledger.clearError();

                            final newName = controller.text.trim();

                            final ledgerRef = context.read<LedgerProvider>();
                            await ledgerRef.updateAccount(
                              Account(
                                id: account.id,
                                name: newName,
                                // preserve the original initial balance unchanged
                                initialBalance: account.initialBalance,
                              ),
                            );

                            if (ledgerRef.lastError == null) {
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          child: Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
