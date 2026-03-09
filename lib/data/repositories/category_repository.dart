import 'package:kanakkan/data/database/database_helper.dart';
import 'package:kanakkan/data/models/category_model.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    final model = CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
      parentId: category.parentId,
    );
    return db.insert(
      "categories",
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    await _ensureSalaryWalletColumn(db);
    final result = await db.query("categories");
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> updateCategory(int id, String newName) async {
    final db = await _dbHelper.database;
    await db.update(
      "categories",
      {"name": newName},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.delete("categories", where: "id = ?", whereArgs: [id]);
  }

  /// Ensures the isSalaryWallet column exists — safe to call on any DB version.
  Future<void> _ensureSalaryWalletColumn(Database db) async {
    try {
      await db.rawQuery('SELECT isSalaryWallet FROM categories LIMIT 1');
    } catch (_) {
      // Column missing — add it now (handles devices that skipped migration)
      await db.execute(
        'ALTER TABLE categories ADD COLUMN isSalaryWallet INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  /// Designates a single category as the salary wallet.
  /// Clears the flag on all others in a single atomic transaction.
  Future<void> setSalaryWallet(int categoryId) async {
    final db = await _dbHelper.database;
    await _ensureSalaryWalletColumn(db);
    await db.transaction((txn) async {
      await txn.update("categories", {"isSalaryWallet": 0});
      await txn.update(
        "categories",
        {"isSalaryWallet": 1},
        where: "id = ?",
        whereArgs: [categoryId],
      );
    });
  }

  /// Clears the salary wallet designation entirely.
  Future<void> clearSalaryWallet() async {
    final db = await _dbHelper.database;
    await _ensureSalaryWalletColumn(db);
    await db.update("categories", {"isSalaryWallet": 0});
  }
}
