import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/dialogs/quick_add_dialogs.dart';
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
  final TransactionEntity? pairedTransaction;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.pairedTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;

  final List<FocusNode> _amountFocusNodes = [];
  final List<FocusNode> _noteFocusNodes = [];

  final ValueNotifier<String> _amountNotifier = ValueNotifier("0");
  final ValueNotifier<bool> _multiModeNotifier = ValueNotifier(false);

  Account? _selectedAccount;
  Account? _selectedToAccount;
  Category? _selectedCategory;
  Category? _selectedSubcategory; // optional, drives category auto-select

  double _cachedTotalAmount = 0;
  DateTime _selectedDateTime = DateTime.now();

  final TextEditingController _noteController = TextEditingController();
  final List<BulkTransactionItem> _items = [BulkTransactionItem()];

  bool get _isEditMode => widget.transaction != null;
  bool get _isTransferEdit => _isEditMode && widget.pairedTransaction != null;

  @override
  void initState() {
    super.initState();

    _amountFocusNodes.add(FocusNode());
    _noteFocusNodes.add(FocusNode());

    final tx = widget.transaction;
    if (tx != null) {
      _amountNotifier.value = tx.amount.toString();
      _selectedDateTime = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      _noteController.text = tx.note ?? "";

      if (_isTransferEdit) {
        _type = TransactionType.transfer;
      } else {
        _type = tx.type == "income"
            ? TransactionType.income
            : TransactionType.expense;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ledger = context.read<LedgerProvider>();
        final categories = context.read<CategoryProvider>();

        setState(() {
          if (_isTransferEdit) {
            final paired = widget.pairedTransaction!;
            final expenseLeg = tx.type == "expense" ? tx : paired;
            final incomeLeg = tx.type == "income" ? tx : paired;
            _selectedAccount = ledger.resolveAccount(expenseLeg.fromAccountId);
            _selectedToAccount = ledger.resolveAccount(incomeLeg.toAccountId);
            _selectedCategory = null;
          } else {
            _selectedAccount = ledger.resolveAccount(
              tx.type == "income" ? tx.toAccountId : tx.fromAccountId,
            );
            final resolvedCat = categories.resolveCategory(tx.categoryId);
            if (resolvedCat != null && resolvedCat.isSubcategory) {
              _selectedSubcategory = resolvedCat;
              _selectedCategory = categories.resolveMainCategory(tx.categoryId);
            } else {
              _selectedCategory = resolvedCat;
              _selectedSubcategory = null;
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    for (final node in _amountFocusNodes) { node.dispose(); }
    for (final node in _noteFocusNodes) { node.dispose(); }
    _noteController.dispose();
    _amountNotifier.dispose();
    _multiModeNotifier.dispose();
    super.dispose();
  }

  // ================= CACHED TOTAL =================

  void _recomputeTotal() {
    _cachedTotalAmount = _items.fold(0, (sum, e) => sum + e.amount);
  }

  // ================= KEYPAD =================

  void _onKeyTap(String key) {
    final current = _amountNotifier.value;
    if (key == "⌫") {
      _amountNotifier.value = current.length > 1
          ? current.substring(0, current.length - 1)
          : "0";
    } else {
      _amountNotifier.value = current == "0" ? key : current + key;
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final categoriesProvider = context.watch<CategoryProvider>();
    final categories = categoriesProvider.mainCategories;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _multiModeNotifier,
          builder: (context, multiMode, _) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        if (!multiMode)
                          TransactionTopBar(
                            onCancel: () => Navigator.pop(context),
                            onSave: _saveTransaction,
                          )
                        else
                          const SizedBox(height: 45),

                        if (!_isEditMode) _modeSelector(multiMode),

                        const SizedBox(height: 10),

                        TransactionTypeSelector(
                          type: _type,
                          multiMode: multiMode,
                          onTypeChanged: _isTransferEdit
                              ? null
                              : (t) {
                                  setState(() {
                                    _type = t;
                                    _selectedCategory = null;
                                    _selectedSubcategory = null;
                                  });
                                },
                        ),

                        const SizedBox(height: 10),

                        _dateTimeRow(),

                        AccountCategorySection(
                          type: _type,
                          selectedAccount: _selectedAccount,
                          selectedToAccount: _selectedToAccount,
                          selectedCategory: _selectedCategory,
                          selectedSubcategory: _selectedSubcategory,
                          onSelectAccount: () => _selectAccount(
                            context.read<LedgerProvider>(),
                            true,
                          ),
                          onSelectToAccount: () => _selectAccount(
                            context.read<LedgerProvider>(),
                            false,
                          ),
                          onSelectSubcategory: () =>
                              _selectSubcategory(categoriesProvider),
                          onSelectCategory: () => _selectCategory(categories),
                        ),

                        const SizedBox(height: 15),

                        if (multiMode)
                          BulkEntryList(
                            items: _items,
                            amountFocusNodes: _amountFocusNodes,
                            noteFocusNodes: _noteFocusNodes,
                            total: _cachedTotalAmount,
                            onAmountChanged: (index, value) {
                              _items[index].amount =
                                  double.tryParse(value) ?? 0;
                              _ensureExtraRow(index);
                              setState(_recomputeTotal);
                            },
                            onNoteChanged: (index, value) {
                              _items[index].note = value;
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

                        if (!multiMode) ...[
                          _notesSection(),
                          const SizedBox(height: 12),
                          ValueListenableBuilder<String>(
                            valueListenable: _amountNotifier,
                            builder: (_, amount, _) =>
                                _AmountDisplay(amount: amount),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (!multiMode)
                  SizedBox(
                    height: 285,
                    child: TransactionKeypad(onKeyTap: _onKeyTap),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= MODE SELECTOR =================

  Widget _modeSelector(bool multiMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeChip(
          label: "Single Entry",
          selected: !multiMode,
          onSelected: () => _multiModeNotifier.value = false,
        ),
        const SizedBox(width: 10),
        _buildModeChip(
          label: "Multiple Entry",
          selected: multiMode,
          onSelected: () => _multiModeNotifier.value = true,
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
        decoration: InputDecoration(
          hintText: "Add notes",
          hintStyle: const TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.accent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
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
    if (_selectedAccount == null) {
      _showSnackbar("Please select an account", isError: true);
      return;
    }
    if (_type != TransactionType.transfer && _selectedCategory == null) {
      _showSnackbar("Please select a category", isError: true);
      return;
    }
    final validItems = _items.where((item) => item.amount > 0).toList();
    if (validItems.isEmpty) {
      _showSnackbar("Enter at least one amount", isError: true);
      return;
    }

    // Capture before first await — provider notifyListeners() mid-save
    // rebuilds the tree and can invalidate context-dependent calls
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ledger = context.read<LedgerProvider>();

    // ── WALLET SUFFICIENCY CHECK FOR BULK ──
    // Check total of all bulk items against combined wallet balance.
    if (_type == TransactionType.expense && _selectedCategory != null) {
      final totalRequired = validItems.fold(0.0, (s, i) => s + i.amount);
      final canAfford = ledger.canAffordExpense(
        categoryId: _selectedCategory!.id!,
        amount: totalRequired,
      );
      if (!canAfford) {
        _showSnackbar(
          "Insufficient wallet balance for total of ₹${formatAmt(totalRequired)}.",
          isError: true,
        );
        return;
      }
    }

    // Use batch methods to insert all items and reload exactly once,
    // instead of N individual addExpense/addIncome calls (each of which
    // triggers _reloadAll + notifyListeners).
    if (_type == TransactionType.expense) {
      await ledger.addExpensesBatch(
        validItems
            .map(
              (item) => (
                amount: item.amount,
                fromAccountId: _selectedAccount!.id!,
                categoryId: _selectedCategory!.id! as int?,
                note: item.note as String?,
                timestamp: _selectedDateTime.millisecondsSinceEpoch as int?,
              ),
            )
            .toList(),
      );
    } else {
      await ledger.addIncomesBatch(
        validItems
            .map(
              (item) => (
                amount: item.amount,
                toAccountId: _selectedAccount!.id!,
                categoryId: _selectedCategory!.id! as int?,
                note: item.note as String?,
                timestamp: _selectedDateTime.millisecondsSinceEpoch as int?,
              ),
            )
            .toList(),
      );
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "${validItems.length} transaction${validItems.length > 1 ? 's' : ''} saved",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    navigator.pop();
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= SAVE SINGLE =================

  Future<void> _saveTransaction() async {
    final amt = double.tryParse(_amountNotifier.value) ?? 0;

    if (amt <= 0) {
      _showSnackbar("Enter a valid amount", isError: true);
      return;
    }
    if (_selectedAccount == null) {
      _showSnackbar("Please select an account", isError: true);
      return;
    }
    if (_type == TransactionType.transfer && _selectedToAccount == null) {
      _showSnackbar("Please select a destination account", isError: true);
      return;
    }
    if (_type == TransactionType.transfer &&
        _selectedAccount!.id == _selectedToAccount!.id) {
      _showSnackbar("From and To accounts must be different", isError: true);
      return;
    }
    if (_type != TransactionType.transfer && _selectedCategory == null) {
      _showSnackbar("Please select a category", isError: true);
      return;
    }

    // Capture navigator BEFORE the first await.
    // LedgerProvider calls notifyListeners() inside addExpense/addIncome/
    // transferFunds which triggers a Provider rebuild mid-save. That rebuild
    // can deactivate this widget, making Navigator.of(context) unreliable
    // after the await gap — even when mounted is still true.
    final navigator = Navigator.of(context);
    final ledger = context.read<LedgerProvider>();

    // ── WALLET SUFFICIENCY CHECK ──
    // For expenses, verify that category wallet + salary wallet can cover
    // the amount before proceeding. This prevents negative wallet balances.
    if (!_isEditMode &&
        _type == TransactionType.expense &&
        _selectedCategory != null) {
      final canAfford = ledger.canAffordExpense(
        categoryId: _selectedCategory!.id!,
        amount: amt,
      );
      if (!canAfford) {
        _showSnackbar(
          "Insufficient wallet balance. Top up your wallet or salary first.",
          isError: true,
        );
        return;
      }
    }

    if (_isEditMode) {
      if (_isTransferEdit) {
        final tx = widget.transaction!;
        final paired = widget.pairedTransaction!;
        final expenseLeg = tx.type == "expense" ? tx : paired;
        final incomeLeg = tx.type == "income" ? tx : paired;
        await ledger.updateTransfer(
          oldExpense: expenseLeg,
          oldIncome: incomeLeg,
          amount: amt,
          fromAccountId: _selectedAccount!.id!,
          toAccountId: _selectedToAccount!.id!,
          timestamp: _selectedDateTime.millisecondsSinceEpoch,
          note: _noteController.text,
        );
      } else {
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
            categoryId: (_selectedSubcategory ?? _selectedCategory)?.id,
            note: _noteController.text,
            timestamp: _selectedDateTime.millisecondsSinceEpoch,
          ),
        );
      }
    } else {
      if (_type == TransactionType.income) {
        await ledger.addIncome(
          amount: amt,
          toAccountId: _selectedAccount!.id!,
          categoryId: (_selectedSubcategory ?? _selectedCategory)?.id,
          note: _noteController.text,
          timestamp: _selectedDateTime.millisecondsSinceEpoch,
        );
      } else if (_type == TransactionType.expense) {
        await ledger.addExpense(
          amount: amt,
          fromAccountId: _selectedAccount!.id!,
          categoryId: (_selectedSubcategory ?? _selectedCategory)?.id,
          note: _noteController.text,
          timestamp: _selectedDateTime.millisecondsSinceEpoch,
        );
      } else {
        await ledger.transferFunds(
          amount: amt,
          fromAccountId: _selectedAccount!.id!,
          toAccountId: _selectedToAccount!.id!,
          note: _noteController.text,
          timestamp: _selectedDateTime.millisecondsSinceEpoch,
        );
      }
    }

    // Safe — navigator was captured before any await
    navigator.pop();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Account",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("New"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                        ),
                        onPressed: () async {
                          final created = await QuickAddAccountDialog.show(
                            context,
                          );
                          if (created != null) {
                            setState(() => _selectedAccount = created);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
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

  // ================= CATEGORY SELECT =================

  // ================= SUBCATEGORY SELECT =================

  void _selectSubcategory(CategoryProvider categoriesProvider) {
    // Build grouped list: income or expense subcategories based on current type
    final relevantMains = categoriesProvider.mainCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Subcategory",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("New"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                        ),
                        onPressed: () async {
                          final created = await QuickAddCategoryDialog.show(
                            context,
                          );
                          if (created != null && created.isSubcategory) {
                            if (!context.mounted) return;
                            final provider = context.read<CategoryProvider>();
                            setState(() {
                              _selectedSubcategory = created;
                              _selectedCategory = provider.resolveMainCategory(
                                created.id,
                              );
                            });
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // None option
                        _selectionTile(
                          title: "None",
                          icon: Icons.block,
                          color: Colors.black45,
                          onTap: () {
                            setState(() => _selectedSubcategory = null);
                            Navigator.pop(context);
                          },
                        ),
                        // Grouped by main category
                        ...relevantMains.map((main) {
                          final subs = categoriesProvider.subcategoriesOf(
                            main.id!,
                          );
                          if (subs.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  4,
                                ),
                                child: Text(
                                  main.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              ...subs.map(
                                (sub) => _selectionTile(
                                  title: sub.name,
                                  icon: Icons.subdirectory_arrow_right,
                                  onTap: () {
                                    setState(() {
                                      _selectedSubcategory = sub;
                                      // Auto-set main category from parent
                                      _selectedCategory = categoriesProvider
                                          .resolveMainCategory(sub.id);
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
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
  }

  // ================= CATEGORY SELECT =================

  void _selectCategory(List<Category> categories) {
    final searchController = TextEditingController();
    List<Category> filtered = List.from(categories);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {


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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Select Category",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("New"),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accent,
                            ),
                            onPressed: () async {
                              final created = await QuickAddCategoryDialog.show(
                                context,
                              );
                              if (created != null) {
                                setState(() {
                                  if (created.isSubcategory) {
                                    _selectedSubcategory = created;
                                    _selectedCategory = context
                                        .read<CategoryProvider>()
                                        .resolveMainCategory(created.id);
                                  } else {
                                    _selectedCategory = created;
                                    _selectedSubcategory = null;
                                  }
                                });
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                          ),
                        ],
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
                            if (filtered.isNotEmpty) ...[
                              for (final c in filtered)
                                _selectionTile(
                                  title: c.name,
                                  icon: Icons.label_outline,
                                  color: AppTheme.accent,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = c;

                                      // ── ACCOUNT AUTO-LINK ──
                                      if (c.linkedAccountId != null) {
                                        final ledger =
                                            context.read<LedgerProvider>();
                                        final linkedAcc = ledger
                                            .resolveAccount(c.linkedAccountId);
                                        if (linkedAcc != null) {
                                          if (_type ==
                                              TransactionType.transfer) {
                                            _selectedAccount = linkedAcc;
                                          } else {
                                            _selectedAccount = linkedAcc;
                                          }
                                        }
                                      }

                                      // Clear subcategory if it doesn't belong to new category
                                      if (_selectedSubcategory?.parentId !=
                                          c.id) {
                                        _selectedSubcategory = null;
                                      }
                                    });
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

  // ================= SHARED WIDGETS =================

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


}

// Isolated widget — only rebuilds when ValueNotifier fires
class _AmountDisplay extends StatelessWidget {
  final String amount;

  const _AmountDisplay({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Text(
      "₹${formatAmt(double.parse(amount))}",
      style: const TextStyle(
        fontSize: 48,
        color: AppTheme.accent,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
