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
}
