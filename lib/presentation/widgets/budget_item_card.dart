import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/budget_entity.dart';
import 'package:kanakkan/providers/category_balance_provider.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/widgets/set_budget_dialog.dart';
import 'package:provider/provider.dart';

class BudgetItemCard extends StatelessWidget {
  final BudgetEntity budget;

  const BudgetItemCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    /// ENVELOPE BALANCE (REAL MONEY)
    final balance = context.select<CategoryBalanceProvider, double>(
      (p) => p.getBalance(budget.categoryId),
    );

    final categoryProvider = context.watch<CategoryProvider>();

    /// monthly spending
    final spent = context.select<LedgerProvider, double>(
      (ledger) => ledger.getMonthlySpent(budget.categoryId),
    );

    /// available after spending
    final available = balance - spent;

    /// progress shows how much of the allocated budget has been spent
    final progress = budget.allocatedAmount <= 0
        ? 0.0
        : (spent / budget.allocatedAmount).clamp(0.0, 1.0);

    /// overspent means exceeded the allocated budget
    final isOverspent = spent > budget.allocatedAmount;

    final categoryName = _getCategoryName(categoryProvider, budget.categoryId);

    /// progress color intelligence
    Color progressColor;
    if (isOverspent) {
      progressColor = AppTheme.error;
    } else if (progress > 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = AppTheme.success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => SetBudgetDialog(existingBudget: budget),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withOpacity(.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= TITLE =================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),

                  Text(
                    "Limit ₹${budget.allocatedAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),

              /// ================= AVAILABLE (PRIMARY VALUE) =================
              Text(
                "Spent ₹${spent.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOverspent ? AppTheme.error : AppTheme.success,
                ),
              ),

              /// ================= PROGRESS =================
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.accent.withOpacity(.2),
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),

              const SizedBox(height: 10),

              /// ================= DETAILS =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverspent
                        ? "Overspent ₹${(spent - budget.allocatedAmount).toStringAsFixed(0)}"
                        : "Remaining ₹${(budget.allocatedAmount - spent).toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isOverspent ? AppTheme.error : Colors.black87,
                    ),
                  ),

                  Text(
                    "Wallet ₹${balance.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryName(CategoryProvider categories, int id) {
    try {
      return categories.categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return "Category";
    }
  }
}
