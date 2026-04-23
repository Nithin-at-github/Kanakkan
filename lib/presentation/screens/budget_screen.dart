import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/budget_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/providers/navigation_provider.dart';
import 'package:kanakkan/presentation/widgets/budget_item_card.dart';
import 'package:kanakkan/presentation/dialogs/copy_budget_dialog.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
import 'package:kanakkan/presentation/widgets/animations/animated_amount.dart';
import 'package:kanakkan/presentation/widgets/animations/pressable_scale.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late NavigationProvider _nav;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nav = context.read<NavigationProvider>();
      _nav.addListener(_onTabChanged);

      /// initial load
      _resetToCurrentMonth();

      context.read<BudgetProvider>().loadBudgets();
    });
  }

  @override
  void dispose() {
    _nav.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_nav.currentIndex == 2 && _nav.previousIndex != 2) {
      _resetToCurrentMonth();
    }
  }

  void _resetToCurrentMonth() {
    final budgetProvider = context.read<BudgetProvider>();
    final ledger = context.read<LedgerProvider>();

    final now = DateTime.now();

    budgetProvider.currentMonth = now.month;
    budgetProvider.currentYear = now.year;

    budgetProvider.loadBudgets();

    /// IMPORTANT: initialize spending cache
    ledger.rebuildMonthlyTotals(
      month: budgetProvider.currentMonth,
      year: budgetProvider.currentYear,
    );
  }

  void _updateLedgerCache(BudgetProvider provider) {
    context.read<LedgerProvider>().rebuildMonthlyTotals(
      month: provider.currentMonth,
      year: provider.currentYear,
    );
  }

  // ================= MONTH FORMAT =================

  String _formatMonth(BudgetProvider provider) {
    final date = DateTime(provider.currentYear, provider.currentMonth);

    return DateFormat("MMMM, yyyy").format(date);
  }

  void _previousMonth(BudgetProvider provider) {
    setState(() {
      provider.currentMonth--;

      if (provider.currentMonth == 0) {
        provider.currentMonth = 12;
        provider.currentYear--;
      }
    });

    provider.loadBudgets();
    _updateLedgerCache(provider);
  }

  void _nextMonth(BudgetProvider provider) {
    setState(() {
      provider.currentMonth++;

      if (provider.currentMonth == 13) {
        provider.currentMonth = 1;
        provider.currentYear++;
      }
    });

    provider.loadBudgets();
    _updateLedgerCache(provider);
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final ledgerProvider = context.watch<LedgerProvider>();

    final totalBudget = budgetProvider.budgets.fold(
      0.0,
      (sum, b) => sum + b.allocatedAmount,
    );

    double totalSpent = 0;
    for (final b in budgetProvider.budgets) {
      // Use the pre-built monthly totals cache — O(1) map lookup per category
      // instead of a full transaction scan per budget row.
      totalSpent += ledgerProvider.getMonthlySpent(b.categoryId);
    }

    return Scaffold(
      appBar: ReusableAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60), // clears the FAB
        child: Column(
          children: [
            /// ================= HEADER =================
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    "Budgets",
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  /// MONTH SELECTOR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PressableScale(
                        child: IconButton(
                          icon: Icon(Icons.arrow_left, color: AppTheme.accent),
                          onPressed: () => _previousMonth(budgetProvider),
                        ),
                      ),

                      Text(
                        _formatMonth(budgetProvider),
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      PressableScale(
                        child: IconButton(
                          icon: Icon(Icons.arrow_right, color: AppTheme.accent),
                          onPressed: () => _nextMonth(budgetProvider),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// SUMMARY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _summaryColumn(
                        "TOTAL BUDGET",
                        totalBudget,
                        AppTheme.accent,
                        delay: const Duration(milliseconds: 100),
                      ),

                      _summaryColumn(
                        "TOTAL SPENT",
                        totalSpent,
                        AppTheme.error,
                        delay: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// ================= BUDGET LIST =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.divider,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: budgetProvider.budgets.isEmpty
                  ? _emptyBudgets()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: budgetProvider.budgets.length,
                      itemBuilder: (_, i) {
                        return StaggeredEntrance(
                          index: i,
                          type: EntranceType.slideUp,
                          child: PressableScale(
                            child: BudgetItemCard(
                              budget: budgetProvider.budgets[i],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: PressableScale(
                  child: GestureDetector(
                    onTap: _openCopyDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.accent),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.divider,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 20,
                            color: AppTheme.onSurface,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Copy from previous months",
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              letterSpacing: .2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _summaryColumn(
    String title,
    double amount,
    Color color, {
    Duration delay = Duration.zero,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        AnimatedAmount(
          amount: amount,
          delay: delay,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _emptyBudgets() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          "No budgets created yet",
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _openCopyDialog() {
    final budgetProvider = context.read<BudgetProvider>();

    showDialog(
      context: context,
      builder: (_) => CopyBudgetDialog(
        currentMonth: budgetProvider.currentMonth,
        currentYear: budgetProvider.currentYear,
      ),
    );
  }
}
