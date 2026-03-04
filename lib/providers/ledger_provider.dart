import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/safe_iterable.dart';
import 'package:kanakkan/data/models/transaction_model.dart';
import 'package:kanakkan/data/repositories/account_repository.dart';
import 'package:kanakkan/data/repositories/transaction_repository.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/data/models/account_model.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/providers/category_balance_provider.dart';
import 'package:sqflite/sqflite.dart';

class LedgerProvider extends ChangeNotifier {
  CategoryBalanceProvider balanceProvider;

  LedgerProvider(this.balanceProvider);

  /// ================= ERROR STATE =================
  String? lastError;

  void _setError(String message) {
    lastError = message;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
  }

  void updateBalanceProvider(CategoryBalanceProvider newProvider) {
    balanceProvider = newProvider;
  }

  /// ================= ACCOUNT RESOLVERS =================

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

  /// ================= REPOSITORIES =================
  final AccountRepository _accountRepository = AccountRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  /// ================= BALANCES =================
  final Map<int, double> _accountBalances = {};
  Map<int, double> get accountBalances => _accountBalances;

  /// ================= ACCOUNTS =================
  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  /// ================= TRANSACTIONS =================
  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> get transactions => _transactions;

  String? _currentFilter;
  String? get currentFilter => _currentFilter;

  /// ================= MONTHLY CACHE =================
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

  /// ================= INITIALIZE =================
  Future<void> initialize() async {
    await loadAccounts();
    await loadTransactions();
    await calculateBalances();
  }

  /// ================= BALANCE CALC =================
  /// Opening balance is now handled via transactions ONLY
  Future<void> calculateBalances() async {
    for (final account in _accounts) {
      final balanceFromTx = await _transactionRepository
          .calculateAccountBalance(account.id!);

      _accountBalances[account.id!] = balanceFromTx;
    }

    notifyListeners();
  }

  /// ================= ACCOUNTS =================
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

      await loadAccounts();
      await loadTransactions(type: _currentFilter);
      await calculateBalances();
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

      await loadAccounts();
      await loadTransactions(type: _currentFilter);
      await calculateBalances();
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

    await loadAccounts();
    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  /// ================= TRANSACTIONS =================

  Future<void> addIncome({
    required double amount,
    required int toAccountId,
    int? categoryId,
    String? note,
  }) async {
    final transaction = TransactionModel(
      type: "income",
      amount: amount,
      fromAccountId: null,
      toAccountId: toAccountId,
      categoryId: categoryId,
      note: note,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _transactionRepository.insertTransaction(transaction);

    await _applyBalanceEffect(transaction);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  Future<void> addExpense({
    required double amount,
    required int fromAccountId,
    int? categoryId,
    String? note,
  }) async {
    final transaction = TransactionModel(
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: null,
      categoryId: categoryId,
      note: note,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _transactionRepository.insertTransaction(transaction);

    await _applyBalanceEffect(transaction);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  Future<void> transferFunds({
    required double amount,
    required int fromAccountId,
    required int toAccountId,
    String? note,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final debit = TransactionModel(
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      categoryId: null,
      note: note ?? "Transfer",
      timestamp: timestamp,
    );

    final credit = TransactionModel(
      type: "income",
      amount: amount,
      toAccountId: toAccountId,
      categoryId: null,
      note: note ?? "Transfer",
      timestamp: timestamp,
    );

    await _transactionRepository.insertTransaction(debit);
    await _transactionRepository.insertTransaction(credit);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  /// ================= LOAD =================
  Future<void> loadTransactions({String? type}) async {
    _currentFilter = type;

    _transactions = await _transactionRepository.getTransactions(type: type);

    if (_activeMonth != null && _activeYear != null) {
      rebuildMonthlyTotals(month: _activeMonth!, year: _activeYear!);
    }

    notifyListeners();
  }

  /// ================= DELETE TRANSACTION =================
  Future<void> deleteTransaction(int id) async {
    final tx = _transactions.firstWhere((t) => t.id == id);

    await _applyBalanceEffect(tx, reverse: true);

    await _transactionRepository.deleteTransaction(id);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  /// ================= UPDATE TRANSACTION =================
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

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  /// ================= ENVELOPE EFFECT =================
  Future<void> _applyBalanceEffect(
    TransactionEntity tx, {
    bool reverse = false,
  }) async {
    if (tx.categoryId == null) return;

    final amount = reverse ? -tx.amount : tx.amount;

    if (tx.type == "expense") {
      await balanceProvider.spend(tx.categoryId!, amount);
    }

    if (tx.type == "income") {
      await balanceProvider.allocate(tx.categoryId!, amount);
    }
  }

  /// ================= OPENING BALANCE =================
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
