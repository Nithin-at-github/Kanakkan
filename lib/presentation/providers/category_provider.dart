import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/safe_iterable.dart';
import 'package:kanakkan/data/repositories/category_balance_repository.dart';
import 'package:kanakkan/data/repositories/category_repository.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:sqflite/sqflite.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();
  final CategoryBalanceRepository categoryBalanceRepository =
      CategoryBalanceRepository();

  String? lastError;

  void _setError(String message) {
    lastError = message;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
  }

  String resolveCategoryName(int? categoryId) {
    final category = resolveCategory(categoryId);
    return category?.name ?? "Deleted Category";
  }

  String resolveTransactionCategoryName(TransactionEntity tx) {
    // Transfers don't have categories
    if (tx.type == "transfer") {
      return "Transfer";
    }

    if (tx.categoryId == null) {
      return "Transfer";
    }

    final category = resolveCategory(tx.categoryId);

    return category?.name ?? "Deleted Category";
  }

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == "income").toList();

  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == "expense").toList();
  
  List<Category> get splitCategories =>
    _categories.where((c) => c.name.toLowerCase() != "salary").toList();

  Category? resolveCategory(int? categoryId) {
    if (categoryId == null) return null;

    return categories.firstWhereOrNull((c) => c.id == categoryId);
  }

  int? getSalaryCategoryId() {
    final salaryCategory = categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == "salary",
    );
    return salaryCategory?.id;
  }

  Future<void> initialize() async {
    await loadCategories();
  }

  Future<void> loadCategories() async {
    _categories = await _repository.getAllCategories();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    clearError();

    try {
      final id = await _repository.insertCategory(category);

      await categoryBalanceRepository.setBalance(id, 0);

      await loadCategories();
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _setError('Category already exists');
        return;
      }

      _setError('Failed to create category');
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> deleteCategory(int id) async {
    final balance = await categoryBalanceRepository.getBalance(id);

    if (balance != 0) {
      _setError("Category still has wallet balance");
      return;
    }

    await _repository.deleteCategory(id);
    await loadCategories();
  }

  Future<void> updateCategory(int id, String newName) async {
    clearError();

    try {
      await _repository.updateCategory(id, newName);
      await loadCategories();
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _setError('Category already exists');
        return;
      }

      _setError('Failed to update category');
    } catch (_) {
      _setError('Something went wrong');
    }
  }
}
