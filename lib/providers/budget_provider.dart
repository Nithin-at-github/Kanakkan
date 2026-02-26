import 'package:flutter/material.dart';
import 'package:kanakkan/data/models/budget_model.dart';
import 'package:kanakkan/data/repositories/budget_repository.dart';
import 'package:kanakkan/domain/entities/budget_entity.dart';
import 'package:kanakkan/providers/ledger_provider.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repository = BudgetRepository();

  List<BudgetEntity> _budgets = [];
  List<BudgetEntity> get budgets => _budgets;

  int currentMonth = DateTime.now().month;
  int currentYear = DateTime.now().year;

  Future<void> loadBudgets() async {
    _budgets = await _repository.getBudgets(currentMonth, currentYear);
    notifyListeners();
  }

  Future<void> addBudget({
    required int categoryId,
    required double amount,
  }) async {
    final model = BudgetModel(
      categoryId: categoryId,
      month: currentMonth,
      year: currentYear,
      allocatedAmount: amount,
    );

    await _repository.insertBudget(model);
    await loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await _repository.deleteBudget(id);
    await loadBudgets();
  }

  /// 🔥 Derived Calculations

  double getSpentForCategory(LedgerProvider ledger, int categoryId) {
    return ledger.transactions
        .where(
          (t) =>
              t.categoryId == categoryId &&
              DateTime.fromMillisecondsSinceEpoch(t.timestamp).month ==
                  currentMonth &&
              DateTime.fromMillisecondsSinceEpoch(t.timestamp).year ==
                  currentYear,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getRemaining(LedgerProvider ledger, BudgetEntity budget) {
    final spent = getSpentForCategory(ledger, budget.categoryId);

    return budget.allocatedAmount - spent;
  }
}
