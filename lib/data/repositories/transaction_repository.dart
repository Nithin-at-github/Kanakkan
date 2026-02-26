import 'package:kanakkan/core/database/database_helper.dart';
import 'package:kanakkan/data/models/transaction_model.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await dbHelper.database;

    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await dbHelper.database;

    final result = await db.query('transactions', orderBy: 'timestamp DESC');

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<double> calculateAccountBalance(int accountId) async {
    final db = await dbHelper.database;

    final incoming = await db.rawQuery(
      '''
    SELECT SUM(amount) as total FROM transactions
    WHERE toAccountId = ?
    ''',
      [accountId],
    );

    final outgoing = await db.rawQuery(
      '''
    SELECT SUM(amount) as total FROM transactions
    WHERE fromAccountId = ?
    ''',
      [accountId],
    );

    final inAmount = (incoming.first['total'] as num?)?.toDouble() ?? 0.0;
    final outAmount = (outgoing.first['total'] as num?)?.toDouble() ?? 0.0;

    return inAmount - outAmount;
  }

  Future<List<TransactionModel>> getTransactions({String? type}) async {
    final db = await dbHelper.database;

    final result = await db.query(
      'transactions',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
      orderBy: 'timestamp DESC',
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }
}
