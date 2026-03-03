import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:kanakkan/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';
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
                      _summaryColumn(
                        "BALANCE",
                        total,
                        total < 0 ? AppTheme.error : AppTheme.success,
                      ),
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
                      shrinkWrap: true, // ⭐ CONTENT HEIGHT
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final tx = filtered[i];

                        final ledger = context.read<LedgerProvider>();

                        final categoryProvider = context
                            .read<CategoryProvider>();

                        final isIncome = tx.type == "income";

                        final accountName = _getAccountName(
                          ledger,
                          tx.type == "income"
                              ? tx.toAccountId
                              : tx.fromAccountId,
                        );

                        final categoryName = _getCategoryName(
                          categoryProvider,
                          tx.categoryId,
                        );

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
                                  color: AppTheme.accent.withOpacity(.25),
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
                                              .withOpacity(.12),
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
                                    "₹${tx.amount.toStringAsFixed(2)}",
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

            const SizedBox(height: 90), // FAB spacing
          ],
        ),
      ),
    );
  }

 String _getAccountName(LedgerProvider ledger, int? id) {
    if (id == null) return "-";

    try {
      return ledger.accounts.firstWhere((a) => a.id == id).name;
    } catch (_) {
      return "-";
    }
  }

  String _getCategoryName(CategoryProvider categories, int? id) {
    if (id == null) return "-";

    try {
      return categories.categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return "-";
    }
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

  void _showTransactionDetails(TransactionEntity tx) {
    final ledger = context.read<LedgerProvider>();
    final categories = context.read<CategoryProvider>();

    final isIncome = tx.type == "income";

    final accountName = _getAccountName(
      ledger,
      isIncome ? tx.toAccountId : tx.fromAccountId,
    );

    final categoryName = _getCategoryName(categories, tx.categoryId);

    final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// DRAG HANDLE
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              /// CLOSE BUTTON
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              /// CATEGORY TITLE
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 8),

              /// AMOUNT
              Text(
                "₹${tx.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppTheme.success : AppTheme.error,
                ),
              ),

              const SizedBox(height: 10),

              /// TYPE BADGE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isIncome ? AppTheme.success : AppTheme.error)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isIncome ? "INCOME" : "EXPENSE",
                  style: TextStyle(
                    color: isIncome ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// DETAILS SECTION
              _detailRow("Account", accountName),
              _detailRow("Date", DateFormat("MMM d, yyyy").format(date)),
              _detailRow("Time", DateFormat("hh:mm a").format(date)),

              if (tx.note != null && tx.note!.trim().isNotEmpty)
                _detailRow("Note", tx.note!),

              const SizedBox(height: 24),

              /// ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _iconActionButton(
                    icon: Icons.edit,
                    color: AppTheme.accent,
                    onTap: () {
                      Navigator.pop(context);
                      _editTransaction(tx);
                    },
                  ),

                  _iconActionButton(
                    icon: Icons.delete,
                    color: AppTheme.error,
                    onTap: () async {
                      await ledger.deleteTransaction(tx.id!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Transaction deleted")),
                        );
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  void _editTransaction(TransactionEntity tx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionScreen(transaction: tx)),
    );
  }

}