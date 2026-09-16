import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkan/data/services/export_service.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';

void main() {
  test('a full year of heavy transaction volume does not throw TooManyPagesException', () async {
    final categories = CategoryProvider();
    final accounts = [
      const Account(id: 1, name: 'Cash', initialBalance: 10000),
      const Account(id: 2, name: 'SIB', initialBalance: 50000),
      const Account(id: 3, name: 'AUCB', initialBalance: 20000),
    ];

    final transactions = <TransactionEntity>[];
    var id = 1;
    for (var month = 1; month <= 12; month++) {
      for (var day = 1; day <= 28; day++) {
        for (var n = 0; n < 6; n++) {
          transactions.add(
            TransactionEntity(
              id: id++,
              type: 'income',
              amount: (100 + day).toDouble(),
              toAccountId: accounts[day % 3].id,
              note: 'Income entry $month-$day-$n',
              timestamp: DateTime(2026, month, day).millisecondsSinceEpoch,
            ),
          );
          transactions.add(
            TransactionEntity(
              id: id++,
              type: 'expense',
              amount: (50 + day).toDouble(),
              fromAccountId: accounts[(day + 1) % 3].id,
              note: 'Expense entry $month-$day-$n',
              timestamp: DateTime(2026, month, day).millisecondsSinceEpoch,
            ),
          );
        }
      }
    }

    expect(transactions.length, greaterThan(4000));

    final bytes = await ExportService.instance.generatePdfBytes(
      allTransactions: transactions,
      accounts: accounts,
      categories: categories,
    );

    expect(bytes.length, greaterThan(0));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
