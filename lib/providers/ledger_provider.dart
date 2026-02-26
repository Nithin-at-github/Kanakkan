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
  final Map<int, double> _accountBalances = {};

  Map<int, double> get accountBalances => _accountBalances;
  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> get transactions => _transactions;

  String? _currentFilter;
  String? get currentFilter => _currentFilter;

  Future<void> calculateBalances() async {
    for (final account in _accounts) {
      final balance = await _transactionRepository.calculateAccountBalance(
        account.id!,
      );

      _accountBalances[account.id!] = balance;
    }

    notifyListeners();
  }

  /// Load accounts from DB
  Future<void> loadAccounts() async {
    _accounts = await _accountRepository.getAllAccounts();
    notifyListeners();
  }

  /// Add new account
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

  /// Add new income transaction
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

    notifyListeners();
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

    notifyListeners();
  }

  Future<void> transferFunds({
    required double amount,
    required int fromAccountId,
    required int toAccountId,
    String? note,
  }) async {
    final transaction = TransactionModel(
      type: "transfer",
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      note: note,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await _transactionRepository.insertTransaction(transaction);
    await calculateBalances();

    notifyListeners();
  }

  Future<void> loadTransactions({String? type}) async {
    _currentFilter = type;
    _transactions = await _transactionRepository.getTransactions(type: type);

    notifyListeners();
  }

  Future<void> deleteAccount(int accountId) async {
    await _accountRepository.deleteAccount(accountId);

    _accountBalances.remove(accountId);

    await loadAccounts();
    await calculateBalances();

    notifyListeners();
  }

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

    notifyListeners();
  }
}
