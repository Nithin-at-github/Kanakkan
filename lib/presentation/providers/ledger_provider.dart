import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/safe_iterable.dart';
import 'package:kanakkan/data/models/salary_trigger.dart';
import 'package:kanakkan/data/models/transaction_model.dart';
import 'package:kanakkan/data/repositories/account_repository.dart';
import 'package:kanakkan/data/repositories/salary_allocation_repository.dart';
import 'package:kanakkan/data/repositories/transaction_repository.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/data/models/account_model.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

enum TransactionDeleteType { normal, salaryDistributed }

class LedgerProvider extends ChangeNotifier {
  CategoryBalanceProvider balanceProvider;
  CategoryProvider categoryProvider = CategoryProvider();

  /// Trigger for salary income dialog
  final ValueNotifier<SalaryTrigger?> salaryIncomeTrigger = ValueNotifier(null);

  LedgerProvider(this.categoryProvider, this.balanceProvider);

  int? get salaryCategoryId {
    final salary = categoryProvider.categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == "salary",
    );
    return salary?.id;
  }

  final SalaryAllocationRepository _salaryAllocationRepository =
      SalaryAllocationRepository();

  // ================= ERROR STATE =================

  String? lastError;

  void _setError(String message) {
    lastError = message;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
  }

  void updateDependencies(
    CategoryProvider newCategoryProvider,
    CategoryBalanceProvider newBalanceProvider,
  ) {
    categoryProvider = newCategoryProvider;
    balanceProvider = newBalanceProvider;
  }

  void updateBalanceProvider(CategoryBalanceProvider newProvider) {
    balanceProvider = newProvider;
  }

  // ================= ACCOUNT RESOLVERS =================

  String resolveAccountName(int? accountId) {
    if (accountId == null) return "Not Found";
    final account = accounts.firstWhereOrNull((a) => a.id == accountId);
    return account?.name ?? "Deleted Account";
  }

  String resolvePrimaryAccountName(TransactionEntity tx) {
    int? accountId;
    switch (tx.type) {
      case "income":
        accountId = tx.toAccountId;
        break;
      case "expense":
        accountId = tx.fromAccountId;
        break;
      case "transfer":
        accountId = tx.fromAccountId;
        break;
      default:
        return "-";
    }
    return resolveAccountName(accountId);
  }

  Account? resolveAccount(int? accountId) {
    if (accountId == null) return null;
    return accounts.firstWhereOrNull((a) => a.id == accountId);
  }

  SalaryTrigger? consumeSalaryTrigger() {
    final trigger = salaryIncomeTrigger.value;
    salaryIncomeTrigger.value = null;
    return trigger;
  }

  // ================= REPOSITORIES =================

  final AccountRepository _accountRepository = AccountRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  // ================= STATE =================

  final Map<int, double> _accountBalances = {};
  Map<int, double> get accountBalances => _accountBalances;

  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> get transactions => _transactions;

  String? _currentFilter;
  String? get currentFilter => _currentFilter;

  // ================= MONTHLY CACHE =================

  final Map<int, double> _monthlyCategoryTotals = {};
  int? _activeMonth;
  int? _activeYear;

  double getMonthlySpent(int categoryId) {
    return _monthlyCategoryTotals[categoryId] ?? 0.0;
  }

  void rebuildMonthlyTotals({required int month, required int year}) {
    _activeMonth = month;
    _activeYear = year;
    _monthlyCategoryTotals.clear();

    for (final tx in _transactions) {
      if (tx.type != "expense") continue;
      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      if (date.month != month || date.year != year) continue;
      final categoryId = tx.categoryId;
      if (categoryId == null) continue;
      _monthlyCategoryTotals[categoryId] =
          (_monthlyCategoryTotals[categoryId] ?? 0) + tx.amount;
    }
  }

  // ================= INITIALIZE =================

  Future<void> initialize() async {
    await loadAccounts();
    await loadTransactions();
    await calculateBalances();
  }

  // ================= BALANCE CALC =================

  Future<void> calculateBalances() async {
    for (final account in _accounts) {
      _accountBalances[account.id!] = await _transactionRepository
          .calculateAccountBalance(account.id!);
    }
    notifyListeners();
  }

  // ================= ACCOUNTS =================

  Future<void> loadAccounts() async {
    _accounts = await _accountRepository.getAllAccounts();
    notifyListeners();
  }

  Future<void> addAccount(Account account) async {
    clearError();
    final model = AccountModel(
      id: account.id,
      name: account.name,
      initialBalance: account.initialBalance,
    );
    try {
      final insertedId = await _accountRepository.insertAccount(model);
      final createdAccount = account.copyWith(id: insertedId);
      await _createOpeningBalanceTransaction(createdAccount);
      await _reloadAll();
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _setError('An account with this name already exists');
        return;
      }
      _setError('Failed to create account');
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> updateAccount(Account updated) async {
    clearError();
    final updatedModel = AccountModel(
      id: updated.id,
      name: updated.name,
      initialBalance: updated.initialBalance,
    );
    try {
      await _accountRepository.updateAccount(updatedModel);
      await _updateOpeningBalanceTransaction(updated);
      await _reloadAll();
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _setError('An account with this name already exists');
        return;
      }
      _setError('Failed to update account');
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> deleteAccount(int accountId) async {
    await _removeOpeningBalance(accountId);
    await _accountRepository.deleteAccount(accountId);
    _accountBalances.remove(accountId);
    await _reloadAll();
  }

  // ================= TRANSACTIONS =================

  Future<void> addIncome({
    required double amount,
    required int toAccountId,
    int? categoryId,
    String? note,
    int? timestamp,
  }) async {
    final transaction = TransactionModel(
      type: "income",
      amount: amount,
      fromAccountId: null,
      toAccountId: toAccountId,
      categoryId: categoryId,
      note: note,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );

    final id = await _transactionRepository.insertTransaction(transaction);
    await _applyBalanceEffect(transaction);

    // Single reload + single notifyListeners at the end
    await _reloadAll();

    // Fire salary trigger after a microtask delay so AddTransactionScreen
    // has time to pop first. Without this, the dialog opens on top of
    // AddTransactionScreen and navigator.pop() closes the dialog instead
    // of returning to the dashboard.
    if (_isSalaryCategory(categoryId)) {
      Future.microtask(() {
        salaryIncomeTrigger.value = SalaryTrigger(
          transactionId: id,
          amount: amount,
        );
      });
    }
  }

  bool _isSalaryCategory(int? categoryId) {
    if (categoryId == null) return false;
    final category = categoryProvider.resolveCategory(categoryId);
    if (category == null) return false;
    return category.name.toLowerCase() == "salary";
  }

  Future<void> addExpense({
    required double amount,
    required int fromAccountId,
    int? categoryId,
    String? note,
    int? timestamp,
  }) async {
    final transaction = TransactionModel(
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: null,
      categoryId: categoryId,
      note: note,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );

    await _transactionRepository.insertTransaction(transaction);
    await _applyBalanceEffect(transaction);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  Future<void> transferFunds({
    required double amount,
    required int fromAccountId,
    required int toAccountId,
    String? note,
    int? timestamp,
  }) async {
    final groupId = const Uuid().v4();
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final expenseLeg = TransactionModel(
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      timestamp: ts,
      note: note,
      transferGroupId: groupId,
    );

    final incomeLeg = TransactionModel(
      type: "income",
      amount: amount,
      toAccountId: toAccountId,
      timestamp: ts,
      note: note,
      transferGroupId: groupId,
    );

    await _transactionRepository.insertTransaction(expenseLeg);
    await _transactionRepository.insertTransaction(incomeLeg);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  Future<TransactionEntity?> getPairedTransferLeg(TransactionEntity tx) async {
    if (tx.transferGroupId == null) return null;
    final legs = await _transactionRepository.getTransactionsByGroupId(
      tx.transferGroupId!,
    );
    return legs.firstWhereOrNull((leg) => leg.id != tx.id);
  }

  Future<void> updateTransfer({
    required TransactionEntity oldExpense,
    required TransactionEntity oldIncome,
    required double amount,
    required int fromAccountId,
    required int toAccountId,
    required int timestamp,
    String? note,
  }) async {
    await _applyBalanceEffect(oldExpense, reverse: true);
    await _applyBalanceEffect(oldIncome, reverse: true);

    final newExpense = TransactionModel(
      id: oldExpense.id,
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      timestamp: timestamp,
      note: note,
      transferGroupId: oldExpense.transferGroupId,
    );

    final newIncome = TransactionModel(
      id: oldIncome.id,
      type: "income",
      amount: amount,
      toAccountId: toAccountId,
      timestamp: timestamp,
      note: note,
      transferGroupId: oldIncome.transferGroupId,
    );

    await _transactionRepository.updateTransferLegs(
      expenseLeg: newExpense,
      incomeLeg: newIncome,
    );

    await _applyBalanceEffect(newExpense);
    await _applyBalanceEffect(newIncome);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  // ================= LOAD =================

  Future<void> loadTransactions({String? type}) async {
    _currentFilter = type;
    _transactions = await _transactionRepository.getTransactions(type: type);

    if (_activeMonth != null && _activeYear != null) {
      rebuildMonthlyTotals(month: _activeMonth!, year: _activeYear!);
    }

    notifyListeners();
  }

  // ================= DELETE TRANSACTION =================

  Future<void> deleteTransaction(int id) async {
    final tx = _transactions.firstWhereOrNull((t) => t.id == id);

    if (tx?.transferGroupId != null) {
      final legs = await _transactionRepository.getTransactionsByGroupId(
        tx!.transferGroupId!,
      );
      for (final leg in legs) {
        await _applyBalanceEffect(leg, reverse: true);
        await _transactionRepository.deleteTransaction(leg.id!);
      }
    } else {
      if (tx != null) {
        await _applyBalanceEffect(tx, reverse: true);

        // Reverse salary wallet allocations if this was a salary transaction
        if (_isSalaryCategory(tx.categoryId)) {
          final allocations = await _salaryAllocationRepository.getAllocations(
            id,
          );
          for (final alloc in allocations) {
            final categoryId = alloc['categoryId'] as int;
            final amount = (alloc['amount'] as num).toDouble();
            // Reverse: subtract from the target wallet, add back to salary wallet
            await balanceProvider.spend(categoryId, amount);
            await balanceProvider.allocate(tx.categoryId!, amount);
          }
          await _salaryAllocationRepository.deleteAllocations(id);
        }
      }
      await _transactionRepository.deleteTransaction(id);
    }

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  Future<TransactionDeleteType> getDeleteType(TransactionEntity tx) async {
    final salaryId = salaryCategoryId;
    if (salaryId == null || tx.type != "income" || tx.categoryId != salaryId) {
      return TransactionDeleteType.normal;
    }
    final allocations = await _salaryAllocationRepository.getAllocations(
      tx.id!,
    );
    if (allocations.isEmpty) {
      return TransactionDeleteType.normal;
    }
    return TransactionDeleteType.salaryDistributed;
  }

  // ================= UPDATE TRANSACTION =================

  Future<void> updateTransaction({
    required TransactionEntity oldTx,
    required TransactionEntity newTx,
  }) async {
    await _applyBalanceEffect(oldTx, reverse: true);

    final model = TransactionModel(
      id: newTx.id,
      type: newTx.type,
      amount: newTx.amount,
      fromAccountId: newTx.fromAccountId,
      toAccountId: newTx.toAccountId,
      categoryId: newTx.categoryId,
      note: newTx.note,
      timestamp: newTx.timestamp,
    );

    await _transactionRepository.updateTransaction(model);
    await _applyBalanceEffect(newTx);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  // ================= WALLET EFFECT =================

  // ================= WALLET SUFFICIENCY CHECK =================

  /// Returns true if the expense can be covered by category wallet
  /// + salary wallet combined. Used by AddTransactionScreen to gate
  /// the save button before calling addExpense.
  bool canAffordExpense({required int categoryId, required double amount}) {
    if (_isSalaryCategory(categoryId)) {
      // Paying directly into salary wallet — just check salary balance
      return balanceProvider.getBalance(categoryId) >= amount;
    }
    final categoryBalance = balanceProvider.getBalance(categoryId);
    final salaryId = salaryCategoryId;
    final salaryBalance = salaryId != null
        ? balanceProvider.getBalance(salaryId)
        : 0.0;
    return (categoryBalance + salaryBalance) >= amount;
  }

  Future<void> _applyBalanceEffect(
    TransactionEntity tx, {
    bool reverse = false,
  }) async {
    if (tx.categoryId == null) return;
    final amount = reverse ? -tx.amount : tx.amount;

    if (tx.type == "expense") {
      if (reverse) {
        // Reversal: we don't know original split, so reload from DB isn't
        // feasible here. Simplest correct approach: add back to category
        // wallet directly. If salary was used, salary split dialog handles
        // its own reversal. For simple expense reversal, restore to category.
        await balanceProvider.allocate(tx.categoryId!, tx.amount);
      } else {
        await _spendWithSalaryFallback(
          categoryId: tx.categoryId!,
          amount: tx.amount,
        );
      }
    }

    if (tx.type == "income") {
      await balanceProvider.allocate(tx.categoryId!, amount);
    }
  }

  /// Spends from category wallet first. If category wallet runs short,
  /// the remainder is pulled from the salary wallet.
  Future<void> _spendWithSalaryFallback({
    required int categoryId,
    required double amount,
  }) async {
    final categoryBalance = balanceProvider.getBalance(categoryId);

    if (categoryBalance >= amount) {
      // Category wallet has enough — spend entirely from it
      await balanceProvider.spend(categoryId, amount);
      return;
    }

    // Partial: use whatever is in category wallet
    final fromCategory = categoryBalance;
    final fromSalary = amount - fromCategory;

    if (fromCategory > 0) {
      await balanceProvider.spend(categoryId, fromCategory);
    }

    // Pull shortfall from salary wallet
    final salaryId = salaryCategoryId;
    if (salaryId != null && fromSalary > 0) {
      await balanceProvider.spend(salaryId, fromSalary);
    }
  }

  // ================= RELOAD HELPER =================
  //
  // Replaces the pattern of calling loadTransactions() + calculateBalances()
  // separately (which fired notifyListeners twice). Now all state is refreshed
  // in one pass and listeners are notified exactly once at the end.

  Future<void> _reloadAll() async {
    _accounts = await _accountRepository.getAllAccounts();
    _transactions = await _transactionRepository.getTransactions(
      type: _currentFilter,
    );

    if (_activeMonth != null && _activeYear != null) {
      rebuildMonthlyTotals(month: _activeMonth!, year: _activeYear!);
    }

    for (final account in _accounts) {
      _accountBalances[account.id!] = await _transactionRepository
          .calculateAccountBalance(account.id!);
    }

    notifyListeners(); // ← exactly once per operation
  }

  // ================= OPENING BALANCE =================

  Future<void> _createOpeningBalanceTransaction(Account account) async {
    if (account.initialBalance <= 0) return;
    final model = TransactionModel(
      type: "income",
      amount: account.initialBalance,
      fromAccountId: null,
      toAccountId: account.id,
      categoryId: null,
      note: "Opening_Balance",
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _transactionRepository.insertTransaction(model);
  }

  Future<void> _updateOpeningBalanceTransaction(Account account) async {
    final openingTx = _transactions.firstWhereOrNull(
      (tx) => tx.note == "Opening_Balance" && tx.toAccountId == account.id,
    );
    if (openingTx == null) {
      await _createOpeningBalanceTransaction(account);
      return;
    }
    final updatedTx = openingTx.copyWith(amount: account.initialBalance);
    await updateTransaction(oldTx: openingTx, newTx: updatedTx);
  }

  Future<void> _removeOpeningBalance(int accountId) async {
    final openingTx = _transactions.firstWhereOrNull(
      (tx) => tx.note == "Opening_Balance" && tx.toAccountId == accountId,
    );
    if (openingTx != null) {
      await _transactionRepository.deleteTransaction(openingTx.id!);
    }
  }
}
