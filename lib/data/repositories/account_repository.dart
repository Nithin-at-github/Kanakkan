import 'package:kanakkan/data/database/database_helper.dart';
import 'package:kanakkan/data/models/account_model.dart';

class AccountRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertAccount(AccountModel account) async {
    final db = await dbHelper.database;

    return await db.insert('accounts', account.toMap());
  }

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await dbHelper.database;

    final result = await db.query('accounts');

    return result.map((e) => AccountModel.fromMap(e)).toList();
  }

  Future<void> updateAccount(AccountModel model) async {
    final db = await dbHelper.database;

    await db.update(
      'accounts',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> deleteAccount(int id) async {
    final db = await dbHelper.database;

    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
