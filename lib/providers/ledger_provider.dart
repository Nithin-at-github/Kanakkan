import 'package:flutter/material.dart';
import 'package:kanakkan/data/models/transaction_model.dart';
import 'package:kanakkan/data/repositories/account_repository.dart';
import 'package:kanakkan/data/repositories/transaction_repository.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/data/models/account_model.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';

class LedgerProvider extends ChangeNotifier {
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
      final balance = await _transactionRepository.calculateAccountBalance(
        account.id!,
      );

      _accountBalances[account.id!] = balance;
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
      entityType: account.entityType,
      mediumType: account.mediumType,
    );

    await _accountRepository.insertAccount(model);

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
    await _transactionRepository.deleteTransaction(id);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }

  /// ================= UPDATE =================
  Future<void> updateAccountName(int accountId, String newName) async {
    final account = _accounts.firstWhere((a) => a.id == accountId);

    final updatedModel = AccountModel(
      id: account.id,
      name: newName,
      entityType: account.entityType,
      mediumType: account.mediumType,
    );

    await _accountRepository.updateAccount(updatedModel);

    await loadAccounts();
  }

  Future<void> updateTransaction({
    required int id,
    required String type,
    required double amount,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    String? note,
    required int timestamp,
  }) async {
    final model = TransactionModel(
      id: id,
      type: type,
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      note: note,
      timestamp: timestamp,
    );

    await _transactionRepository.updateTransaction(model);

    await loadTransactions(type: _currentFilter);
    await calculateBalances();
  }
}
