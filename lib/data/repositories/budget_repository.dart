import 'package:kanakkan/data/database/database_helper.dart';
import 'package:kanakkan/data/models/budget_model.dart';
import 'package:sqflite/sqflite.dart';

class BudgetRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertBudget(BudgetModel model) async {
    final db = await dbHelper.database;
    await db.insert(
      "budgets",
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBudget(BudgetModel model) async {
    final db = await dbHelper.database;
    await db.update(
      "budgets",
      model.toMap(),
      where: "id = ?",
      whereArgs: [model.id],
    );
  }

  Future<void> deleteBudget(int id) async {
    final db = await dbHelper.database;
    await db.delete("budgets", where: "id = ?", whereArgs: [id]);
  }

  Future<List<BudgetModel>> getBudgets(int month, int year) async {
    final db = await dbHelper.database;

    final result = await db.query(
      "budgets",
      where: "month = ? AND year = ?",
      whereArgs: [month, year],
    );

    return result.map((e) => BudgetModel.fromMap(e)).toList();
  }

  Future<BudgetModel?> getBudgetForCategory(
    int categoryId,
    int month,
    int year,
  ) async {
    final db = await dbHelper.database;

    final result = await db.query(
      "budgets",
      where: "categoryId=? AND month=? AND year=?",
      whereArgs: [categoryId, month, year],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return BudgetModel.fromMap(result.first);
  }

  Future<List<BudgetModel>> getBudgetsForPeriod(int month, int year) async {
    final db = await dbHelper.database;

    final result = await db.query(
      "budgets",
      where: "month = ? AND year = ?",
      whereArgs: [month, year],
      orderBy: "categoryId ASC",
    );

    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }
}
