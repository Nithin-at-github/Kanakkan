import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/domain/entities/account.dart';

enum TransactionType { income, expense, transfer }

class AddTransactionScreen extends StatefulWidget {
  final TransactionEntity? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType type = TransactionType.expense;
  bool get isEditMode => widget.transaction != null;

  Account? selectedAccount;
  Account? selectedToAccount;
  Category? selectedCategory;

  String amount = "0";

  DateTime selectedDateTime = DateTime.now();

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final tx = widget.transaction;

    if (tx != null) {
      amount = tx.amount.toString();

      selectedDateTime = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);

      _noteController.text = tx.note ?? "";

      /// TYPE
      if (tx.type == "income") {
        type = TransactionType.income;
      } else {
        type = TransactionType.expense;
      }

      /// ACCOUNTS WILL BE RESOLVED AFTER BUILD
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ledger = context.read<LedgerProvider>();

        setState(() {
          selectedAccount = ledger.accounts.firstWhere(
            (a) =>
                a.id ==
                (tx.type == "income" ? tx.toAccountId : tx.fromAccountId),
          );
        });

        final categories = context.read<CategoryProvider>();

        if (tx.categoryId != null) {
          selectedCategory = categories.categories.firstWhere(
            (c) => c.id == tx.categoryId,
          );
        }
      });
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final ledger = context.watch<LedgerProvider>();
    final categoriesProvider = context.watch<CategoryProvider>();

    final categories = type == TransactionType.income
        ? categoriesProvider.incomeCategories
        : categoriesProvider.expenseCategories;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),

            const SizedBox(height: 16),

            _typeSelector(),

            const SizedBox(height: 16),

            _dateTimeRow(),

            _accountCategorySection(ledger, categories),

            const SizedBox(height: 20),

            _notesSection(),

            const SizedBox(height: 16),

            _amountDisplay(),

            const SizedBox(height: 16),

            Expanded(child: _buildKeypad()),
          ],
        ),
      ),
    );
  }

  // ================= TOP BAR =================

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.accent),
            label: const Text(
              "CANCEL",
              style: TextStyle(color: AppTheme.accent),
            ),
          ),

          TextButton.icon(
            onPressed: _saveTransaction,
            icon: const Icon(Icons.check, color: AppTheme.accent),
            label: const Text("SAVE", style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  // ================= TYPE SELECTOR =================

  Widget _typeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _typeButton("INCOME", TransactionType.income),
        _divider(),
        _typeButton("EXPENSE", TransactionType.expense),
        _divider(),
        _typeButton("TRANSFER", TransactionType.transfer),
      ],
    );
  }

  Widget _typeButton(String label, TransactionType t) {
    final selected = type == t;

    return GestureDetector(
      onTap: () {
        setState(() {
          type = t;
          selectedCategory = null;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppTheme.accent : Colors.white54,
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text("|", style: TextStyle(color: Colors.white54)),
  );

  // ================= ACCOUNT + CATEGORY =================

  Widget _accountCategorySection(
    LedgerProvider ledger,
    List<Category> categories,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _selectionBox(
            label: type == TransactionType.transfer
                ? "From Account"
                : "Account",
            value: selectedAccount?.name ?? "Select",
            onTap: () => _selectAccount(ledger, true),
          ),

          const SizedBox(height: 12),

          if (type == TransactionType.transfer)
            _selectionBox(
              label: "To Account",
              value: selectedToAccount?.name ?? "Select",
              onTap: () => _selectAccount(ledger, false),
            ),

          if (type != TransactionType.transfer)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _selectionBox(
                label: "Category",
                value: selectedCategory?.name ?? "Select",
                onTap: () => _selectCategory(categories),
              ),
            ),
        ],
      ),
    );
  }

  Widget _selectionBox({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54)),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  // ================= DATE TIME =================

  Widget _dateTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _pickDate,
            child: Text(
              DateFormat("MMM d, yyyy").format(selectedDateTime),
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 13),
            child: Text("|", style: TextStyle(color: Colors.white54)),
          ),

          GestureDetector(
            onTap: _pickTime,
            child: Text(
              DateFormat("hh:mm a").format(selectedDateTime),
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= NOTES =================

  Widget _notesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _noteController,
        maxLines: 2,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "Add notes",
          hintStyle: TextStyle(color: Colors.white54),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  // ================= AMOUNT =================

  Widget _amountDisplay() {
    return Text(
      "₹${double.parse(amount).toStringAsFixed(2)}",
      style: const TextStyle(
        fontSize: 48,
        color: AppTheme.accent,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ================= KEYPAD =================

  Widget _buildKeypad() {
    final keys = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", ".", "⌫"];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, i) {
        final key = keys[i];

        return GestureDetector(
          onTap: () => _onKeyTap(key),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent),
            ),
            child: Center(
              child: Text(
                key,
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == "⌫") {
        if (amount.length > 1) {
          amount = amount.substring(0, amount.length - 1);
        } else {
          amount = "0";
        }
      } else {
        if (amount == "0") {
          amount = key;
        } else {
          amount += key;
        }
      }
    });
  }

  // ================= PICKERS =================

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          selectedDateTime.hour,
          selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );

    if (time != null) {
      setState(() {
        selectedDateTime = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  // ================= SELECTORS =================

  void _selectAccount(LedgerProvider ledger, bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),

              const Text(
                "Select Account",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 16),

              ...ledger.accounts.map((account) {
                return _selectionTile(
                  title: account.name,
                  icon: Icons.account_balance,
                  onTap: () {
                    setState(() {
                      if (isFrom) {
                        selectedAccount = account;
                      } else {
                        selectedToAccount = account;
                      }
                    });

                    Navigator.pop(context);
                  },
                );
              }),

            ],
          ),
        );
      },
    );
  }

  void _selectCategory(List<Category> categories) {
    final income = categories.where((c) => c.type == "income");

    final expense = categories.where((c) => c.type == "expense");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),

                const Center(
                  child: Text(
                    "Select Category",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (expense.isNotEmpty) ...[
                  _sectionTitle("Expense"),
                  ...expense.map(
                    (c) => _selectionTile(
                      title: c.name,
                      icon: Icons.arrow_upward,
                      color: AppTheme.error,
                      onTap: () {
                        setState(() => selectedCategory = c);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],

                if (income.isNotEmpty) ...[
                  _sectionTitle("Income"),
                  ...income.map(
                    (c) => _selectionTile(
                      title: c.name,
                      icon: Icons.arrow_downward,
                      color: AppTheme.success,
                      onTap: () {
                        setState(() => selectedCategory = c);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _selectionTile({
    required String title,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.accent),
      title: Text(title),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  // ================= SAVE =================

  void _saveTransaction() async {
    final ledger = context.read<LedgerProvider>();
    final amt = double.tryParse(amount) ?? 0;

    if (amt <= 0) return;

    final timestamp = selectedDateTime.millisecondsSinceEpoch;

    /// ================= EDIT MODE =================
    if (isEditMode) {
      final oldTx = widget.transaction!;
      final newTx = TransactionEntity(
        id: oldTx.id,
        type: type.name,
        amount: amt,
        fromAccountId: type == TransactionType.expense
            ? selectedAccount?.id
            : null,
        toAccountId: type == TransactionType.income
            ? selectedAccount?.id
            : null,
        categoryId: selectedCategory?.id,
        note: _noteController.text,
        timestamp: timestamp,
      );

      await ledger.updateTransaction(
        oldTx: oldTx,
        newTx: newTx,
      );

      Navigator.pop(context);
      return;
    }

    /// ================= CREATE MODE =================
    if (type == TransactionType.income) {
      ledger.addIncome(
        amount: amt,
        toAccountId: selectedAccount!.id!,
        categoryId: selectedCategory?.id,
        note: _noteController.text,
      );
    } else if (type == TransactionType.expense) {
      ledger.addExpense(
        amount: amt,
        fromAccountId: selectedAccount!.id!,
        categoryId: selectedCategory?.id,
        note: _noteController.text,
      );
    } else {
      ledger.transferFunds(
        amount: amt,
        fromAccountId: selectedAccount!.id!,
        toAccountId: selectedToAccount!.id!,
        note: _noteController.text,
      );
    }
    Navigator.pop(context);
  }
}
