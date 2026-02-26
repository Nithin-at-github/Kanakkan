import 'package:flutter/material.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/domain/entities/account.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String transactionType = "expense";

  final amountController = TextEditingController();
  final noteController = TextEditingController();

  Account? fromAccount;
  Account? toAccount;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Transaction Type Selector
            DropdownButton<String>(
              value: transactionType,
              items: const [
                DropdownMenuItem(value: "income", child: Text("Income")),
                DropdownMenuItem(value: "expense", child: Text("Expense")),
                DropdownMenuItem(value: "transfer", child: Text("Transfer")),
              ],
              onChanged: (value) {
                setState(() {
                  transactionType = value!;
                });
              },
            ),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),

            /// FROM account
            if (transactionType != "income")
              _accountDropdown(
                label: "From Account",
                accounts: provider.accounts,
                selected: fromAccount,
                onChanged: (acc) => setState(() => fromAccount = acc),
              ),

            /// TO account
            if (transactionType != "expense")
              _accountDropdown(
                label: "To Account",
                accounts: provider.accounts,
                selected: toAccount,
                onChanged: (acc) => setState(() => toAccount = acc),
              ),

            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _saveTransaction(context),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountDropdown({
    required String label,
    required List<Account> accounts,
    required Account? selected,
    required Function(Account?) onChanged,
  }) {
    return DropdownButton<Account>(
      hint: Text(label),
      value: selected,
      items: accounts.map((acc) {
        return DropdownMenuItem(value: acc, child: Text(acc.name));
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _saveTransaction(BuildContext context) {
    final provider = context.read<LedgerProvider>();

    final amount = double.tryParse(amountController.text);

    if (amount == null) return;

    if (transactionType == "income") {
      provider.addIncome(
        amount: amount,
        toAccountId: toAccount!.id!,
        note: noteController.text,
      );
    } else if (transactionType == "expense") {
      provider.addExpense(
        amount: amount,
        fromAccountId: fromAccount!.id!,
        note: noteController.text,
      );
    } else {
      provider.transferFunds(
        amount: amount,
        fromAccountId: fromAccount!.id!,
        toAccountId: toAccount!.id!,
        note: noteController.text,
      );
    }

    Navigator.pop(context);
  }
}
