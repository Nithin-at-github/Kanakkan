import 'package:flutter/material.dart';
import 'package:kanakkan/data/repositories/category_balance_repository.dart';

class CategoryBalanceProvider extends ChangeNotifier {
  final CategoryBalanceRepository _repository = CategoryBalanceRepository();

  final Map<int, double> _balances = {};

  Map<int, double> get balances => _balances;

  /// ================= LOAD =================
  Future<void> loadBalances() async {
    final data = await _repository.getAllBalances();

    _balances.clear();

    for (final item in data) {
      _balances[item.categoryId] = item.balance;
    }

    notifyListeners();
  }

  /// ================= GET =================
  double getBalance(int categoryId) {
    return _balances[categoryId] ?? 0;
  }

  /// ================= SET =================
  Future<void> setBalance(int categoryId, double amount) async {
    _balances[categoryId] = amount;

    notifyListeners();

    await _repository.setBalance(categoryId, amount);
  }

  /// ================= ALLOCATE =================
  Future<void> allocate(int categoryId, double amount) async {
    final current = _balances[categoryId] ?? 0;

    final updated = current + amount;

    _balances[categoryId] = updated;

    notifyListeners();

    await _repository.addToBalance(categoryId, amount);
  }

  /// ================= SPEND =================
  Future<void> spend(int categoryId, double amount) async {
    final current = _balances[categoryId] ?? 0;

    final updated = current - amount;

    _balances[categoryId] = updated;

    notifyListeners();

    await _repository.subtractFromBalance(categoryId, amount);
  }

  /// ================= RESET =================
  Future<void> resetBalance(int categoryId) async {
    _balances[categoryId] = 0;

    notifyListeners();

    await _repository.setBalance(categoryId, 0);
  }

  /// ================= MOVE =================
  Future<void> moveBalance({
    required int fromCategoryId,
    required int toCategoryId,
    required double amount,
  }) async {
    if (fromCategoryId == toCategoryId) {
      throw Exception("Cannot move to same wallet");
    }

    final fromBalance = await _repository.getBalance(fromCategoryId);

    if (fromBalance < amount) {
      throw Exception("Insufficient wallet balance");
    }

    final db = await _repository.dbHelper.database;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        '''
      UPDATE category_balances
      SET balance = balance - ?
      WHERE categoryId = ?
      ''',
        [amount, fromCategoryId],
      );

      await txn.rawInsert(
        '''
      INSERT INTO category_balances(categoryId, balance)
      VALUES(?, ?)
      ON CONFLICT(categoryId)
      DO UPDATE SET balance = balance + excluded.balance
      ''',
        [toCategoryId, amount],
      );
    });

    await loadBalances();
  }
}
