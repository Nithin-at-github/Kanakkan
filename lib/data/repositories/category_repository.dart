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
      excludeFromAnalysis: category.excludeFromAnalysis,
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

  Future<void> updateCategory(int id, String newName, bool excludeFromAnalysis) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      {
        'name': newName,
        'excludeFromAnalysis': excludeFromAnalysis ? 1 : 0,
      },
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

  /// Merges multiple categories into a single new category with a new name.
  /// Moves all transactions, subcategories, and consolidates balances.
  Future<void> mergeCategories(List<int> sourceIds, String newName) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Create the NEW target category
      final newCategoryId = await txn.insert('categories', {
        'name': newName,
        'isSalaryWallet': 0,
        'excludeFromAnalysis': 0,
      });

      // 2. Initialise balance for the new category
      await txn.insert('category_balances', {
        'categoryId': newCategoryId,
        'balance': 0.0,
      });

      // 3. Move everything from sources to the NEW category
      for (final sourceId in sourceIds) {
        await _migrateData(txn, sourceId, newCategoryId);
      }
    });
  }

  /// Merges all data from a source category into an EXISTING target category,
  /// then deletes the source.
  Future<void> mergeInto(int sourceId, int targetId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await _migrateData(txn, sourceId, targetId);
    });
  }

  /// Internal helper to move transactions, subcategories, and balances
  /// from one category to another within a transaction.
  Future<void> _migrateData(Transaction txn, int sourceId, int targetId) async {
    // 1. Inherit salary wallet status if source was the salary wallet
    final List<Map<String, dynamic>> sourceCat = await txn.query(
      'categories',
      columns: ['isSalaryWallet'],
      where: 'id = ?',
      whereArgs: [sourceId],
    );

    if (sourceCat.isNotEmpty && sourceCat.first['isSalaryWallet'] == 1) {
      await txn.update(
        'categories',
        {'isSalaryWallet': 1},
        where: 'id = ?',
        whereArgs: [targetId],
      );
    }

    // 2. Move transactions
    await txn.update(
      'transactions',
      {'categoryId': targetId},
      where: 'categoryId = ?',
      whereArgs: [sourceId],
    );

    // 3. Move subcategories
    await txn.update(
      'categories',
      {'parentId': targetId},
      where: 'parentId = ?',
      whereArgs: [sourceId],
    );

    // 4. Consolidate balances
    final List<Map<String, dynamic>> sourceBal = await txn.query(
      'category_balances',
      columns: ['balance'],
      where: 'categoryId = ?',
      whereArgs: [sourceId],
    );

    if (sourceBal.isNotEmpty) {
      final double sBalance = (sourceBal.first['balance'] as num).toDouble();

      final List<Map<String, dynamic>> targetBal = await txn.query(
        'category_balances',
        columns: ['balance'],
        where: 'categoryId = ?',
        whereArgs: [targetId],
      );

      if (targetBal.isNotEmpty) {
        final double tBalance = (targetBal.first['balance'] as num).toDouble();
        await txn.update(
          'category_balances',
          {'balance': tBalance + sBalance},
          where: 'categoryId = ?',
          whereArgs: [targetId],
        );
      } else {
        await txn.insert('category_balances', {
          'categoryId': targetId,
          'balance': sBalance,
        });
      }
    }

    // 5. Delete associated data and the source category
    await txn.delete(
      'category_balances',
      where: 'categoryId = ?',
      whereArgs: [sourceId],
    );
    await txn.delete(
      'salary_allocation_templates',
      where: 'categoryId = ?',
      whereArgs: [sourceId],
    );
    await txn.delete('categories', where: 'id = ?', whereArgs: [sourceId]);
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
