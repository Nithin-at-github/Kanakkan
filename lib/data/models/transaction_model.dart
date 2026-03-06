import 'package:kanakkan/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    required super.type,
    required super.amount,
    super.fromAccountId,
    super.toAccountId,
    super.categoryId,
    super.note,
    required super.timestamp,
    super.transferGroupId,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      fromAccountId: map['fromAccountId'],
      toAccountId: map['toAccountId'],
      categoryId: map['categoryId'],
      note: map['note'],
      timestamp: map['timestamp'],
      transferGroupId: map['transferGroupId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'note': note,
      'timestamp': timestamp,
      'transferGroupId': transferGroupId,
    };
  }
}
