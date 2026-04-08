import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/budget_entity.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/dialogs/set_budget_dialog.dart';
import 'package:provider/provider.dart';

class BudgetItemCard extends StatelessWidget {
  final BudgetEntity budget;

  const BudgetItemCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    /// Wallet Balance (REAL MONEY)
    final balance = context.select<CategoryBalanceProvider, double>(
      (p) => p.getBalance(budget.categoryId),
    );

    final categoryProvider = context.watch<CategoryProvider>();

    /// monthly spending
    final spent = context.select<LedgerProvider, double>(
      (ledger) => ledger.getMonthlySpent(budget.categoryId),
    );

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
      progressColor = AppTheme.warning;
    } else {
      progressColor = AppTheme.success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showSetBudgetDialog(context, existingBudget: budget),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withValues(alpha: .25)),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),

                  Text(
                    "Limit ₹${formatAmt(budget.allocatedAmount, decimals: false)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),

              /// ================= AVAILABLE (PRIMARY VALUE) =================
              Text(
                "Spent ₹${formatAmt(spent, decimals: false)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOverspent ? AppTheme.error : AppTheme.success,
                ),
              ),

              /// ================= PROGRESS =================
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: AppTheme.accent.withValues(alpha: .2),
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// ================= DETAILS =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverspent
                        ? "Overspent ₹${formatAmt(spent - budget.allocatedAmount, decimals: false)}"
                        : "Remaining ₹${formatAmt(budget.allocatedAmount - spent, decimals: false)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isOverspent ? AppTheme.error : AppTheme.onSurface,
                    ),
                  ),

                  Text(
                    "Wallet ₹${formatAmt(balance, decimals: false)}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
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
