import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/budget_entity.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:kanakkan/ui/widgets/set_budget_dialog.dart';
import 'package:provider/provider.dart';

class BudgetItemCard extends StatelessWidget {
  final BudgetEntity budget;

  const BudgetItemCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    final spent = context.select<LedgerProvider, double>(
      (ledger) => ledger.getMonthlySpent(budget.categoryId),
    );

    final remaining = budget.allocatedAmount - spent;

    final progress = (spent / budget.allocatedAmount).clamp(0.0, 1.0);

    final isOverspent = remaining < 0;

    final categoryName = _getCategoryName(categoryProvider, budget.categoryId);

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
              /// ================= TITLE ROW =================
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
                    "₹${budget.allocatedAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
        
              const SizedBox(height: 10),
        
              /// ================= PROGRESS =================
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.accent.withOpacity(.2),
                  valueColor: AlwaysStoppedAnimation(
                    isOverspent ? AppTheme.error : AppTheme.success,
                  ),
                ),
              ),
        
              const SizedBox(height: 10),
        
              /// ================= VALUES =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Spent ₹${spent.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: isOverspent ? AppTheme.error : AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
        
                  Text(
                    isOverspent
                        ? "Overspent ₹${(-remaining).toStringAsFixed(0)}"
                        : "Remaining ₹${remaining.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: isOverspent ? AppTheme.error : AppTheme.success,
                      fontWeight: FontWeight.w500,
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
