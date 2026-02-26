class Category {
  final int? id;
  final String title;
  final double budgetedAmount; // The 'Planned' amount from your notebook
  final bool isExpense;

  Category({
    this.id,
    required this.title,
    required this.budgetedAmount,
    this.isExpense = true,
  });

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    title: map['title'],
    budgetedAmount: map['budgeted_amount'],
    isExpense: map['is_expense'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'budgeted_amount': budgetedAmount,
    'is_expense': isExpense ? 1 : 0,
  };
}
