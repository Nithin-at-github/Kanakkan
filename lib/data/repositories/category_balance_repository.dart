import 'package:kanakkan/core/database/database_helper.dart';

class CategoryBalanceRepository {
  final dbHelper = DatabaseHelper.instance;

  /// get balance
  Future<double> getBalance(int categoryId) async {
    final db = await dbHelper.database;

    final result = await db.query(
      "category_balances",
      where: "categoryId=?",
      whereArgs: [categoryId],
    );

    if (result.isEmpty) return 0;

    return result.first["balance"] as double;
  }

  /// increase balance (allocation)
  Future<void> addToBalance(int categoryId, double amount) async {
    final db = await dbHelper.database;

    await db.rawInsert(
      '''
      INSERT INTO category_balances(categoryId, balance)
      VALUES(?, ?)
      ON CONFLICT(categoryId)
      DO UPDATE SET balance = balance + excluded.balance
    ''',
      [categoryId, amount],
    );
  }

  /// decrease balance (spending)
  Future<void> subtractFromBalance(int categoryId, double amount) async {
    final db = await dbHelper.database;

    await db.rawUpdate(
      '''
      UPDATE category_balances
      SET balance = balance - ?
      WHERE categoryId = ?
      ''',
      [amount, categoryId],
    );
  }
}
