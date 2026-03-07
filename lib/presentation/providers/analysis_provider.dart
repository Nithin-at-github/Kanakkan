import 'package:flutter/material.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';

// ─────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────

class MonthlyTrend {
  final String label; // "Jan", "Feb" etc.
  final double income;
  final double expense;
  const MonthlyTrend(this.label, this.income, this.expense);
}

class CategoryBreakdown {
  final String name;
  final double amount;
  final double percentage;
  const CategoryBreakdown({
    required this.name,
    required this.amount,
    required this.percentage,
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

// ─────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────

class AnalysisProvider extends ChangeNotifier {
  final LedgerProvider _ledger;
  final CategoryProvider _categories;

  AnalysisProvider(this._ledger, this._categories) {
    // Initialize with all accounts selected
    _selectedAccountIds = _ledger.accounts.map((a) => a.id!).toSet();
    _recompute();
  }

  /// Called by ProxyProvider when dependencies change
  void updateDependencies(LedgerProvider ledger, CategoryProvider categories) {
    // Sync account list — remove stale ids, add new ones
    final currentIds = ledger.accounts.map((a) => a.id!).toSet();
    _selectedAccountIds = _selectedAccountIds.intersection(currentIds);
    if (_selectedAccountIds.isEmpty) _selectedAccountIds = currentIds;
    _recompute();
    notifyListeners();
  }

  // ── SELECTED STATE ──

  Set<int> _selectedAccountIds = {};
  Set<int> get selectedAccountIds => _selectedAccountIds;

  int _monthOffset = 0; // 0 = current month, -1 = last month
  int get monthOffset => _monthOffset;

  // ── COMPUTED RESULTS ──

  double totalIncome = 0;
  double totalExpense = 0;
  double savings = 0;
  double savingsRate = 0; // 0–100

  List<MonthlyTrend> trend = [];
  List<CategoryBreakdown> topCategories = [];
  Map<int, double> dailySpend = {}; // day → amount
  List<AnalysisInsight> insights = [];

  // ── HELPERS ──

  DateTime get _focusMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset);
  }

  String get monthLabel {
    const months = [
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
    return '${months[_focusMonth.month - 1]} ${_focusMonth.year}';
  }

  bool get canGoForward => _monthOffset < 0;

  List<Account> get accounts => _ledger.accounts;

  // ── PUBLIC ACTIONS ──

  void toggleAccount(int accountId) {
    if (_selectedAccountIds.contains(accountId)) {
      if (_selectedAccountIds.length == 1) return; // keep at least one
      _selectedAccountIds = Set.from(_selectedAccountIds)..remove(accountId);
    } else {
      _selectedAccountIds = Set.from(_selectedAccountIds)..add(accountId);
    }
    _recompute();
    notifyListeners();
  }

  void previousMonth() {
    _monthOffset--;
    _recompute();
    notifyListeners();
  }

  void nextMonth() {
    if (!canGoForward) return;
    _monthOffset++;
    _recompute();
    notifyListeners();
  }

  // ── CORE COMPUTATION ──

  void _recompute() {
    final allTx = _ledger.transactions;

    // Transactions for the selected month + selected accounts
    final monthTx = _filterByMonthAndAccounts(allTx, _focusMonth);

    // Totals
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

    // 6-month trend
    trend = _buildTrend(allTx);

    // Category breakdown (expenses only)
    topCategories = _buildCategoryBreakdown(monthTx);

    // Daily spend map
    dailySpend = _buildDailySpend(monthTx);

    // Insights
    insights = _buildInsights();
  }

  List<TransactionEntity> _filterByMonthAndAccounts(
    List<TransactionEntity> all,
    DateTime month,
  ) {
    return all.where((tx) {
      // Skip opening balance entries
      if (tx.note == 'Opening_Balance') return false;
      // Skip transfers — they don't represent real income/expense
      if (tx.transferGroupId != null) return false;

      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      if (date.year != month.year || date.month != month.month) return false;

      final accountId = tx.type == 'income' ? tx.toAccountId : tx.fromAccountId;
      return _selectedAccountIds.contains(accountId);
    }).toList();
  }

  List<MonthlyTrend> _buildTrend(List<TransactionEntity> all) {
    const monthNames = [
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
    return List.generate(6, (i) {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month - 5 + i);
      final txs = _filterByMonthAndAccounts(all, month);
      final inc = txs
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final exp = txs
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      return MonthlyTrend(monthNames[month.month - 1], inc, exp);
    });
  }

  List<CategoryBreakdown> _buildCategoryBreakdown(
    List<TransactionEntity> monthTx,
  ) {
    final Map<int, double> totals = {};
    for (final tx in monthTx.where((t) => t.type == 'expense')) {
      if (tx.categoryId == null) continue;
      totals[tx.categoryId!] = (totals[tx.categoryId!] ?? 0) + tx.amount;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) {
      final name = _categories.resolveCategoryName(e.key);
      final pct = totalExpense > 0 ? (e.value / totalExpense * 100) : 0.0;
      return CategoryBreakdown(name: name, amount: e.value, percentage: pct);
    }).toList();
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

    // No data at all
    if (totalIncome == 0 && totalExpense == 0) {
      result.add(
        const AnalysisInsight(
          emoji: '📭',
          title: 'No Data',
          body: 'No transactions found for the selected accounts and month.',
          level: InsightLevel.neutral,
        ),
      );
      return result;
    }

    // Savings rate
    if (savingsRate >= 30) {
      result.add(
        AnalysisInsight(
          emoji: '🌟',
          title: 'Excellent Savings!',
          body:
              'You saved ${savingsRate.toStringAsFixed(0)}% of your income. That\'s well above the 20% target.',
          level: InsightLevel.good,
        ),
      );
    } else if (savingsRate >= 20) {
      result.add(
        AnalysisInsight(
          emoji: '👍',
          title: 'Good Job!',
          body:
              'You saved ${savingsRate.toStringAsFixed(0)}% this month, hitting the recommended 20% target.',
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
              'You saved ${savingsRate.toStringAsFixed(0)}%. Reduce spending by ₹${_fmt(needed)} more to reach 20%.',
          level: InsightLevel.warning,
        ),
      );
    } else {
      result.add(
        AnalysisInsight(
          emoji: '🚨',
          title: 'Overspending Alert',
          body:
              'You spent ₹${_fmt(totalExpense - totalIncome)} more than you earned. Review your top expenses.',
          level: InsightLevel.danger,
        ),
      );
    }

    // Month-over-month spend change
    if (trend.length >= 2) {
      final thisExp = trend.last.expense;
      final lastExp = trend[trend.length - 2].expense;
      if (lastExp > 0) {
        final change = (thisExp - lastExp) / lastExp * 100;
        if (change > 15) {
          result.add(
            AnalysisInsight(
              emoji: '📈',
              title: 'Spending Increased',
              body:
                  'You spent ${change.toStringAsFixed(0)}% more than last month. Check what changed.',
              level: InsightLevel.warning,
            ),
          );
        } else if (change < -15) {
          result.add(
            AnalysisInsight(
              emoji: '📉',
              title: 'Spending Decreased',
              body:
                  'You spent ${change.abs().toStringAsFixed(0)}% less than last month. Keep it up!',
              level: InsightLevel.good,
            ),
          );
        }
      }
    }

    // Top category warning
    if (topCategories.isNotEmpty && topCategories.first.percentage > 40) {
      final top = topCategories.first;
      result.add(
        AnalysisInsight(
          emoji: '⚠️',
          title:
              '${top.name} is ${top.percentage.toStringAsFixed(0)}% of spending',
          body:
              'One category taking up this much is a sign to review if it\'s necessary.',
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
