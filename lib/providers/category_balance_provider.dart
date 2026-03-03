import 'package:flutter/material.dart';
import 'package:kanakkan/data/repositories/category_balance_repository.dart';

class CategoryBalanceProvider extends ChangeNotifier {
  final _repo = CategoryBalanceRepository();

  final Map<int, double> _balances = {};

  double getBalance(int categoryId) {
    return _balances[categoryId] ?? 0;
  }

  /// load one balance
  Future<void> loadBalance(int categoryId) async {
    final balance = await _repo.getBalance(categoryId);
    _balances[categoryId] = balance;
    notifyListeners();
  }

  /// allocate money
  Future<void> allocate(int categoryId, double amount) async {
    await _repo.addToBalance(categoryId, amount);

    _balances[categoryId] = (_balances[categoryId] ?? 0) + amount;

    notifyListeners();
  }

  /// spend money
  Future<void> spend(int categoryId, double amount) async {
    await _repo.subtractFromBalance(categoryId, amount);

    _balances[categoryId] = (_balances[categoryId] ?? 0) - amount;

    notifyListeners();
  }
}
