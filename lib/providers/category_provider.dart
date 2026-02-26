import 'package:flutter/material.dart';
import 'package:kanakkan/data/repositories/category_repository.dart';
import 'package:kanakkan/domain/entities/category.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == "income").toList();

  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == "expense").toList();

  Future<void> loadCategories() async {
    _categories = await _repository.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _repository.insertCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }

  Future<void> updateCategory(int id, String newName) async {
    await _repository.updateCategory(id, newName);
    await loadCategories();
  }
}
