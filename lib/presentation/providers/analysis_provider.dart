import 'package:flutter/material.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class MonthlyTrend {
  final String label;
  final int year;
  final int month;
  final double income;
  final double expense;
  const MonthlyTrend(
    this.label,
    this.year,
    this.month,
    this.income,
    this.expense,
  );
  double get savings => income - expense;
}

class CategoryBreakdown {
  final int categoryId;
  final String name;
  final double amount;
  final double percentage;
  final bool isSubcategory;
  final int? parentId;
  final String? parentName;
  final List<CategoryBreakdown> subcategories;

  const CategoryBreakdown({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.percentage,
    this.isSubcategory = false,
    this.parentId,
    this.parentName,
    this.subcategories = const [],
  });
}

class AnalysisInsight {
  final String emoji;
  final String title;
  final String body;
  final InsightLevel level;
  const AnalysisInsight({
    required this.emoji,
    required this.title,
    required this.body,
    required this.level,
  });
}

enum InsightLevel { good, warning, danger, neutral }

enum AnalysisMode { monthly, yearly }

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class AnalysisProvider extends ChangeNotifier {
  LedgerProvider _ledger;
  CategoryProvider _categories;

  AnalysisProvider(this._ledger, this._categories) {
    _selectedAccountIds = _ledger.accounts.map((a) => a.id!).toSet();
    _recompute();
  }

  void updateDependencies(LedgerProvider ledger, CategoryProvider categories) {
    _ledger = ledger;
    _categories = categories;
    final currentIds = ledger.accounts.map((a) => a.id!).toSet();
    _selectedAccountIds = _selectedAccountIds.intersection(currentIds);
    if (_selectedAccountIds.isEmpty) _selectedAccountIds = currentIds;
    _recompute();
    notifyListeners();
  }

  // ── STATE ──

  Set<int> _selectedAccountIds = {};
  Set<int> get selectedAccountIds => _selectedAccountIds;

  AnalysisMode _mode = AnalysisMode.monthly;
  AnalysisMode get mode => _mode;
  bool get isMonthly => _mode == AnalysisMode.monthly;

  int _monthOffset = 0;
  int get monthOffset => _monthOffset;

  int _yearOffset = 0;
  int get yearOffset => _yearOffset;

  // ── COMPUTED — MONTHLY ──

  double totalIncome = 0;
  double totalExpense = 0;
  double savings = 0;
  double savingsRate = 0;

  List<MonthlyTrend> trend = []; // 6-month rolling
  List<CategoryBreakdown> expenseBreakdown = []; // main categories with subs
  List<CategoryBreakdown> incomeBreakdown = [];
  Map<int, double> dailySpend = {};
  List<AnalysisInsight> insights = [];

  // ── COMPUTED — YEARLY ──

  double yearTotalIncome = 0;
  double yearTotalExpense = 0;
  double yearSavings = 0;
  double yearSavingsRate = 0;
  double avgMonthlyIncome = 0;
  double avgMonthlyExpense = 0;
  double bestSavingsMonth = 0;
  String bestSavingsMonthLabel = '';
  List<MonthlyTrend> yearMonthlyBreakdown = []; // all 12 months of year
  List<CategoryBreakdown> yearExpenseBreakdown = [];
  List<CategoryBreakdown> yearIncomeBreakdown = [];

  // ── HELPERS ──

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  DateTime get _focusMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset);
  }

  int get _focusYear => DateTime.now().year + _yearOffset;

  String get periodLabel => isMonthly
      ? '${_monthNames[_focusMonth.month - 1]} ${_focusMonth.year}'
      : 'Year $_focusYear';

  bool get canGoForward => isMonthly ? _monthOffset < 0 : _yearOffset < 0;

  List<Account> get accounts => _ledger.accounts;

  // ── PUBLIC ACTIONS ──

  void setMode(AnalysisMode mode) {
    _mode = mode;
    _recompute();
    notifyListeners();
  }

  /// Resets period to the current month/year. Called when the
  /// Analysis tab becomes active so it always shows today's period.
  void resetToToday() {
    _monthOffset = 0;
    _yearOffset = 0;
    _recompute();
    notifyListeners();
  }

  void toggleAccount(int accountId) {
    if (_selectedAccountIds.contains(accountId)) {
      if (_selectedAccountIds.length == 1) return;
      _selectedAccountIds = Set.from(_selectedAccountIds)..remove(accountId);
    } else {
      _selectedAccountIds = Set.from(_selectedAccountIds)..add(accountId);
    }
    _recompute();
    notifyListeners();
  }

  void previous() {
    if (isMonthly) {
      _monthOffset--;
    } else {
      _yearOffset--;
    }
    _recompute();
    notifyListeners();
  }

  void next() {
    if (!canGoForward) return;
    if (isMonthly) {
      _monthOffset++;
    } else {
      _yearOffset++;
    }
    _recompute();
    notifyListeners();
  }

  // ── CORE COMPUTATION ──

  void _recompute() {
    final allTx = _ledger.transactions;
    // Build a (year, month) → transactions bucket map in one O(N) pass.
    // Every subsequent monthly/yearly filter is then a O(1) map lookup
    // instead of a repeated O(N) full-list scan.
    final buckets = _bucketByMonth(allTx);
    if (isMonthly) {
      _computeMonthly(allTx, buckets);
    } else {
      _computeYearly(allTx, buckets);
    }
  }

  /// Partitions all transactions into a `(year, month)` map in a single pass.
  Map<(int, int), List<TransactionEntity>> _bucketByMonth(
    List<TransactionEntity> all,
  ) {
    final map = <(int, int), List<TransactionEntity>>{};
    for (final tx in all) {
      if (tx.note == 'Opening_Balance') continue;
      if (tx.transferGroupId != null) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      final key = (date.year, date.month);
      (map[key] ??= []).add(tx);
    }
    return map;
  }

  void _computeMonthly(
    List<TransactionEntity> allTx,
    Map<(int, int), List<TransactionEntity>> buckets,
  ) {
    final monthTx = _filterBucketByAccounts(
        buckets[(_focusMonth.year, _focusMonth.month)] ?? const [],
    );

    totalIncome = monthTx
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    totalExpense = monthTx
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    savings = totalIncome - totalExpense;
    savingsRate = totalIncome > 0
        ? (savings / totalIncome * 100).clamp(-100.0, 100.0)
        : 0.0;

    trend = _buildTrend(buckets, 6);
    expenseBreakdown = _buildBreakdown(monthTx, 'expense', totalExpense);
    incomeBreakdown = _buildBreakdown(monthTx, 'income', totalIncome);
    dailySpend = _buildDailySpend(monthTx);
    insights = _buildInsights();
  }

  void _computeYearly(
    List<TransactionEntity> allTx,
    Map<(int, int), List<TransactionEntity>> buckets,
  ) {
    final year = _focusYear;
    final yearTx = _filterYearBucketByAccounts(buckets, year);

    yearTotalIncome = yearTx
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    yearTotalExpense = yearTx
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);
    yearSavings = yearTotalIncome - yearTotalExpense;
    yearSavingsRate = yearTotalIncome > 0
        ? (yearSavings / yearTotalIncome * 100).clamp(-100.0, 100.0)
        : 0.0;

    // 12-month breakdown: O(1) bucket lookup per month instead of O(N) scan
    yearMonthlyBreakdown = List.generate(12, (i) {
      final monthBucket = _filterBucketByAccounts(
        buckets[(year, i + 1)] ?? const [],
      );
      final inc = monthBucket
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final exp = monthBucket
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      return MonthlyTrend(_shortMonths[i], year, i + 1, inc, exp);
    });

    final monthsWithData = yearMonthlyBreakdown
        .where((m) => m.income > 0 || m.expense > 0)
        .length;
    final divisor = monthsWithData > 0 ? monthsWithData.toDouble() : 1;
    avgMonthlyIncome = yearTotalIncome / divisor;
    avgMonthlyExpense = yearTotalExpense / divisor;

    final best = yearMonthlyBreakdown.reduce(
      (a, b) => a.savings > b.savings ? a : b,
    );
    bestSavingsMonth = best.savings;
    bestSavingsMonthLabel = best.label;

    yearExpenseBreakdown = _buildBreakdown(yearTx, 'expense', yearTotalExpense);
    yearIncomeBreakdown = _buildBreakdown(yearTx, 'income', yearTotalIncome);
  }

  // ── FILTER HELPERS (bucket-based) ──

  /// Filters a pre-bucketed month list by selected accounts only — O(K).
  List<TransactionEntity> _filterBucketByAccounts(
    List<TransactionEntity> bucket,
  ) {
    return bucket.where((tx) {
      final accountId = tx.type == 'income' ? tx.toAccountId : tx.fromAccountId;
      return _selectedAccountIds.contains(accountId);
    }).toList();
  }

  /// Collects all buckets for a given year and filters by selected accounts.
  List<TransactionEntity> _filterYearBucketByAccounts(
    Map<(int, int), List<TransactionEntity>> buckets,
    int year,
  ) {
    final result = <TransactionEntity>[];
    for (int m = 1; m <= 12; m++) {
      final bucket = buckets[(year, m)];
      if (bucket == null) continue;
      for (final tx in bucket) {
        final accountId =
            tx.type == 'income' ? tx.toAccountId : tx.fromAccountId;
        if (_selectedAccountIds.contains(accountId)) result.add(tx);
      }
    }
    return result;
  }

  // ── BREAKDOWN WITH SUBCATEGORIES ──

  List<CategoryBreakdown> _buildBreakdown(
    List<TransactionEntity> txs,
    String type,
    double total,
  ) {
    // Aggregate by actual categoryId (could be subcategory or main)
    final Map<int, double> rawTotals = {};
    for (final tx in txs.where((t) => t.type == type)) {
      if (tx.categoryId == null) continue;
      rawTotals[tx.categoryId!] = (rawTotals[tx.categoryId!] ?? 0) + tx.amount;
    }

    // Group: resolve each id to its wallet-owning main category
    // Map: mainCategoryId → { subId → amount } + direct amount
    final Map<int, Map<int?, double>> grouped = {};

    for (final entry in rawTotals.entries) {
      final cat = _categories.resolveCategory(entry.key);
      if (cat == null) continue;

      if (cat.isSubcategory) {
        final parentId = cat.parentId!;
        grouped[parentId] ??= {};
        grouped[parentId]![entry.key] = entry.value;
      } else {
        grouped[entry.key] ??= {};
        grouped[entry.key]![null] =
            (grouped[entry.key]![null] ?? 0) + entry.value;
      }
    }

    // Build CategoryBreakdown list
    final List<CategoryBreakdown> result = [];
    for (final mainId in grouped.keys) {
      final mainCat = _categories.resolveCategory(mainId);
      if (mainCat == null) continue;

      // Total for this main category = direct + all subcategory amounts
      final subMap = grouped[mainId]!;
      final mainAmount = subMap.values.fold(0.0, (s, v) => s + v);

      // Build subcategory breakdowns
      final List<CategoryBreakdown> subs = [];
      for (final subEntry in subMap.entries) {
        if (subEntry.key == null) continue; // direct transactions
        final subCat = _categories.resolveCategory(subEntry.key);
        if (subCat == null) continue;
        subs.add(
          CategoryBreakdown(
            categoryId: subEntry.key!,
            name: subCat.name,
            amount: subEntry.value,
            percentage: mainAmount > 0
                ? (subEntry.value / mainAmount * 100)
                : 0,
            isSubcategory: true,
            parentId: mainId,
            parentName: mainCat.name,
          ),
        );
      }
      subs.sort((a, b) => b.amount.compareTo(a.amount));

      result.add(
        CategoryBreakdown(
          categoryId: mainId,
          name: mainCat.name,
          amount: mainAmount,
          percentage: total > 0 ? (mainAmount / total * 100) : 0,
          subcategories: subs,
        ),
      );
    }

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  List<MonthlyTrend> _buildTrend(
    Map<(int, int), List<TransactionEntity>> buckets,
    int count,
  ) {
    return List.generate(count, (i) {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month - (count - 1) + i);
      // O(1) bucket lookup + O(K) account filter per month
      final txs = _filterBucketByAccounts(
        buckets[(month.year, month.month)] ?? const [],
      );
      final inc = txs
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final exp = txs
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      return MonthlyTrend(
        _shortMonths[month.month - 1],
        month.year,
        month.month,
        inc,
        exp,
      );
    });
  }

  Map<int, double> _buildDailySpend(List<TransactionEntity> monthTx) {
    final Map<int, double> result = {};
    for (final tx in monthTx.where((t) => t.type == 'expense')) {
      final day = DateTime.fromMillisecondsSinceEpoch(tx.timestamp).day;
      result[day] = (result[day] ?? 0) + tx.amount;
    }
    return result;
  }

  List<AnalysisInsight> _buildInsights() {
    final List<AnalysisInsight> result = [];

    if (totalIncome == 0 && totalExpense == 0) {
      result.add(
        const AnalysisInsight(
          emoji: '📭',
          title: 'No Data',
          body: 'No transactions found for this period.',
          level: InsightLevel.neutral,
        ),
      );
      return result;
    }

    if (savingsRate >= 30) {
      result.add(
        AnalysisInsight(
          emoji: '🌟',
          title: 'Excellent Savings!',
          body:
              'You saved ${savingsRate.toStringAsFixed(0)}% of your income. Well above the 20% target.',
          level: InsightLevel.good,
        ),
      );
    } else if (savingsRate >= 20) {
      result.add(
        AnalysisInsight(
          emoji: '👍',
          title: 'Good Job!',
          body:
              'You saved ${savingsRate.toStringAsFixed(0)}% this month, hitting the 20% target.',
          level: InsightLevel.good,
        ),
      );
    } else if (savingsRate >= 0) {
      final needed = totalIncome * 0.20 - savings;
      result.add(
        AnalysisInsight(
          emoji: '🎯',
          title: 'Almost There',
          body:
              'Reduce spending by ₹${_fmt(needed)} more to reach the 20% savings target.',
          level: InsightLevel.warning,
        ),
      );
    } else {
      result.add(
        AnalysisInsight(
          emoji: '🚨',
          title: 'Overspending Alert',
          body:
              'You spent ₹${_fmt(totalExpense - totalIncome)} more than you earned.',
          level: InsightLevel.danger,
        ),
      );
    }

    if (trend.length >= 2) {
      final thisExp = trend.last.expense;
      final lastExp = trend[trend.length - 2].expense;
      if (lastExp > 0) {
        final change = (thisExp - lastExp) / lastExp * 100;
        if (change > 15) {
          result.add(
            AnalysisInsight(
              emoji: '📈',
              title: 'Spending Up ${change.toStringAsFixed(0)}%',
              body: 'You spent more than last month. Check what changed.',
              level: InsightLevel.warning,
            ),
          );
        } else if (change < -15) {
          result.add(
            AnalysisInsight(
              emoji: '📉',
              title: 'Spending Down ${change.abs().toStringAsFixed(0)}%',
              body: 'You spent less than last month. Keep it up!',
              level: InsightLevel.good,
            ),
          );
        }
      }
    }

    if (expenseBreakdown.isNotEmpty && expenseBreakdown.first.percentage > 40) {
      final top = expenseBreakdown.first;
      result.add(
        AnalysisInsight(
          emoji: '⚠️',
          title:
              '${top.name} is ${top.percentage.toStringAsFixed(0)}% of spending',
          body: 'One category dominating spending is worth reviewing.',
          level: InsightLevel.warning,
        ),
      );
    }

    return result;
  }
}

// ─────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────

String _fmt(double v) {
  if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
  return v.toStringAsFixed(0);
}
