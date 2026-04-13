import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/safe_iterable.dart';
import 'package:kanakkan/data/models/salary_trigger.dart';
import 'package:kanakkan/data/models/transaction_model.dart';
import 'package:kanakkan/data/database/database_helper.dart';
import 'package:kanakkan/data/repositories/account_repository.dart';
import 'package:kanakkan/data/repositories/salary_allocation_repository.dart';
import 'package:kanakkan/data/repositories/transaction_wallet_split_repository.dart';
import 'package:kanakkan/data/repositories/transaction_repository.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/data/models/account_model.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum TransactionDeleteType { normal, salaryDistributed }

class LedgerProvider extends ChangeNotifier {
  CategoryBalanceProvider balanceProvider;
  CategoryProvider categoryProvider = CategoryProvider();

  /// Trigger for salary income dialog
  final ValueNotifier<SalaryTrigger?> salaryIncomeTrigger = ValueNotifier(null);

  LedgerProvider(this.categoryProvider, this.balanceProvider);

  int? get salaryCategoryId => categoryProvider.getSalaryCategoryId();

  final SalaryAllocationRepository _salaryAllocationRepository =
      SalaryAllocationRepository();
  final TransactionWalletSplitRepository _walletSplitRepository =
      TransactionWalletSplitRepository();

  // ================= ERROR STATE =================

  String? lastError;

  void _setError(String message) {
    lastError = message;
    notifyListeners();
  }

  void clearError() {
    lastError = null;
  }

  void updateDependencies(
    CategoryProvider newCategoryProvider,
    CategoryBalanceProvider newBalanceProvider,
  ) {
    categoryProvider = newCategoryProvider;
    balanceProvider = newBalanceProvider;
  }

  void updateBalanceProvider(CategoryBalanceProvider newProvider) {
    balanceProvider = newProvider;
  }

  // ================= ACCOUNT RESOLVERS =================

  String resolveAccountName(int? accountId) {
    if (accountId == null) return "Not Found";
    final account = accounts.firstWhereOrNull((a) => a.id == accountId);
    return account?.name ?? "Deleted Account";
  }

  String resolvePrimaryAccountName(TransactionEntity tx) {
    int? accountId;
    switch (tx.type) {
      case "income":
        accountId = tx.toAccountId;
        break;
      case "expense":
        accountId = tx.fromAccountId;
        break;
      case "transfer":
        accountId = tx.fromAccountId;
        break;
      default:
        return "-";
    }
    return resolveAccountName(accountId);
  }

  Account? resolveAccount(int? accountId) {
    if (accountId == null) return null;
    return accounts.firstWhereOrNull((a) => a.id == accountId);
  }

  SalaryTrigger? consumeSalaryTrigger() {
    final trigger = salaryIncomeTrigger.value;
    salaryIncomeTrigger.value = null;
    return trigger;
  }

  // ================= REPOSITORIES =================

  final AccountRepository _accountRepository = AccountRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  // ================= STATE =================

  final Map<int, double> _accountBalances = {};
  Map<int, double> get accountBalances => _accountBalances;

  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  List<TransactionEntity> _transactions = [];
  List<TransactionEntity> get transactions => _transactions;

  String? _currentFilter;
  String? get currentFilter => _currentFilter;

  // ================= MONTHLY CACHE =================

  final Map<int, double> _monthlyCategoryTotals = {};
  int? _activeMonth;
  int? _activeYear;

  double getMonthlySpent(int categoryId) {
    return _monthlyCategoryTotals[categoryId] ?? 0.0;
  }

  void rebuildMonthlyTotals({required int month, required int year}) {
    _activeMonth = month;
    _activeYear = year;
    _monthlyCategoryTotals.clear();

    for (final tx in _transactions) {
      if (tx.type != "expense" || tx.transferGroupId != null) continue;
      if (categoryProvider.isExcluded(tx.categoryId)) continue;

      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      if (date.month != month || date.year != year) continue;

      final categoryId = tx.categoryId;
      if (categoryId == null) continue;

      // 1. Direct attribution (Self)
      _monthlyCategoryTotals[categoryId] =
          (_monthlyCategoryTotals[categoryId] ?? 0) + tx.amount;

      // 2. Roll up to parent (if subcategory)
      final category = categoryProvider.resolveCategory(categoryId);
      if (category != null && category.isSubcategory && category.parentId != null) {
        final parentId = category.parentId!;
        _monthlyCategoryTotals[parentId] =
            (_monthlyCategoryTotals[parentId] ?? 0) + tx.amount;
      }
    }
  }

  // ================= INITIALIZE =================

  Future<void> initialize() async {
    await loadAccounts();
    await loadTransactions();
    await calculateBalances();

    // One-time wallet reconciliation for version 11
    const storage = FlutterSecureStorage();
    final lastReconciled = await storage.read(key: 'last_reconciled_v');
    if (lastReconciled == null || int.parse(lastReconciled) < 11) {
      await reconcileCategoryWallets();
    }
  }

  // ================= BALANCE CALC =================

  Future<void> calculateBalances() async {
    final db = await DatabaseHelper.instance.database;

    // Single query: credit (incoming) per account
    final creditRows = await db.rawQuery(
      'SELECT toAccountId AS id, SUM(amount) AS total '
      'FROM transactions WHERE toAccountId IS NOT NULL '
      'GROUP BY toAccountId',
    );
    // Single query: debit (outgoing) per account
    final debitRows = await db.rawQuery(
      'SELECT fromAccountId AS id, SUM(amount) AS total '
      'FROM transactions WHERE fromAccountId IS NOT NULL '
      'GROUP BY fromAccountId',
    );

    final credits = <int, double>{};
    for (final row in creditRows) {
      credits[row['id'] as int] = (row['total'] as num).toDouble();
    }
    final debits = <int, double>{};
    for (final row in debitRows) {
      debits[row['id'] as int] = (row['total'] as num).toDouble();
    }

    _accountBalances.clear();
    for (final account in _accounts) {
      final id = account.id!;
      _accountBalances[id] = (credits[id] ?? 0) - (debits[id] ?? 0);
    }

    notifyListeners();
  }

  // ================= RECONCILIATION =================

  /// Re-calculates all category wallet balances and expense splits from scratch.
  /// This ensures that subcategory income is correctly rolled up to parent wallets
  /// and any past data inconsistencies are resolved.
  Future<void> reconcileCategoryWallets() async {
    final db = await DatabaseHelper.instance.database;
    // 1. Get all transactions ordered by timestamp ASC for correct balance simulation
    final allTxModels = await _transactionRepository.getAllTransactions();
    final allTx = allTxModels.reversed.toList(); // getAllTransactions is DESC

    await db.transaction((txn) async {
      // 2. Clear current bucket state
      await txn.execute('DELETE FROM category_balances');
      await txn.execute('DELETE FROM transaction_wallet_splits');

      final balances = <int, double>{};
      final salaryId = categoryProvider.getSalaryCategoryId();

      for (final tx in allTx) {
        // Transfers don't affect category wallets
        if (tx.transferGroupId != null && tx.type != "income" && tx.type != "expense") continue;
        if (tx.type == "transfer") continue;

        final baseCategoryId = tx.categoryId ?? salaryId;
        if (baseCategoryId == null) continue;

        // Resolve rollup (Parent if it's a subcategory)
        final walletId = _walletCategoryId(baseCategoryId) ?? baseCategoryId;

        if (tx.type == "income") {
          balances[walletId] = (balances[walletId] ?? 0) + tx.amount;
        } else if (tx.type == "expense") {
          // Simulate _spendWithSalaryFallback logic using local balance map
          final currentCatBal = balances[walletId] ?? 0;
          final splits = <({int categoryId, double amount})>[];

          if (currentCatBal >= tx.amount) {
            // Enough in category wallet
            balances[walletId] = currentCatBal - tx.amount;
            splits.add((categoryId: walletId, amount: tx.amount));
          } else {
            // Partial/Full shortfall handled by pulling from Salary Wallet
            final fromCategory = currentCatBal;
            final fromSalary = tx.amount - fromCategory;

            if (fromCategory > 0) {
              balances[walletId] = 0;
              splits.add((categoryId: walletId, amount: fromCategory));
            }

            if (salaryId != null && fromSalary > 0) {
              balances[salaryId] = (balances[salaryId] ?? 0) - fromSalary;
              splits.add((categoryId: salaryId, amount: fromSalary));
            }
          }

          // Save calculated splits back to DB
          for (final split in splits) {
            await txn.insert('transaction_wallet_splits', {
              'transactionId': tx.id,
              'categoryId': split.categoryId,
              'amount': split.amount,
            });
          }
        }
      }

      // 3. Batch insert final balances
      for (final entry in balances.entries) {
        await txn.insert('category_balances', {
          'categoryId': entry.key,
          'balance': entry.value,
        });
      }
    });

    // 4. Mark as reconciled
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_reconciled_v', value: '11');

    // 5. Reload provider states to reflect changes globally
    await balanceProvider.loadBalances();
    await _reloadAll();
  }

  // ================= ACCOUNTS =================

  Future<void> loadAccounts() async {
    _accounts = await _accountRepository.getAllAccounts();
    notifyListeners();
  }

  Future<void> addAccount(Account account) async {
    clearError();
    final model = AccountModel(
      id: account.id,
      name: account.name,
      initialBalance: account.initialBalance,
    );
    try {
      final insertedId = await _accountRepository.insertAccount(model);
      final createdAccount = account.copyWith(id: insertedId);
      await _createOpeningBalanceTransaction(createdAccount);
      await _reloadAll();
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _setError('An account with this name already exists');
        return;
      }
      _setError('Failed to create account');
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> updateAccount(Account updated) async {
    clearError();
    final updatedModel = AccountModel(
      id: updated.id,
      name: updated.name,
      initialBalance: updated.initialBalance,
    );
    try {
      await _accountRepository.updateAccount(updatedModel);
      await _updateOpeningBalanceTransaction(updated);
      await _reloadAll();
    } on DatabaseException catch (e) {
      if (e.toString().contains('UNIQUE')) {
        _setError('An account with this name already exists');
        return;
      }
      _setError('Failed to update account');
    } catch (_) {
      _setError('Something went wrong');
    }
  }

  Future<void> deleteAccount(int accountId) async {
    await _removeOpeningBalance(accountId);
    await _accountRepository.deleteAccount(accountId);
    _accountBalances.remove(accountId);
    await _reloadAll();
  }

  // ================= TRANSACTIONS =================

  Future<void> addIncome({
    required double amount,
    required int toAccountId,
    int? categoryId,
    String? note,
    int? timestamp,
  }) async {
    final transaction = TransactionModel(
      type: "income",
      amount: amount,
      fromAccountId: null,
      toAccountId: toAccountId,
      categoryId: categoryId,
      note: note,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );

    final id = await _transactionRepository.insertTransaction(transaction);
    await _applyBalanceEffect(transaction);

    // Single reload + single notifyListeners at the end
    await _reloadAll();

    // Fire salary trigger only if this category is designated as the
    // salary wallet. Gracefully skips if no wallet is designated.
    if (categoryProvider.hasSalaryWallet && _isSalaryCategory(categoryId)) {
      Future.microtask(() {
        salaryIncomeTrigger.value = SalaryTrigger(
          transactionId: id,
          amount: amount,
        );
      });
    }
  }

  /// Returns the wallet-owning category id for a given categoryId.
  /// Subcategories don't have wallets — we use their parent's wallet.
  int? _walletCategoryId(int? categoryId) {
    if (categoryId == null) return null;
    final cat = categoryProvider.resolveCategory(categoryId);
    if (cat == null) return null;
    return cat.isSubcategory ? cat.parentId : categoryId;
  }

  /// Uses the isSalaryWallet flag — name-independent
  bool _isSalaryCategory(int? categoryId) {
    if (categoryId == null) return false;
    final category = categoryProvider.resolveCategory(categoryId);
    return category?.isSalaryWallet ?? false;
  }

  Future<void> addExpense({
    required double amount,
    required int fromAccountId,
    int? categoryId,
    String? note,
    int? timestamp,
  }) async {
    final transaction = TransactionModel(
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      toAccountId: null,
      categoryId: categoryId,
      note: note,
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
    );

    final id = await _transactionRepository.insertTransaction(transaction);
    await _applyBalanceEffect(transaction, transactionId: id);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  /// Saves multiple expenses in one DB transaction and reloads once.
  /// Used by the bulk-entry screen to avoid N individual _reloadAll calls.
  Future<void> addExpensesBatch(
    List<({double amount, int fromAccountId, int? categoryId, String? note, int? timestamp})> items,
  ) async {
    for (final item in items) {
      final transaction = TransactionModel(
        type: "expense",
        amount: item.amount,
        fromAccountId: item.fromAccountId,
        toAccountId: null,
        categoryId: item.categoryId,
        note: item.note,
        timestamp: item.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      );
      final id = await _transactionRepository.insertTransaction(transaction);
      await _applyBalanceEffect(transaction, transactionId: id);
    }
    // Single reload for all items
    await _reloadAll();
  }

  /// Saves multiple income transactions in one pass and reloads once.
  Future<void> addIncomesBatch(
    List<({double amount, int toAccountId, int? categoryId, String? note, int? timestamp})> items,
  ) async {
    int? lastSalaryTxId;
    double? lastSalaryAmount;

    for (final item in items) {
      final transaction = TransactionModel(
        type: "income",
        amount: item.amount,
        fromAccountId: null,
        toAccountId: item.toAccountId,
        categoryId: item.categoryId,
        note: item.note,
        timestamp: item.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      );
      final id = await _transactionRepository.insertTransaction(transaction);
      await _applyBalanceEffect(transaction);

      if (categoryProvider.hasSalaryWallet &&
          _isSalaryCategory(item.categoryId)) {
        lastSalaryTxId = id;
        lastSalaryAmount = item.amount;
      }
    }

    await _reloadAll();

    // Fire salary trigger for the last salary income if any
    if (lastSalaryTxId != null) {
      Future.microtask(() {
        salaryIncomeTrigger.value = SalaryTrigger(
          transactionId: lastSalaryTxId!,
          amount: lastSalaryAmount!,
        );
      });
    }
  }

  Future<void> transferFunds({
    required double amount,
    required int fromAccountId,
    required int toAccountId,
    String? note,
    int? timestamp,
  }) async {
    final groupId = const Uuid().v4();
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final expenseLeg = TransactionModel(
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      timestamp: ts,
      note: note,
      transferGroupId: groupId,
    );

    final incomeLeg = TransactionModel(
      type: "income",
      amount: amount,
      toAccountId: toAccountId,
      timestamp: ts,
      note: note,
      transferGroupId: groupId,
    );

    await _transactionRepository.insertTransaction(expenseLeg);
    await _transactionRepository.insertTransaction(incomeLeg);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  /// Returns wallet splits for an expense transaction.
  /// Used by the transaction detail sheet to show which wallets were debited.
  Future<List<WalletSplit>> getWalletSplits(int transactionId) {
    return _walletSplitRepository.getSplits(transactionId);
  }

  Future<TransactionEntity?> getPairedTransferLeg(TransactionEntity tx) async {
    if (tx.transferGroupId == null) return null;
    final legs = await _transactionRepository.getTransactionsByGroupId(
      tx.transferGroupId!,
    );
    return legs.firstWhereOrNull((leg) => leg.id != tx.id);
  }

  Future<void> updateTransfer({
    required TransactionEntity oldExpense,
    required TransactionEntity oldIncome,
    required double amount,
    required int fromAccountId,
    required int toAccountId,
    required int timestamp,
    String? note,
  }) async {
    await _applyBalanceEffect(oldExpense, reverse: true);
    await _applyBalanceEffect(oldIncome, reverse: true);

    final newExpense = TransactionModel(
      id: oldExpense.id,
      type: "expense",
      amount: amount,
      fromAccountId: fromAccountId,
      timestamp: timestamp,
      note: note,
      transferGroupId: oldExpense.transferGroupId,
    );

    final newIncome = TransactionModel(
      id: oldIncome.id,
      type: "income",
      amount: amount,
      toAccountId: toAccountId,
      timestamp: timestamp,
      note: note,
      transferGroupId: oldIncome.transferGroupId,
    );

    await _transactionRepository.updateTransferLegs(
      expenseLeg: newExpense,
      incomeLeg: newIncome,
    );

    await _applyBalanceEffect(newExpense);
    await _applyBalanceEffect(newIncome);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  // ================= LOAD =================

  Future<void> loadTransactions({String? type}) async {
    _currentFilter = type;
    _transactions = await _transactionRepository.getTransactions(type: type);

    if (_activeMonth != null && _activeYear != null) {
      rebuildMonthlyTotals(month: _activeMonth!, year: _activeYear!);
    }

    notifyListeners();
  }

  // ================= DELETE TRANSACTION =================

  Future<void> deleteTransaction(int id) async {
    final tx = _transactions.firstWhereOrNull((t) => t.id == id);

    if (tx?.transferGroupId != null) {
      final legs = await _transactionRepository.getTransactionsByGroupId(
        tx!.transferGroupId!,
      );
      for (final leg in legs) {
        await _applyBalanceEffect(leg, reverse: true);
        await _transactionRepository.deleteTransaction(leg.id!);
      }
    } else {
      if (tx != null) {
        await _applyBalanceEffect(tx, reverse: true);

        // Reverse salary wallet allocations using stored records — NOT the
        // current isSalaryWallet flag. This is correct even if the user has
        // switched the salary wallet since this transaction was created.
        final salaryAllocations = await _salaryAllocationRepository
            .getAllocations(id);
        if (salaryAllocations.isNotEmpty) {
          for (final alloc in salaryAllocations) {
            final categoryId = alloc['categoryId'] as int;
            final amount = (alloc['amount'] as num).toDouble();
            // Reverse: subtract from the target wallet, add back to the
            // original salary wallet (tx.categoryId) regardless of current flag
            await balanceProvider.spend(categoryId, amount);
            await balanceProvider.allocate(tx.categoryId!, amount);
          }
          await _salaryAllocationRepository.deleteAllocations(id);
        }
      }
      await _transactionRepository.deleteTransaction(id);
    }

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  Future<TransactionDeleteType> getDeleteType(TransactionEntity tx) async {
    // Do NOT rely on current isSalaryWallet flag — the user may have
    // switched the salary wallet since this transaction was created.
    // Instead, check whether salary allocations were actually stored
    // for this transaction. That's the authoritative source of truth.
    if (tx.type != 'income' || tx.id == null) {
      return TransactionDeleteType.normal;
    }
    final allocations = await _salaryAllocationRepository.getAllocations(
      tx.id!,
    );
    if (allocations.isEmpty) {
      return TransactionDeleteType.normal;
    }
    return TransactionDeleteType.salaryDistributed;
  }

  // ================= UPDATE TRANSACTION =================

  Future<void> updateTransaction({
    required TransactionEntity oldTx,
    required TransactionEntity newTx,
  }) async {
    await _applyBalanceEffect(oldTx, reverse: true);

    final model = TransactionModel(
      id: newTx.id,
      type: newTx.type,
      amount: newTx.amount,
      fromAccountId: newTx.fromAccountId,
      toAccountId: newTx.toAccountId,
      categoryId: newTx.categoryId,
      note: newTx.note,
      timestamp: newTx.timestamp,
    );

    await _transactionRepository.updateTransaction(model);
    await _applyBalanceEffect(newTx);

    // Single reload + single notifyListeners at the end
    await _reloadAll();
  }

  // ================= WALLET EFFECT =================

  // ================= WALLET SUFFICIENCY CHECK =================

  /// Returns true if the expense can be covered by category wallet
  /// + salary wallet combined. Used by AddTransactionScreen to gate
  /// the save button before calling addExpense.
  bool canAffordExpense({required int categoryId, required double amount}) {
    final walletId = _walletCategoryId(categoryId) ?? categoryId;
    if (_isSalaryCategory(walletId)) {
      return balanceProvider.getBalance(walletId) >= amount;
    }
    final categoryBalance = balanceProvider.getBalance(walletId);
    // If no salary wallet is designated, only check category balance
    if (!categoryProvider.hasSalaryWallet) return categoryBalance >= amount;
    final salaryId = salaryCategoryId;
    final salaryBalance = salaryId != null
        ? balanceProvider.getBalance(salaryId)
        : 0.0;
    return (categoryBalance + salaryBalance) >= amount;
  }

  Future<void> _applyBalanceEffect(
    TransactionEntity tx, {
    bool reverse = false,
    int? transactionId,
  }) async {
    final baseCategoryId = tx.categoryId ?? salaryCategoryId;
    if (baseCategoryId == null) return; // No wallet system established yet

    // Resolve to the actual wallet (Parent if it's a subcategory)
    final walletId = _walletCategoryId(baseCategoryId) ?? baseCategoryId;

    final amount = reverse ? -tx.amount : tx.amount;

    if (tx.type == "expense") {
      if (reverse) {
        // Reversal: read stored splits so we restore each wallet correctly
        final id = transactionId ?? tx.id;
        if (id != null) {
          final splits = await _walletSplitRepository.getSplits(id);
          if (splits.isNotEmpty) {
            for (final split in splits) {
              await balanceProvider.allocate(split.categoryId, split.amount);
            }
            await _walletSplitRepository.deleteSplits(id);
            return;
          }
        }
        // Fallback for old transactions with no split record
        await balanceProvider.allocate(walletId, tx.amount);
      } else {
        final splits = await _spendWithSalaryFallback(
          categoryId: baseCategoryId,
          amount: tx.amount,
        );
        // Persist splits so detail screen and reversal can read them
        final id = transactionId ?? tx.id;
        if (id != null && splits.isNotEmpty) {
          await _walletSplitRepository.saveSplits(
            transactionId: id,
            splits: splits,
          );
        }
      }
    }

    if (tx.type == "income") {
      await balanceProvider.allocate(walletId, amount);
    }
  }

  /// Spends from category wallet first. If category wallet runs short,
  /// the remainder is pulled from the salary wallet.
  /// Returns the list of wallet splits so they can be persisted.
  Future<List<WalletSplit>> _spendWithSalaryFallback({
    required int categoryId,
    required double amount,
  }) async {
    // Subcategories don't have wallets — resolve to main category wallet
    final walletId = _walletCategoryId(categoryId) ?? categoryId;
    final splits = <WalletSplit>[];
    final categoryBalance = balanceProvider.getBalance(walletId);

    if (categoryBalance >= amount) {
      // Category wallet has enough — spend entirely from it
      await balanceProvider.spend(walletId, amount);
      splits.add(WalletSplit(categoryId: walletId, amount: amount));
      return splits;
    }

    // Partial: use whatever is in category wallet
    final fromCategory = categoryBalance;
    final fromSalary = amount - fromCategory;

    if (fromCategory > 0) {
      await balanceProvider.spend(walletId, fromCategory);
      splits.add(WalletSplit(categoryId: walletId, amount: fromCategory));
    }

    // Pull shortfall from salary wallet
    final salaryId = salaryCategoryId;
    if (salaryId != null && fromSalary > 0) {
      await balanceProvider.spend(salaryId, fromSalary);
      splits.add(WalletSplit(categoryId: salaryId, amount: fromSalary));
    }

    return splits;
  }

  // ================= RELOAD HELPER =================
  //
  // Replaces the pattern of calling loadTransactions() + calculateBalances()
  // separately (which fired notifyListeners twice). Now all state is refreshed
  // in one pass and listeners are notified exactly once at the end.

  Future<void> _reloadAll() async {
    _accounts = await _accountRepository.getAllAccounts();
    _transactions = await _transactionRepository.getTransactions(
      type: _currentFilter,
    );

    if (_activeMonth != null && _activeYear != null) {
      rebuildMonthlyTotals(month: _activeMonth!, year: _activeYear!);
    }

    // 2 grouped queries instead of N×2 sequential per-account queries
    final db = await DatabaseHelper.instance.database;
    final creditRows = await db.rawQuery(
      'SELECT toAccountId AS id, SUM(amount) AS total '
      'FROM transactions WHERE toAccountId IS NOT NULL '
      'GROUP BY toAccountId',
    );
    final debitRows = await db.rawQuery(
      'SELECT fromAccountId AS id, SUM(amount) AS total '
      'FROM transactions WHERE fromAccountId IS NOT NULL '
      'GROUP BY fromAccountId',
    );
    final credits = <int, double>{};
    for (final row in creditRows) {
      credits[row['id'] as int] = (row['total'] as num).toDouble();
    }
    final debits = <int, double>{};
    for (final row in debitRows) {
      debits[row['id'] as int] = (row['total'] as num).toDouble();
    }
    _accountBalances.clear();
    for (final account in _accounts) {
      final id = account.id!;
      _accountBalances[id] = (credits[id] ?? 0) - (debits[id] ?? 0);
    }

    notifyListeners(); // ← exactly once per operation
  }

  // ================= OPENING BALANCE =================

  Future<void> _createOpeningBalanceTransaction(Account account) async {
    if (account.initialBalance <= 0) return;
    final model = TransactionModel(
      type: "income",
      amount: account.initialBalance,
      fromAccountId: null,
      toAccountId: account.id,
      categoryId: null,
      note: "Opening_Balance",
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await _transactionRepository.insertTransaction(model);
  }

  Future<void> _updateOpeningBalanceTransaction(Account account) async {
    final openingTx = _transactions.firstWhereOrNull(
      (tx) => tx.note == "Opening_Balance" && tx.toAccountId == account.id,
    );
    if (openingTx == null) {
      await _createOpeningBalanceTransaction(account);
      return;
    }
    final updatedTx = openingTx.copyWith(amount: account.initialBalance);
    await updateTransaction(oldTx: openingTx, newTx: updatedTx);
  }

  Future<void> _removeOpeningBalance(int accountId) async {
    final openingTx = _transactions.firstWhereOrNull(
      (tx) => tx.note == "Opening_Balance" && tx.toAccountId == accountId,
    );
    if (openingTx != null) {
      await _transactionRepository.deleteTransaction(openingTx.id!);
    }
  }
}
