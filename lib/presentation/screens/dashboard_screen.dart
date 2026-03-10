import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/data/models/salary_trigger.dart';
import 'package:kanakkan/presentation/dialogs/salary_split_dialog.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
import 'package:kanakkan/presentation/widgets/transaction/transaction_detail_sheet.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
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

  void _openSalarySplitDialog(SalaryTrigger trigger) {
    // Use the flag-based getter — no hardcoded name lookup
    final salaryCategoryId = context
        .read<CategoryProvider>()
        .getSalaryCategoryId();

    // Guard: salary wallet may have been cleared since the trigger fired
    if (salaryCategoryId == null) return;

    showDialog(
      context: context,
      builder: (_) => SalarySplitDialog(
        salaryAmount: trigger.amount,
        salaryCategoryId: salaryCategoryId,
        salaryTransactionId: trigger.transactionId,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final ledger = context.read<LedgerProvider>();

    ledger.salaryIncomeTrigger.addListener(() {
      final trigger = ledger.consumeSalaryTrigger();
      if (trigger != null) {
        _openSalarySplitDialog(trigger);
      }
    });

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
    // Hoist these reads above the ListView so they are not repeated per item.
    final categoryProvider = context.read<CategoryProvider>();

    final filtered = _filterTransactions(provider.transactions);

    final totalExpense = filtered
        .where((e) => e.type == "expense")
        .fold(0.0, (sum, e) => sum + e.amount);

    final totalIncome = filtered
        .where((e) => e.type == "income")
        .fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const ReusableAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ================= HEADER =================
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  /// DATE SELECTOR
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

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryColumn("EXPENSE", totalExpense, AppTheme.error),
                      _summaryColumn("INCOME", totalIncome, AppTheme.success),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// ================= TRANSACTION BOX =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              child: filtered.isEmpty
                  ? _emptyTransactions()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final tx = filtered[i];
                        // Use the already-read providers hoisted above —
                        // no per-item context.read needed.
                        final isIncome = tx.type == "income";
                        final accountName = provider.resolvePrimaryAccountName(
                          tx,
                        );
                        final categoryName = categoryProvider
                            .resolveTransactionCategoryName(tx);
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          tx.timestamp,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showTransactionDetails(tx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: .25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  /// ICON
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          (isIncome
                                                  ? AppTheme.success
                                                  : AppTheme.error)
                                              .withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: isIncome
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  /// DETAILS
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$accountName • ${DateFormat("MMM d").format(date)}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// AMOUNT
                                  Text(
                                    "₹${formatAmt(tx.amount)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isIncome
                                          ? AppTheme.success
                                          : AppTheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

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
        return "${DateFormat("MMM d").format(start)} - ${DateFormat("MMM d").format(end)}";
      case DateFilterMode.monthly:
        return DateFormat("MMMM yyyy").format(selectedDate);
      case DateFilterMode.yearly:
        return DateFormat("yyyy").format(selectedDate);
    }
  }

  void _previousPeriod() => setState(() => selectedDate = _shiftDate(-1));
  void _nextPeriod() => setState(() => selectedDate = _shiftDate(1));

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

  Widget _emptyTransactions() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          "No transactions yet",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _summaryColumn(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          "₹${formatAmt(amount)}",
          style: TextStyle(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showTransactionDetails(TransactionEntity tx) {
    TransactionDetailSheet.show(context, tx: tx);
  }
}
