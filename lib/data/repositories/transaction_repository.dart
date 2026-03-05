import 'package:kanakkan/data/database/database_helper.dart';
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

  Future<void> deleteTransaction(int id) async {
    final db = await dbHelper.database;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTransaction(TransactionModel model) async {
    final db = await dbHelper.database;

    await db.update(
      "transactions",
      model.toMap(),
      where: "id = ?",
      whereArgs: [model.id],
    );
  }
}
