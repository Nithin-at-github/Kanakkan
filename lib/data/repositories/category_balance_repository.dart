import 'package:kanakkan/data/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_balance_model.dart';

class CategoryBalanceRepository {
  final dbHelper = DatabaseHelper.instance;

  /// ================= LOAD ALL =================
  Future<List<CategoryBalanceModel>> getAllBalances() async {
    final db = await dbHelper.database;

    final result = await db.query("category_balances");

    return result.map((e) => CategoryBalanceModel.fromMap(e)).toList();
  }

  /// ================= GET ONE =================
  Future<double> getBalance(int categoryId) async {
    final db = await dbHelper.database;

    final result = await db.query(
      "category_balances",
      where: "categoryId = ?",
      whereArgs: [categoryId],
    );

    if (result.isEmpty) return 0;

    return (result.first["balance"] as num).toDouble();
  }

  /// ================= ALLOCATE =================
  Future<void> addToBalance(int categoryId, double amount) async {
    final db = await dbHelper.database;

    await db.rawInsert(
      '''
INSERT INTO category_balances(categoryId, balance)
VALUES(?, ?)
ON CONFLICT(categoryId)
DO UPDATE SET balance = balance + ?
''',
      [categoryId, amount, amount],
    );
  }

  /// ================= SPEND =================
  Future<void> subtractFromBalance(int categoryId, double amount) async {
    final db = await dbHelper.database;

    await db.rawInsert(
      '''
INSERT INTO category_balances(categoryId, balance)
VALUES(?, ?)
ON CONFLICT(categoryId)
DO UPDATE SET balance = balance - ?
''',
      [categoryId, -amount, amount],
    );
  }

  /// ================= SET =================
  Future<void> setBalance(int categoryId, double balance) async {
    final db = await dbHelper.database;

    await db.insert("category_balances", {
      "categoryId": categoryId,
      "balance": balance,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
