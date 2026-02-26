import 'package:kanakkan/domain/entities/budget_entity.dart';

class BudgetModel extends BudgetEntity {
  BudgetModel({
    super.id,
    required super.categoryId,
    required super.month,
    required super.year,
    required super.allocatedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "categoryId": categoryId,
      "month": month,
      "year": year,
      "allocatedAmount": allocatedAmount,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map["id"],
      categoryId: map["categoryId"],
      month: map["month"],
      year: map["year"],
      allocatedAmount: map["allocatedAmount"],
    );
  }
}
