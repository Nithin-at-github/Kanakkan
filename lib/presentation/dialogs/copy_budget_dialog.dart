import 'package:flutter/material.dart';
import 'package:kanakkan/data/models/budget_model.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/budget_provider.dart';

class CopyBudgetDialog extends StatefulWidget {
  final int currentMonth;
  final int currentYear;

  const CopyBudgetDialog({
    super.key,
    required this.currentMonth,
    required this.currentYear,
  });

  @override
  State<CopyBudgetDialog> createState() => _CopyBudgetDialogState();
}

class _CopyBudgetDialogState extends State<CopyBudgetDialog> {
  late int selectedMonth;
  late int selectedYear;

  List<BudgetModel> previousBudgets = [];
  bool loading = true;

 @override
  void initState() {
    super.initState();

    selectedMonth = widget.currentMonth - 1;
    selectedYear = widget.currentYear;

    if (selectedMonth == 0) {
      selectedMonth = 12;
      selectedYear--;
    }

    _loadBudgets();
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();

    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// TITLE
            const Text(
              "Copy budget",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Select a previous month to copy from:",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            /// MONTH SELECTOR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      selectedMonth--;
                      if (selectedMonth == 0) {
                        selectedMonth = 12;
                        selectedYear--;
                      }
                    });

                    _loadBudgets();
                  },
                ),

                Text(
                  _formatMonth(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                /// disabled forward button
                const SizedBox(width: 48),
              ],
            ),

            SizedBox(
              height: 220,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : previousBudgets.isEmpty
                  ? const Center(child: Text("No budgets found"))
                  : ListView.builder(
                      itemCount: previousBudgets.length,
                      itemBuilder: (_, i) {
                        final budget = previousBudgets[i];

                        final category = context
                            .read<CategoryProvider>()
                            .categories
                            .firstWhere((c) => c.id == budget.categoryId);

                        return ListTile(
                          leading: CircleAvatar(child: Text(category.name[0])),
                          title: Text(category.name),
                          trailing: Text(
                            "₹${budget.allocatedAmount.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            /// INFO TEXT
            Row(
              children: const [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Copying will overwrite budgets for this month.",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await budgetProvider.copyBudgetsFrom(
                        fromMonth: selectedMonth,
                        fromYear: selectedYear,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                    ),
                    child: const Text("Copy All"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonth() {
    return "${_monthName(selectedMonth)}, $selectedYear";
  }

  String _monthName(int month) {
    const names = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return names[month];
  }

  Future<void> _loadBudgets() async {
    setState(() => loading = true);

    previousBudgets = await context.read<BudgetProvider>().getBudgetsForMonth(
      selectedMonth,
      selectedYear,
    );

    setState(() => loading = false);
  }
}
