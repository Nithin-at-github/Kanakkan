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
      parentId: category.parentId,
      linkedAccountId: category.linkedAccountId,
    );
    return db.insert(
      'categories',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;
    final result = await db.query('categories');
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<void> updateCategory(int id, String newName) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Updates the linked account for a category.
  /// Pass null to clear the link.
  Future<void> updateLinkedAccount(int categoryId, int? accountId) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {'linkedAccountId': accountId},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Clear references in transactions (SET NULL)
      // This ensures we don't violate FK constraints if they exist,
      // and keeps the transaction history intact.
      await txn.update(
        'transactions',
        {'categoryId': null},
        where: 'categoryId = ?',
        whereArgs: [id],
      );

      // 2. Delete from category_balances
      await txn.delete(
        'category_balances',
        where: 'categoryId = ?',
        whereArgs: [id],
      );

      // 3. Delete from salary_allocation_templates
      await txn.delete(
        'salary_allocation_templates',
        where: 'categoryId = ?',
        whereArgs: [id],
      );

      // 4. Finally delete the category itself
      // (Cascades to subcategories and budgets via DB-level CASCADE)
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Designates a single category as the salary wallet.
  /// Clears the flag on all others in a single atomic transaction.
  Future<void> setSalaryWallet(int categoryId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('categories', {'isSalaryWallet': 0});
      await txn.update(
        'categories',
        {'isSalaryWallet': 1},
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }

  /// Clears the salary wallet designation entirely.
  Future<void> clearSalaryWallet() async {
    final db = await _dbHelper.database;
    await db.update('categories', {'isSalaryWallet': 0});
  }
}
