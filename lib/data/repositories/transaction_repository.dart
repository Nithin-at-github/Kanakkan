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

  /// Returns both legs of a transfer by their shared transferGroupId.
  /// Always returns exactly 2 results for a valid transfer pair.
  Future<List<TransactionModel>> getTransactionsByGroupId(
    String groupId,
  ) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'transferGroupId = ?',
      whereArgs: [groupId],
      orderBy: 'timestamp DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<double> calculateAccountBalance(int accountId) async {
    final db = await dbHelper.database;
    final incoming = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE toAccountId = ?',
      [accountId],
    );
    final outgoing = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE fromAccountId = ?',
      [accountId],
    );
    final inAmount = (incoming.first['total'] as num?)?.toDouble() ?? 0.0;
    final outAmount = (outgoing.first['total'] as num?)?.toDouble() ?? 0.0;
    return inAmount - outAmount;
  }

  Future<void> deleteTransaction(int id) async {
    final db = await dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTransaction(TransactionModel model) async {
    final db = await dbHelper.database;
    await db.update(
      'transactions',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  /// Updates both legs of a transfer atomically inside a transaction.
  /// [expenseLeg] — the outgoing leg (type: "expense", fromAccountId set)
  /// [incomeLeg]  — the incoming leg (type: "income",  toAccountId set)
  Future<void> updateTransferLegs({
    required TransactionModel expenseLeg,
    required TransactionModel incomeLeg,
  }) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'transactions',
        expenseLeg.toMap(),
        where: 'id = ?',
        whereArgs: [expenseLeg.id],
      );
      await txn.update(
        'transactions',
        incomeLeg.toMap(),
        where: 'id = ?',
        whereArgs: [incomeLeg.id],
      );
    });
  }
}
