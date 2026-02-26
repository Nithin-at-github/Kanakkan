import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();
    final accounts = provider.accounts;

    final totalBalance = accounts.fold(0.0, (sum, a) => sum + (provider.accountBalances[a.id] ?? 0.0));

    final totalIncome = provider.transactions
        .where((t) => t.type == "income")
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = provider.transactions
        .where((t) => t.type == "expense")
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          "കണക്കൻ",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
        ),
      ),
      body: Column(
        children: [
          /// TOP HEADER
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  "[ All Accounts ₹${totalBalance.toStringAsFixed(2)} ]",
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

          /// ACCOUNTS LIST
          Expanded(
            child: ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final acc = accounts[index];
                final balance = provider.accountBalances[acc.id] ?? 0.0;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.accent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      /// Name + Balance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Balance: ₹${balance.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: balance < 0
                                    ? AppTheme.error
                                    : AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// THREE DOT MENU
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "edit") {
                            _editAccount(context, acc);
                          } else if (value == "delete") {
                            provider.deleteAccount(acc.id!);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: "edit", child: Text("Edit")),
                          PopupMenuItem(value: "delete", child: Text("Delete")),
                        ],
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /// ADD NEW ACCOUNT BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              onPressed: () {
                _addAccountDialog(context);
              },
              icon: const Icon(Icons.add, color: AppTheme.accent),
              label: const Text(
                "ADD NEW ACCOUNT",
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
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

  void _addAccountDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Account"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Account Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LedgerProvider>().addAccount(
                Account(
                  name: nameController.text,
                  entityType: "ME",
                  mediumType: "BANK",
                ),
              );
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _editAccount(BuildContext context, Account account) {
    final controller = TextEditingController(text: account.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Account"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LedgerProvider>().updateAccountName(
                account.id!,
                controller.text,
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
