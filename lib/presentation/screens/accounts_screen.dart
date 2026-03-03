import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final accounts = provider.accounts;

    final totalBalance = accounts.fold(
      0.0,
      (sum, a) => sum + (provider.accountBalances[a.id] ?? 0.0),
    );

    final totalIncome = provider.transactions
        .where((t) => t.type == "income")
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = provider.transactions
        .where((t) => t.type == "expense")
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ReusableAppBar(),
      body: Column(
        children: [
          /// TOP HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Column(
              children: [
                const Text(
                  "Accounts",
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Total Balance - ₹${totalBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
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
              color: Colors.white,
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
              mainAxisSize: MainAxisSize.min, // ⭐ IMPORTANT
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
                    shrinkWrap: true, // ⭐ IMPORTANT
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
          )
        ],
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
        border: Border.all(color: AppTheme.accent.withOpacity(.35)),
        color: Colors.white,
      ),

      child: Row(
        children: [
          /// ACCOUNT INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// NAME
                Text(
                  acc.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(height: 6),

                /// BALANCE
                Text(
                  "Balance - ₹${balance.toStringAsFixed(2)}",
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
            icon: const Icon(Icons.more_vert, color: AppTheme.primary),
            onSelected: (value) {
              if (value == "edit") {
                _editAccount(context, acc);
              } else if (value == "delete") {
                provider.deleteAccount(acc.id!);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "edit", child: Text("Edit")),
              PopupMenuItem(value: "delete", child: Text("Delete")),
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
          "₹${amount.toStringAsFixed(2)}",
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
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
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
                  const Text(
                    "Edit Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 24),

                  /// ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () {
                            context.read<LedgerProvider>().updateAccountName(
                              account.id!,
                              controller.text,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
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
