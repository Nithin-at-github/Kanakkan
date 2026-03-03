import 'package:flutter/material.dart';
import 'package:kanakkan/data/models/transaction_model.dart';
import 'package:kanakkan/data/repositories/account_repository.dart';
import 'package:kanakkan/data/repositories/transaction_repository.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/data/models/account_model.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/providers/category_balance_provider.dart';
import 'package:sqflite/sqflite.dart';

class LedgerProvider extends ChangeNotifier {
  /// dependency that can change over time; the proxy provider will update this
  CategoryBalanceProvider balanceProvider;

  LedgerProvider(this.balanceProvider);

  /// Called by the proxy provider when the balance provider instance changes.
  void updateBalanceProvider(CategoryBalanceProvider newProvider) {
    balanceProvider = newProvider;
  }
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

  /// Build aggregation cache
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
  Future<void> calculateBalances() async {
    for (final account in _accounts) {
      final balanceFromTx = await _transactionRepository.calculateAccountBalance(
        account.id!,
      );

      // include the opening balance stored on the account itself
      _accountBalances[account.id!] = balanceFromTx + account.initialBalance;
    }

    notifyListeners();
  }

  /// ================= ACCOUNTS =================
  Future<void> loadAccounts() async {
    _accounts = await _accountRepository.getAllAccounts();
    notifyListeners();
  }

  Future<void> addAccount(Account account) async {
    final model = AccountModel(
      id: account.id,
      name: account.name,
      initialBalance: account.initialBalance,
    );

    try {
      await _accountRepository.insertAccount(model);
    } on DatabaseException catch (e) {
      // bubble up a friendlier error so the UI can show a message
      if (e.toString().contains('UNIQUE')) {
        throw Exception('An account with this name already exists');
      }
      rethrow;
    }

    await loadAccounts();
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

    await calculateBalances();
    await loadTransactions(type: _currentFilter);
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

    await calculateBalances();
    await loadTransactions(type: _currentFilter);
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
      toAccountId: null,
      categoryId: null,
      note: note ?? "Transfer",
      timestamp: timestamp,
    );

    final credit = TransactionModel(
      type: "income",
      amount: amount,
      fromAccountId: null,
      toAccountId: toAccountId,
      categoryId: null,
      note: note ?? "Transfer",
      timestamp: timestamp,
    );

    await _transactionRepository.insertTransaction(debit);
    await _transactionRepository.insertTransaction(credit);

    await calculateBalances();
    await loadTransactions(type: _currentFilter);
  }

  /// ================= LOAD TRANSACTIONS =================
  Future<void> loadTransactions({String? type}) async {
    _currentFilter = type;

    _transactions = await _transactionRepository.getTransactions(type: type);

    /// rebuild cache automatically
    if (_activeMonth != null && _activeYear != null) {
      rebuildMonthlyTotals(month: _activeMonth!, year: _activeYear!);
    }

    notifyListeners();
  }

  /// ================= DELETE =================
  Future<void> deleteAccount(int accountId) async {
    await _accountRepository.deleteAccount(accountId);

    _accountBalances.remove(accountId);

    await loadAccounts();
    await calculateBalances();
  }

  Future<void> deleteTransaction(int id) async {
    final tx = _transactions.firstWhere((t) => t.id == id);

    /// rollback balance first
    await _applyBalanceEffect(tx, reverse: true);

    await _transactionRepository.deleteTransaction(id);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  /// ================= UPDATE =================
  /// update both name and opening balance
  Future<void> updateAccount(Account updated) async {
    final updatedModel = AccountModel(
      id: updated.id,
      name: updated.name,
      initialBalance: updated.initialBalance,
    );

    try {
      await _accountRepository.updateAccount(updatedModel);
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        throw Exception('An account with this name already exists');
      }
      rethrow;
    }

    await loadAccounts();
    await calculateBalances();
  }

  Future<void> updateTransaction({
    required TransactionEntity oldTx,
    required TransactionEntity newTx,
  }) async {
    /// undo previous balance effect
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

    /// apply new effect
    await _applyBalanceEffect(newTx);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

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
}
