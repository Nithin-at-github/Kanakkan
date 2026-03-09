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
}
