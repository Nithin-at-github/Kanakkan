class BudgetEntity {
  final int? id;
  final int categoryId;
  final int month;
  final int year;
  final double allocatedAmount;

  BudgetEntity({
    this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.allocatedAmount,
  });
}
