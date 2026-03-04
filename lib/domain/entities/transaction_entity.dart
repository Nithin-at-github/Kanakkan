class TransactionEntity {
  final int? id;
  final String type;
  final double amount;
  final int? fromAccountId;
  final int? toAccountId;
  final int? categoryId;
  final String? note;
  final int timestamp;

  const TransactionEntity({
    this.id,
    required this.type,
    required this.amount,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    required this.timestamp,
  });

  TransactionEntity copyWith({
    int? id,
    String? type,
    double? amount,
    int? fromAccountId,
    int? toAccountId,
    int? categoryId,
    String? note,
    int? timestamp,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
