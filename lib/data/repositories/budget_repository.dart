import 'package:kanakkan/core/database/database_helper.dart';
import 'package:kanakkan/data/models/budget_model.dart';

class BudgetRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> insertBudget(BudgetModel model) async {
    final db = await dbHelper.database;
    await db.insert("budgets", model.toMap());
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
}
