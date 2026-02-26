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

  final TextEditingController amountController = TextEditingController();

  final TextEditingController noteController = TextEditingController();

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
            /// TRANSACTION TYPE SELECTOR
            ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              isSelected: [
                transactionType == "income",
                transactionType == "expense",
                transactionType == "transfer",
              ],
              onPressed: (index) {
                setState(() {
                  transactionType = ["income", "expense", "transfer"][index];
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Income"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Expense"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Transfer"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// BIG AMOUNT INPUT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "₹ 0.00",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 20),

            /// FROM ACCOUNT
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: transactionType != "income"
                  ? _accountDropdown(
                      label: "From Account",
                      accounts: provider.accounts,
                      selected: fromAccount,
                      onChanged: (acc) => setState(() => fromAccount = acc),
                    )
                  : const SizedBox(),
            ),

            /// TO ACCOUNT
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: transactionType != "expense"
                  ? _accountDropdown(
                      label: "To Account",
                      accounts: provider.accounts,
                      selected: toAccount,
                      onChanged: (acc) => setState(() => toAccount = acc),
                    )
                  : const SizedBox(),
            ),

            const SizedBox(height: 10),

            /// NOTE FIELD
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note"),
            ),

            const Spacer(),

            /// SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _saveTransaction(context),
                child: const Text(
                  "Save Transaction",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ACCOUNT DROPDOWN
  Widget _accountDropdown({
    required String label,
    required List<Account> accounts,
    required Account? selected,
    required Function(Account?) onChanged,
  }) {
    return DropdownButtonFormField<Account>(
      decoration: InputDecoration(labelText: label),
      initialValue: selected,
      items: accounts.map((acc) {
        return DropdownMenuItem(value: acc, child: Text(acc.name));
      }).toList(),
      onChanged: onChanged,
    );
  }

  /// SAVE LOGIC
  void _saveTransaction(BuildContext context) {
    final provider = context.read<LedgerProvider>();

    final amount = double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid amount")));
      return;
    }

    if (transactionType == "income") {
      if (toAccount == null) return;

      provider.addIncome(
        amount: amount,
        toAccountId: toAccount!.id!,
        note: noteController.text,
      );
    } else if (transactionType == "expense") {
      if (fromAccount == null) return;

      provider.addExpense(
        amount: amount,
        fromAccountId: fromAccount!.id!,
        note: noteController.text,
      );
    } else {
      if (fromAccount == null || toAccount == null) return;

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
