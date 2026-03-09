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

  // ================= RESOLVERS =================

  String resolveCategoryName(int? categoryId) {
    final category = resolveCategory(categoryId);
    return category?.name ?? "Deleted Category";
  }

  String resolveTransactionCategoryName(TransactionEntity tx) {
    if (tx.transferGroupId != null) return "Transfer";
    if (tx.categoryId == null) {
      if (tx.type == "income") return "Income";
      if (tx.type == "expense") return "Expense";
      return "Transaction";
    }
    final category = resolveCategory(tx.categoryId);
    return category?.name ?? "Deleted Category";
  }

  Category? resolveCategory(int? categoryId) {
    if (categoryId == null) return null;
    return _categories.firstWhereOrNull((c) => c.id == categoryId);
  }

  /// Returns the main (parent) category for a given category id.
  /// If categoryId is already a main category, returns it directly.
  Category? resolveMainCategory(int? categoryId) {
    final cat = resolveCategory(categoryId);
    if (cat == null) return null;
    if (cat.isMainCategory) return cat;
    return resolveCategory(cat.parentId);
  }

  /// The category designated as the salary wallet, or null if none set.
  Category? get salaryWalletCategory =>
      _categories.firstWhereOrNull((c) => c.isSalaryWallet);

  int? getSalaryCategoryId() => salaryWalletCategory?.id;

  bool get hasSalaryWallet => salaryWalletCategory != null;

  // ================= STATE =================

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  /// Top-level categories only (no subcategories)
  List<Category> get mainCategories =>
      _categories.where((c) => c.isMainCategory).toList();

  List<Category> get incomeCategories =>
      mainCategories.where((c) => c.type == "income").toList();

  List<Category> get expenseCategories =>
      mainCategories.where((c) => c.type == "expense").toList();

  /// Subcategories belonging to a specific parent
  List<Category> subcategoriesOf(int parentId) =>
      _categories.where((c) => c.parentId == parentId).toList();

  /// All subcategories across all parents, grouped by parent id.
  /// Used by the transaction screen grouped picker.
  Map<Category, List<Category>> get groupedSubcategories {
    final Map<Category, List<Category>> result = {};
    for (final main in mainCategories) {
      final subs = subcategoriesOf(main.id!);
      if (subs.isNotEmpty) result[main] = subs;
    }
    return result;
  }

  /// Flat list of all subcategories — income + expense combined.
  List<Category> get allSubcategories =>
      _categories.where((c) => c.isSubcategory).toList();

  /// Income subcategories only
  List<Category> get incomeSubcategories =>
      allSubcategories.where((c) => c.type == "income").toList();

  /// Expense subcategories only
  List<Category> get expenseSubcategories =>
      allSubcategories.where((c) => c.type == "expense").toList();

  /// Income main categories available for salary split
  /// (excludes the salary wallet itself — it's the source, not a target)
  List<Category> get splitCategories => mainCategories
      .where(
        (c) => c.type == "expense" || (c.type == "income" && !c.isSalaryWallet),
      )
      .toList();

  // ================= INIT =================

  Future<void> initialize() async {
    await loadCategories();
  }

  Future<void> loadCategories() async {
    _categories = await _repository.getAllCategories();
    notifyListeners();
  }

  // ================= CRUD =================

  Future<void> addCategory(Category category) async {
    clearError();
    try {
      final id = await _repository.insertCategory(category);
      // Only main categories get a wallet balance entry
      if (category.isMainCategory) {
        await categoryBalanceRepository.setBalance(id, 0);
      }
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

  Future<void> addSubcategory({
    required String name,
    required int parentId,
  }) async {
    clearError();
    final parent = resolveCategory(parentId);
    if (parent == null) {
      _setError('Parent category not found');
      return;
    }
    final subcategory = Category(
      name: name,
      type: parent.type, // inherits type from parent
      parentId: parentId,
    );
    await addCategory(subcategory);
  }

  Future<void> setSalaryWallet(int categoryId) async {
    clearError();
    final category = resolveCategory(categoryId);
    if (category == null || category.type != "income") {
      _setError("Only income categories can be the salary wallet");
      return;
    }
    await _repository.setSalaryWallet(categoryId);
    await loadCategories();
  }

  Future<void> clearSalaryWallet() async {
    await _repository.clearSalaryWallet();
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    clearError();
    final category = resolveCategory(id);
    if (category == null) return;

    // For main categories, check wallet balance
    if (category.isMainCategory) {
      final balance = await categoryBalanceRepository.getBalance(id);
      if (balance != 0) {
        _setError("Category still has wallet balance");
        return;
      }
    }

    // Subcategories are deleted via CASCADE in DB,
    // but we delete explicitly here for clarity
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
