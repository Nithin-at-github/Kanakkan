import 'package:kanakkan/data/database/database_helper.dart';

class WalletSplit {
  final int categoryId;
  final double amount;
  const WalletSplit({required this.categoryId, required this.amount});
}

class TransactionWalletSplitRepository {
  final dbHelper = DatabaseHelper.instance;

  /// Records all wallet splits for a transaction.
  /// Called right after an expense is saved.
  Future<void> saveSplits({
    required int transactionId,
    required List<WalletSplit> splits,
  }) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final split in splits) {
      batch.insert('transaction_wallet_splits', {
        'transactionId': transactionId,
        'categoryId': split.categoryId,
        'amount': split.amount,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Returns all wallet splits for a transaction.
  Future<List<WalletSplit>> getSplits(int transactionId) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'transaction_wallet_splits',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
    return rows
        .map(
          (r) => WalletSplit(
            categoryId: r['categoryId'] as int,
            amount: (r['amount'] as num).toDouble(),
          ),
        )
        .toList();
  }

  /// Deletes splits for a transaction — called on delete/update.
  Future<void> deleteSplits(int transactionId) async {
    final db = await dbHelper.database;
    await db.delete(
      'transaction_wallet_splits',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
  }
}
