import 'package:kanakkan/data/database/database_helper.dart';
import 'package:kanakkan/data/models/category_model.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:sqflite/sqflite.dart';

class CategoryRepository {
  // use the named constructor (e.g. singleton) provided by DatabaseHelper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert Category
  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;

    final model = CategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
    );

    final id = await db.insert(
      "categories",
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return id;
  }

  /// Get All Categories
  Future<List<Category>> getAllCategories() async {
    final db = await _dbHelper.database;

    final result = await db.query("categories");

    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  /// Update Category Name
  Future<void> updateCategory(int id, String newName) async {
    final db = await _dbHelper.database;

    await db.update(
      "categories",
      {"name": newName},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  /// Delete Category
  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;

    await db.delete("categories", where: "id = ?", whereArgs: [id]);
  }
}
