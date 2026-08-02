import 'package:kanakkan/data/database/database_helper.dart';
import 'package:kanakkan/data/models/transaction_model.dart';
import 'package:kanakkan/domain/entities/lend_person.dart';

class LendRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertPerson(LendPerson person) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'lend_people',
      person.toMap(),
    );
  }

  Future<List<({LendPerson person, double balance})>> getAllPeopleWithBalances() async {
    final db = await _dbHelper.database;

    // Calculate net balance for each person:
    // Outgoing (expense) transactions count as positive (debtor owes us).
    // Incoming (income) transactions count as negative (we received repayment, or we borrowed).
    final result = await db.rawQuery('''
      SELECT 
        p.id,
        p.name,
        p.phoneNumber,
        p.createdAt,
        COALESCE(SUM(CASE WHEN t.type = 'expense' THEN t.amount ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN t.type = 'income' THEN t.amount ELSE 0 END), 0) AS balance
      FROM lend_people p
      LEFT JOIN transactions t ON p.id = t.lendPersonId
      GROUP BY p.id
      ORDER BY p.name ASC
    ''');

    return result.map((row) {
      final person = LendPerson(
        id: row['id'] as int?,
        name: row['name'] as String,
        phoneNumber: row['phoneNumber'] as String?,
        createdAt: row['createdAt'] as int,
      );
      final balance = (row['balance'] as num).toDouble();
      return (person: person, balance: balance);
    }).toList();
  }

  Future<void> updatePerson(LendPerson person) async {
    final db = await _dbHelper.database;
    await db.update(
      'lend_people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<void> deletePerson(int id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Unlink all transactions linked to this person, keeping their financial records intact
      await txn.update(
        'transactions',
        {'lendPersonId': null},
        where: 'lendPersonId = ?',
        whereArgs: [id],
      );
      // Delete the person
      await txn.delete(
        'lend_people',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<TransactionModel>> getTransactionsForPerson(int personId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'transactions',
      where: 'lendPersonId = ?',
      whereArgs: [personId],
      orderBy: 'timestamp DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> linkTransactionsToPerson(int personId, List<int> transactionIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final txId in transactionIds) {
        await txn.update(
          'transactions',
          {'lendPersonId': personId},
          where: 'id = ?',
          whereArgs: [txId],
        );
      }
    });
  }
}
