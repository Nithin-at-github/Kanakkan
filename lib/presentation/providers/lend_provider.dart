import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/safe_iterable.dart';
import 'package:kanakkan/data/models/transaction_model.dart';
import 'package:kanakkan/data/repositories/category_repository.dart';
import 'package:kanakkan/data/repositories/lend_repository.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/domain/entities/lend_person.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';

class LendProvider extends ChangeNotifier {
  LedgerProvider _ledger;
  final LendRepository _lendRepository = LendRepository();

  List<({LendPerson person, double balance})> _people = [];
  List<({LendPerson person, double balance})> get people => _people;

  List<TransactionModel> _personTransactions = [];
  List<TransactionModel> get personTransactions => _personTransactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _activePersonId;
  int? get activePersonId => _activePersonId;

  LendProvider(this._ledger);

  void setActivePersonId(int? id) {
    _activePersonId = id;
    if (id != null) {
      loadTransactionsForPerson(id);
    } else {
      _personTransactions = [];
      Future.microtask(() => notifyListeners());
    }
  }

  void updateLedger(LedgerProvider newLedger) {
    _ledger = newLedger;
    loadPeople();
    if (_activePersonId != null) {
      loadTransactionsForPerson(_activePersonId!, showLoading: false);
    }
  }

  Future<void> loadPeople() async {
    _people = await _lendRepository.getAllPeopleWithBalances();
    notifyListeners();
  }

  Future<void> loadTransactionsForPerson(int personId, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      Future.microtask(() => notifyListeners());
    }

    final txs = await _lendRepository.getTransactionsForPerson(personId);
    _personTransactions = txs;
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> addPerson(String name, String? phoneNumber) async {
    final person = LendPerson(
      name: name,
      phoneNumber: phoneNumber?.isEmpty == true ? null : phoneNumber,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _lendRepository.insertPerson(person);
    await loadPeople();
  }

  Future<void> editPerson(LendPerson person) async {
    await _lendRepository.updatePerson(person);
    await loadPeople();
  }

  Future<void> deletePerson(int id) async {
    await _lendRepository.deletePerson(id);
    // Reload ledger as transactions are unlinked (which clears their lendPersonId)
    await _ledger.initialize();
    await loadPeople();
  }

  Future<void> linkTransactions(int personId, List<int> transactionIds) async {
    await _lendRepository.linkTransactionsToPerson(personId, transactionIds);
    await _ledger.initialize(); // Trigger reload of LedgerProvider
    await loadPeople();
    if (_activePersonId == personId) {
      await loadTransactionsForPerson(personId);
    }
  }

  /// Finds or creates a default Lend subcategory under "Others".
  /// Returns the category ID.
  Future<int> getOrCreateLendCategoryId() async {
    final catRepo = CategoryRepository();
    final allCats = await catRepo.getAllCategories();

    // 1. Search for subcategory named "Lend" (has parentId != null)
    final subLend = allCats.firstWhereOrNull(
      (c) => c.name.toLowerCase() == 'lend' && c.parentId != null,
    );
    if (subLend != null) return subLend.id!;

    // 2. Search for main category named "Lend" (has parentId == null)
    final mainLend = allCats.firstWhereOrNull(
      (c) => c.name.toLowerCase() == 'lend' && c.parentId == null,
    );
    if (mainLend != null) return mainLend.id!;

    // 3. Search for "Others" category to create "Lend" as subcategory
    final othersCat = allCats.firstWhereOrNull(
      (c) => c.name.toLowerCase() == 'others' && c.parentId == null,
    );
    if (othersCat != null) {
      final newSub = Category(name: 'Lend', parentId: othersCat.id);
      return await catRepo.insertCategory(newSub);
    }

    // 4. Create top-level "Others" and "Lend" subcategory
    final othersId = await catRepo.insertCategory(const Category(name: 'Others'));
    final newSub = Category(name: 'Lend', parentId: othersId);
    return await catRepo.insertCategory(newSub);
  }
}
