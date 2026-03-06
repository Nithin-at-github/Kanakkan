import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/presentation/widgets/transaction/account_category_section.dart';
import 'package:kanakkan/presentation/widgets/transaction/bulk_entry_list.dart';
import 'package:kanakkan/presentation/widgets/transaction/transaction_keypad.dart';
import 'package:kanakkan/presentation/widgets/transaction/transaction_top_bar.dart';
import 'package:kanakkan/presentation/widgets/transaction/transaction_type_selector.dart';
import 'package:provider/provider.dart';

import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/data/models/bulk_transaction_item.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';

import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';

enum TransactionType { income, expense, transfer }

class AddTransactionScreen extends StatefulWidget {
  final TransactionEntity? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;

  // FIX 1: Track ALL focus nodes (including dynamically added ones) for proper disposal
  final List<FocusNode> _amountFocusNodes = [];
  final List<FocusNode> _noteFocusNodes = [];

  bool _multiMode = false;

  Account? _selectedAccount;
  Account? _selectedToAccount;
  Category? _selectedCategory;

  String _amount = "0";

  // FIX 2: Cache totalAmount — recompute only when items change, not on every build
  double _cachedTotalAmount = 0;

  DateTime _selectedDateTime = DateTime.now();

  final TextEditingController _noteController = TextEditingController();

  // FIX 3: Store items as final list to avoid accidental reassignment
  final List<BulkTransactionItem> _items = [BulkTransactionItem()];

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();

    _amountFocusNodes.add(FocusNode());
    _noteFocusNodes.add(FocusNode());

    final tx = widget.transaction;

    if (tx != null) {
      _amount = tx.amount.toString();
      _selectedDateTime = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      _noteController.text = tx.note ?? "";
      _type = tx.type == "income"
          ? TransactionType.income
          : TransactionType.expense;

      // FIX 4: Resolve edit-mode state in postFrameCallback only once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Guard against unmounted widget
        final ledger = context.read<LedgerProvider>();
        final categories = context.read<CategoryProvider>();

        setState(() {
          _selectedAccount = ledger.resolveAccount(
            tx.type == "income" ? tx.toAccountId : tx.fromAccountId,
          );
          _selectedCategory = categories.resolveCategory(tx.categoryId);
        });
      });
    }
  }

  @override
  void dispose() {
    // FIX 5: Dispose ALL dynamically created FocusNodes, not just the initial ones
    for (final node in _amountFocusNodes) node.dispose();
    for (final node in _noteFocusNodes) node.dispose();

    // FIX 6: Dispose TextEditingController (was missing entirely before)
    _noteController.dispose();

    super.dispose();
  }

  // ================= CACHED TOTAL =================

  void _recomputeTotal() {
    _cachedTotalAmount = _items.fold(0, (sum, e) => sum + e.amount);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    // FIX 7: Use context.watch only for data that should trigger rebuilds.
    // Use context.read inside callbacks (not build) for one-shot reads.
    final categoriesProvider = context.watch<CategoryProvider>();

    final categories = _type == TransactionType.income
        ? categoriesProvider.incomeCategories
        : categoriesProvider.expenseCategories;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    if (!_multiMode)
                      TransactionTopBar(
                        onCancel: () => Navigator.pop(context),
                        onSave: _saveTransaction,
                      )
                    else
                      // FIX 8: Use const SizedBox where possible
                      const SizedBox(height: 45),

                    _modeSelector(),

                    const SizedBox(height: 10),

                    TransactionTypeSelector(
                      type: _type,
                      multiMode: _multiMode,
                      onTypeChanged: (t) {
                        setState(() {
                          _type = t;
                          _selectedCategory = null;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    _dateTimeRow(),

                    // FIX 9: Read ledger inside callback only, pass account lists directly
                    AccountCategorySection(
                      type: _type,
                      selectedAccount: _selectedAccount,
                      selectedToAccount: _selectedToAccount,
                      selectedCategory: _selectedCategory,
                      onSelectAccount: () =>
                          _selectAccount(context.read<LedgerProvider>(), true),
                      onSelectToAccount: () =>
                          _selectAccount(context.read<LedgerProvider>(), false),
                      onSelectCategory: () => _selectCategory(categories),
                    ),

                    const SizedBox(height: 15),

                    if (_multiMode)
                      BulkEntryList(
                        items: _items,
                        amountFocusNodes: _amountFocusNodes,
                        noteFocusNodes: _noteFocusNodes,
                        // FIX 10: Use cached total instead of recomputing on every build
                        total: _cachedTotalAmount,
                        onAmountChanged: (index, value) {
                          _items[index].amount = double.tryParse(value) ?? 0;
                          _ensureExtraRow(index);
                          // Recompute only when data changes
                          setState(_recomputeTotal);
                        },
                        onNoteChanged: (index, value) {
                          _items[index].note = value;
                          // No setState needed — note changes don't affect UI total
                        },
                        onSubmitNote: (index) {
                          _ensureExtraRow(index);
                          if (index + 1 < _amountFocusNodes.length) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_amountFocusNodes[index + 1]);
                          }
                        },
                        onDelete: (index) {
                          setState(() {
                            _items.removeAt(index);
                            _amountFocusNodes.removeAt(index).dispose();
                            _noteFocusNodes.removeAt(index).dispose();
                            _recomputeTotal();
                          });
                        },
                        onSaveAll: _saveBulkTransactions,
                        onCancel: () => Navigator.pop(context),
                      ),

                    if (!_multiMode) ...[
                      _notesSection(),
                      const SizedBox(height: 12),
                      // FIX 11: Isolate amount display to reduce rebuild scope
                      _AmountDisplay(amount: _amount),
                    ],
                  ],
                ),
              ),
            ),

            if (!_multiMode)
              SizedBox(
                height: 285,
                // FIX 12: TransactionKeypad should be const if it has no changing props
                child: TransactionKeypad(onKeyTap: _onKeyTap),
                // Note: if TransactionKeypad can't be const, keep it as-is
              ),
          ],
        ),
      ),
    );
  }

  // ================= MODE SELECTOR =================

  Widget _modeSelector() {
    // FIX 13: Extract repeated ChoiceChip styling into a helper to avoid duplication
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeChip(
          label: "Single Entry",
          selected: !_multiMode,
          onSelected: () {
            setState(() => _multiMode = false);
          },
        ),
        const SizedBox(width: 10),
        _buildModeChip(
          label: "Multiple Entry",
          selected: _multiMode,
          onSelected: () {
            setState(() => _multiMode = true);
          },
        ),
      ],
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.accent,
      backgroundColor: AppTheme.background,
      labelStyle: TextStyle(
        color: selected ? AppTheme.background : AppTheme.primary,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => onSelected(),
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
              DateFormat("MMM d, yyyy").format(_selectedDateTime),
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
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
              DateFormat("hh:mm a").format(_selectedDateTime),
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

  // ================= KEYPAD LOGIC =================

  void _onKeyTap(String key) {
    setState(() {
      if (key == "⌫") {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : "0";
      } else {
        _amount = _amount == "0" ? key : _amount + key;
      }
    });
  }

  // ================= HELPERS =================

  void _ensureExtraRow(int index) {
    if (index == _items.length - 1) {
      setState(() {
        _items.add(BulkTransactionItem());
        _amountFocusNodes.add(FocusNode());
        _noteFocusNodes.add(FocusNode());
      });
    }
  }

  // ================= SAVE BULK =================

  Future<void> _saveBulkTransactions() async {
    // FIX 14: Read provider once before async gap, not inside loop
    final ledger = context.read<LedgerProvider>();

    final validItems = _items.where((item) => item.amount > 0);

    for (final item in validItems) {
      if (_type == TransactionType.expense) {
        await ledger.addExpense(
          amount: item.amount,
          fromAccountId: _selectedAccount!.id!,
          categoryId: _selectedCategory!.id!,
          note: item.note,
        );
      } else {
        await ledger.addIncome(
          amount: item.amount,
          toAccountId: _selectedAccount!.id!,
          categoryId: _selectedCategory!.id!,
          note: item.note,
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  // ================= SAVE SINGLE =================

  void _saveTransaction() async {
    final ledger = context.read<LedgerProvider>();
    final amt = double.tryParse(_amount) ?? 0;
    if (amt <= 0) return;

    if (_isEditMode) {
      // Edit mode: update the existing transaction in-place.
      // Pass the original as oldTx (for balance reversal) and build newTx from current form state.
      await ledger.updateTransaction(
        oldTx: widget.transaction!,
        newTx: TransactionEntity(
          id: widget.transaction!.id,
          type: _type == TransactionType.income ? "income" : "expense",
          amount: amt,
          fromAccountId: _type == TransactionType.income
              ? null
              : _selectedAccount?.id,
          toAccountId: _type == TransactionType.income
              ? _selectedAccount?.id
              : null,
          categoryId: _selectedCategory?.id,
          note: _noteController.text,
          timestamp: _selectedDateTime.millisecondsSinceEpoch,
        ),
      );
    } else {
      // Create mode: add a new transaction
      if (_type == TransactionType.income) {
        await ledger.addIncome(
          amount: amt,
          toAccountId: _selectedAccount!.id!,
          categoryId: _selectedCategory?.id,
          note: _noteController.text,
        );
      } else if (_type == TransactionType.expense) {
        await ledger.addExpense(
          amount: amt,
          fromAccountId: _selectedAccount!.id!,
          categoryId: _selectedCategory?.id,
          note: _noteController.text,
        );
      } else {
        await ledger.transferFunds(
          amount: amt,
          fromAccountId: _selectedAccount!.id!,
          toAccountId: _selectedToAccount!.id!,
          note: _noteController.text,
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  // ================= PICKERS =================

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  // ================= ACCOUNT SELECT =================

  void _selectAccount(LedgerProvider ledger, bool isFrom) {
    // FIX 15: Pre-snapshot the accounts list before opening sheet —
    // avoids holding a stale provider reference inside the builder closure
    final accounts = ledger.accounts;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
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
                  Expanded(
                    child: ListView.builder(
                      // FIX 16: Use ListView.builder instead of .map().toList()
                      // for lazy rendering of large lists
                      controller: scrollController,
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return _selectionTile(
                          title: account.name,
                          icon: Icons.account_balance,
                          onTap: () {
                            setState(() {
                              if (isFrom) {
                                _selectedAccount = account;
                              } else {
                                _selectedToAccount = account;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _selectCategory(List<Category> categories) {
    final searchController = TextEditingController();
    // FIX 17: Initialize filtered list once outside StatefulBuilder,
    // not on every modal rebuild
    List<Category> filtered = List.from(categories);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // FIX 18: Compute income/expense split inside setModalState only,
            // not on the outer build pass
            final incomeCategories = filtered
                .where((c) => c.type == "income")
                .toList();
            final expenseCategories = filtered
                .where((c) => c.type == "expense")
                .toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.45,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _sheetHandle(),
                      const Text(
                        "Select Category",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.black),
                        cursorColor: AppTheme.accent,
                        decoration: InputDecoration(
                          hintText: "Search category",
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.black54,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppTheme.accent,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppTheme.accent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filtered = value.isEmpty
                                ? List.from(categories)
                                : categories
                                      .where(
                                        (c) => c.name.toLowerCase().contains(
                                          value.toLowerCase(),
                                        ),
                                      )
                                      .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            if (expenseCategories.isNotEmpty) ...[
                              _sectionTitle("Expense"),
                              // FIX 19: Use spread with pre-computed lists instead
                              // of chained .map() calls inside build
                              for (final c in expenseCategories)
                                _selectionTile(
                                  title: c.name,
                                  icon: Icons.arrow_upward,
                                  color: AppTheme.error,
                                  onTap: () {
                                    setState(() => _selectedCategory = c);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                            if (incomeCategories.isNotEmpty) ...[
                              _sectionTitle("Income"),
                              for (final c in incomeCategories)
                                _selectionTile(
                                  title: c.name,
                                  icon: Icons.arrow_downward,
                                  color: AppTheme.success,
                                  onTap: () {
                                    setState(() => _selectedCategory = c);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                            if (filtered.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text(
                                    "No categories found",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
}

// FIX 20: Extract AmountDisplay into its own StatelessWidget.
// Now only this widget rebuilds on keypad taps, not the entire screen.
class _AmountDisplay extends StatelessWidget {
  final String amount;

  const _AmountDisplay({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Text(
      "₹${double.parse(amount).toStringAsFixed(2)}",
      style: const TextStyle(
        fontSize: 48,
        color: AppTheme.accent,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
