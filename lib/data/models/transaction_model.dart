class TransactionEntry {
  final int? id;
  final int fromAccountId; // Source
  final int? toAccountId; // Destination (Null if it's just an expense)
  final int categoryId;
  final double amount;
  final DateTime date;
  final String note;

  TransactionEntry({
    this.id,
    required this.fromAccountId,
    this.toAccountId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory TransactionEntry.fromMap(Map<String, dynamic> map) =>
      TransactionEntry(
        id: map['id'],
        fromAccountId: map['from_account_id'],
        toAccountId: map['to_account_id'],
        categoryId: map['category_id'],
        amount: map['amount'],
        date: DateTime.parse(map['date']),
        note: map['note'] ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'from_account_id': fromAccountId,
    'to_account_id': toAccountId,
    'category_id': categoryId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
  };
}
