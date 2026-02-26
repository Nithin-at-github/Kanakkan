import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/ui/screens/add_transaction_screen.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';

enum DateFilterMode { daily, weekly, monthly, yearly }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateFilterMode filterMode = DateFilterMode.monthly;
  DateTime selectedDate = DateTime.now();
  late NavigationProvider _nav;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nav = context.read<NavigationProvider>();

      _nav.addListener(_onTabChanged);
    });
  }

  @override
  void dispose() {
    _nav.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_nav.currentIndex == 0 && _nav.previousIndex != 0) {
      _resetToToday();
    }
  }

  void _resetToToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LedgerProvider>();

    final filtered = _filterTransactions(provider.transactions);

    final totalExpense = filtered
        .where((e) => e.type == "expense")
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalIncome = filtered
        .where((e) => e.type == "income")
        .fold(0.0, (sum, e) => sum + e.amount);

    final total = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          "കണക്കൻ",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                /// DATE SELECTOR + FILTER BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_left,
                        color: AppTheme.accent,
                      ),
                      onPressed: _previousPeriod,
                    ),

                    Text(
                      _formatDate(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.arrow_right,
                        color: AppTheme.accent,
                      ),
                      onPressed: _nextPeriod,
                    ),

                    const SizedBox(width: 10),

                    PopupMenuButton<DateFilterMode>(
                      icon: const Icon(
                        Icons.filter_list,
                        color: AppTheme.accent,
                      ),
                      onSelected: (mode) {
                        setState(() => filterMode = mode);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: DateFilterMode.daily,
                          child: Text("Daily"),
                        ),
                        PopupMenuItem(
                          value: DateFilterMode.weekly,
                          child: Text("Weekly"),
                        ),
                        PopupMenuItem(
                          value: DateFilterMode.monthly,
                          child: Text("Monthly"),
                        ),
                        PopupMenuItem(
                          value: DateFilterMode.yearly,
                          child: Text("Yearly"),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _summaryColumn("EXPENSE", totalExpense, AppTheme.error),
                    _summaryColumn("INCOME", totalIncome, AppTheme.success),
                    _summaryColumn(
                      "TOTAL",
                      total,
                      total < 0 ? AppTheme.error : AppTheme.success,
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// TRANSACTION LIST (NOW INSIDE DASHBOARD)
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final tx = filtered[i];

                final isIncome = tx.type == "income";

                return ListTile(
                  leading: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? AppTheme.success : AppTheme.error,
                  ),
                  title: Text(tx.note ?? ""),
                  trailing: Text(
                    "₹${tx.amount}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// FILTER LOGIC
  List<TransactionEntity> _filterTransactions(List<TransactionEntity> all) {
    return all.where((tx) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);

      switch (filterMode) {
        case DateFilterMode.daily:
          return date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

        case DateFilterMode.weekly:
          final start = selectedDate.subtract(
            Duration(days: selectedDate.weekday - 1),
          );
          final end = start.add(const Duration(days: 6));
          return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              date.isBefore(end.add(const Duration(days: 1)));

        case DateFilterMode.monthly:
          return date.year == selectedDate.year &&
              date.month == selectedDate.month;

        case DateFilterMode.yearly:
          return date.year == selectedDate.year;
      }
    }).toList();
  }

  String _formatDate() {
    switch (filterMode) {
      case DateFilterMode.daily:
        return DateFormat("MMM d, yyyy").format(selectedDate);

      case DateFilterMode.weekly:
        final start = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));

        final startFormatted = DateFormat("MMM d").format(start);

        final endFormatted = DateFormat("MMM d").format(end);

        return "$startFormatted - $endFormatted";

      case DateFilterMode.monthly:
        return DateFormat("MMMM yyyy").format(selectedDate);

      case DateFilterMode.yearly:
        return DateFormat("yyyy").format(selectedDate);
    }
  }

  void _previousPeriod() {
    setState(() {
      selectedDate = _shiftDate(-1);
    });
  }

  void _nextPeriod() {
    setState(() {
      selectedDate = _shiftDate(1);
    });
  }

  DateTime _shiftDate(int step) {
    switch (filterMode) {
      case DateFilterMode.daily:
        return selectedDate.add(Duration(days: step));
      case DateFilterMode.weekly:
        final monday = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        return monday.add(Duration(days: 7 * step));
      case DateFilterMode.monthly:
        return DateTime(selectedDate.year, selectedDate.month + step);
      case DateFilterMode.yearly:
        return DateTime(selectedDate.year + step);
    }
  }

  Widget _summaryColumn(String title, double amount, Color color) {
    return Column(
      children: [
        const Text("", style: TextStyle(fontSize: 12, color: Colors.white70)),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
