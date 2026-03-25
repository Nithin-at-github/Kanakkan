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
    return category?.name ?? 'Deleted Category';
  }

  String resolveTransactionCategoryName(TransactionEntity tx) {
    if (tx.transferGroupId != null) return 'Transfer';
    if (tx.categoryId == null) {
      if (tx.type == 'income') return 'Income';
      if (tx.type == 'expense') return 'Expense';
      return 'Transaction';
    }
    final category = resolveCategory(tx.categoryId);
    if (category == null) return 'Deleted Category';

    // If it's a subcategory, show "Parent - Sub" for better context in lists
    if (category.isSubcategory) {
      final parent = resolveCategory(category.parentId);
      if (parent != null) {
        return '${parent.name} - ${category.name}';
      }
    }

    return category.name;
  }

  /// O(1) Map lookup — replaces the previous O(N) firstWhereOrNull scan.
  Category? resolveCategory(int? categoryId) {
    if (categoryId == null) return null;
    return _categoryMap[categoryId];
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
  Category? get salaryWalletCategory => _salaryWalletCategory;

  int? getSalaryCategoryId() => _salaryWalletCategory?.id;

  bool get hasSalaryWallet => _salaryWalletCategory != null;

  // ================= STATE =================

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  // ── CACHED DERIVED LISTS — rebuilt once in _rebuildCache ──
  Map<int, Category> _categoryMap = {};
  Category? _salaryWalletCategory;

  List<Category> _mainCategories = [];
  List<Category> _allSubcategories = [];
  List<Category> _splitCategories = [];
  Map<int, List<Category>> _subcategoryMap = {}; // parentId → subs

  /// Top-level categories only (no subcategories).
  List<Category> get mainCategories => _mainCategories;

  /// All main categories eligible as salary split targets.
  /// Excludes the salary wallet itself — it's the source, not a target.
  List<Category> get splitCategories => _splitCategories;

  /// Subcategories belonging to a specific parent — O(1) map lookup.
  List<Category> subcategoriesOf(int parentId) =>
      _subcategoryMap[parentId] ?? const [];

  /// All subcategories across all parents, grouped by parent id.
  /// Used by the transaction screen grouped picker.
  Map<Category, List<Category>> get groupedSubcategories {
    final Map<Category, List<Category>> result = {};
    for (final main in _mainCategories) {
      final subs = subcategoriesOf(main.id!);
      if (subs.isNotEmpty) result[main] = subs;
    }
    return result;
  }

  /// Flat list of all subcategories across all parents.
  List<Category> get allSubcategories => _allSubcategories;

  /// Rebuilds all in-memory caches from the raw _categories list.
  /// Called once after each DB load — O(N) total, not O(N) per getter call.
  void _rebuildCache() {
    _categories.sort((a, b) {
      if (a.isSalaryWallet) return -1;
      if (b.isSalaryWallet) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    _categoryMap = {for (final c in _categories) c.id!: c};

    _mainCategories = _categories.where((c) => c.isMainCategory).toList();
    _allSubcategories = _categories.where((c) => c.isSubcategory).toList();

    _salaryWalletCategory = _categories.firstWhereOrNull(
      (c) => c.isSalaryWallet,
    );

    // Split targets = all main categories except the salary wallet itself
    _splitCategories = _mainCategories
        .where((c) => !c.isSalaryWallet)
        .toList();

    _subcategoryMap = {};
    for (final sub in _allSubcategories) {
      if (sub.parentId != null) {
        (_subcategoryMap[sub.parentId!] ??= []).add(sub);
      }
    }
  }

  // ================= INIT =================

  Future<void> initialize() async {
    await loadCategories();
  }

  Future<void> loadCategories() async {
    _categories = await _repository.getAllCategories();
    _rebuildCache();
    notifyListeners();
  }

  /// Returns true if the category OR its parent is set to be excluded from analysis.
  bool isExcluded(int? categoryId) {
    if (categoryId == null) return false;
    final cat = resolveCategory(categoryId);
    if (cat == null) return false;
    if (cat.excludeFromAnalysis) return true;
    if (cat.isSubcategory) {
      final parent = resolveCategory(cat.parentId!);
      return parent?.excludeFromAnalysis ?? false;
    }
    return false;
  }

  // ================= CORE DATA =================

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
    bool excludeFromAnalysis = false,
  }) async {
    clearError();
    final parent = resolveCategory(parentId);
    if (parent == null) {
      _setError('Parent category not found');
      return;
    }
    final subcategory = Category(
      name: name,
      parentId: parentId,
      excludeFromAnalysis: excludeFromAnalysis,
    );
    await addCategory(subcategory);
  }

  Future<void> setSalaryWallet(int categoryId) async {
    clearError();
    final category = resolveCategory(categoryId);
    if (category == null) {
      _setError('Category not found');
      return;
    }
    await _repository.setSalaryWallet(categoryId);
    await loadCategories();
  }

  Future<void> clearSalaryWallet() async {
    await _repository.clearSalaryWallet();
    await loadCategories();
  }

  Future<void> updateLinkedAccount(int categoryId, int? accountId) async {
    clearError();
    await _repository.updateLinkedAccount(categoryId, accountId);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    clearError();
    final category = resolveCategory(id);
    if (category == null) return;

    try {
      // Subcategories and associated data are handled via CASCADE or
      // explicit transaction in the repository.
      await _repository.deleteCategory(id);
      await loadCategories();
    } on DatabaseException catch (e) {
      if (e.toString().contains('FOREIGN KEY')) {
        _setError('Category is in use and cannot be deleted');
        return;
      }
      _setError('Failed to delete category');
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> updateCategory(int id, String newName, bool excludeFromAnalysis) async {
    clearError();
    try {
      await _repository.updateCategory(id, newName, excludeFromAnalysis);
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

  Future<void> mergeCategories(List<int> sourceIds, String newName) async {
    clearError();
    if (sourceIds.isEmpty) {
      _setError('No categories selected to merge');
      return;
    }
    try {
      await _repository.mergeCategories(sourceIds, newName);
      await loadCategories();
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _setError('A category with that name already exists');
        return;
      }
      _setError('Failed to merge categories');
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> mergeInto(int sourceId, int targetId) async {
    clearError();
    try {
      await _repository.mergeInto(sourceId, targetId);
      await loadCategories();
    } on DatabaseException catch (e) {
      _setError('Failed to migrate data: ${e.toString()}');
    } catch (_) {
      _setError('Something went wrong during migration');
    }
  }
}
