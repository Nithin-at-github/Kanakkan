import 'package:flutter/material.dart';
import 'package:kanakkan/data/repositories/category_balance_repository.dart';

class CategoryBalanceProvider extends ChangeNotifier {
  final CategoryBalanceRepository _repository = CategoryBalanceRepository();
  final Map<int, double> _balances = {};
  Map<int, double> get balances => _balances;
  double get totalWalletBalance => _balances.values.fold(0, (sum, b) => sum + b);

  // ================= LOAD =================

  Future<void> loadBalances() async {
    final data = await _repository.getAllBalances();
    _balances.clear();
    for (final item in data) {
      _balances[item.categoryId] = item.balance;
    }
    notifyListeners();
  }

  // ================= GET =================

  double getBalance(int categoryId) {
    return _balances[categoryId] ?? 0;
  }

  // ================= SET =================

  Future<void> setBalance(int categoryId, double amount) async {
    _balances[categoryId] = amount;
    await _repository.setBalance(categoryId, amount);
    notifyListeners();
  }

  // ================= ALLOCATE =================

  Future<void> allocate(int categoryId, double amount) async {
    final current = _balances[categoryId] ?? 0;
    _balances[categoryId] = current + amount;
    await _repository.addToBalance(categoryId, amount);
    notifyListeners();
  }

  // ================= SPEND =================

  Future<void> spend(int categoryId, double amount) async {
    final current = _balances[categoryId] ?? 0;
    _balances[categoryId] = current - amount;
    await _repository.subtractFromBalance(categoryId, amount);
    notifyListeners();
  }

  // ================= RESET =================

  Future<void> resetBalance(int categoryId) async {
    _balances[categoryId] = 0;
    await _repository.setBalance(categoryId, 0);
    notifyListeners();
  }

  // ================= MOVE =================

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

    // loadBalances() calls notifyListeners() once after all DB changes settle
    await loadBalances();
  }
}
