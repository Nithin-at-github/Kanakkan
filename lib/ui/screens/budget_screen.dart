import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/providers/budget_provider.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final ledger = context.watch<LedgerProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          "Monthly Budget",
          style: TextStyle(color: AppTheme.accent),
        ),
      ),
      body: ListView.builder(
        itemCount: budgetProvider.budgets.length,
        itemBuilder: (context, index) {
          final budget = budgetProvider.budgets[index];

          final spent = budgetProvider.getSpentForCategory(
            ledger,
            budget.categoryId,
          );

          final remaining = budget.allocatedAmount - spent;

          final progress = spent / budget.allocatedAmount;

          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category ID: ${budget.categoryId}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(
                    value: progress > 1 ? 1 : progress,
                    backgroundColor: Colors.grey.shade200,
                    color: remaining < 0 ? AppTheme.error : AppTheme.success,
                  ),

                  const SizedBox(height: 8),

                  Text("₹$spent / ₹${budget.allocatedAmount}"),
                  Text("Remaining: ₹$remaining"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
