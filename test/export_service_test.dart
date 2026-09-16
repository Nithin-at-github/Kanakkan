import 'package:csv/csv.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanakkan/data/services/export_service.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);
int _ms(int y, int m, int d) => _d(y, m, d).millisecondsSinceEpoch;

void main() {
  // A CategoryProvider with no categories loaded is safe to use here since
  // every test transaction has categoryId: null — resolveCategory(null)
  // never touches the (otherwise DB-backed) repository.
  final categories = CategoryProvider();

  final cash = const Account(id: 1, name: 'Cash', initialBalance: 1000);
  final bank = const Account(id: 2, name: 'Bank', initialBalance: 500);
  final accounts = [cash, bank];

  // The export must compute balances purely from the transaction ledger,
  // the same way LedgerProvider.calculateBalances() does — an account's
  // initialBalance is materialized as a real "Opening_Balance" income
  // transaction (see LedgerProvider._createOpeningBalanceTransaction), not
  // read from Account.initialBalance directly. Reproduce that here, dated
  // before the exported range, rather than relying on initialBalance alone.
  final transactions = [
    TransactionEntity(
      id: 100,
      type: 'income',
      amount: 1000,
      toAccountId: cash.id,
      note: 'Opening_Balance',
      timestamp: _ms(2025, 12, 1),
    ),
    TransactionEntity(
      id: 101,
      type: 'income',
      amount: 500,
      toAccountId: bank.id,
      note: 'Opening_Balance',
      timestamp: _ms(2025, 12, 1),
    ),
    // January
    TransactionEntity(
      id: 1,
      type: 'income',
      amount: 200,
      toAccountId: cash.id,
      note: 'Donation',
      timestamp: _ms(2026, 1, 5),
    ),
    TransactionEntity(
      id: 2,
      type: 'expense',
      amount: 150,
      fromAccountId: cash.id,
      note: 'Supplies',
      timestamp: _ms(2026, 1, 10),
    ),
    // Transfer: stored as a paired expense+income leg (matches
    // LedgerProvider.transferFunds), not a single type:'transfer' row.
    TransactionEntity(
      id: 3,
      type: 'expense',
      amount: 300,
      fromAccountId: cash.id,
      timestamp: _ms(2026, 1, 15),
      transferGroupId: 'g1',
    ),
    TransactionEntity(
      id: 4,
      type: 'income',
      amount: 300,
      toAccountId: bank.id,
      timestamp: _ms(2026, 1, 15),
      transferGroupId: 'g1',
    ),
    // February
    TransactionEntity(
      id: 5,
      type: 'income',
      amount: 100,
      toAccountId: bank.id,
      note: 'Interest',
      timestamp: _ms(2026, 2, 3),
    ),
    TransactionEntity(
      id: 6,
      type: 'expense',
      amount: 50,
      fromAccountId: bank.id,
      note: 'Fees',
      timestamp: _ms(2026, 2, 20),
    ),
  ];

  /// Parses the generated CSV into row-maps keyed by header name, grouped
  /// by the month section they belong to (split on the blank spacer rows).
  List<List<Map<String, String>>> parseSections(String csv) {
    final table = const CsvToListConverter(shouldParseNumbers: false).convert(csv);
    final header = table.first.map((e) => e.toString()).toList();

    final sections = <List<Map<String, String>>>[];
    var current = <Map<String, String>>[];
    for (final raw in table.skip(1)) {
      final isBlank = raw.every((c) => c.toString().isEmpty);
      if (isBlank) {
        if (current.isNotEmpty) sections.add(current);
        current = [];
        continue;
      }
      current.add({
        for (var i = 0; i < header.length; i++) header[i]: raw[i].toString(),
      });
    }
    if (current.isNotEmpty) sections.add(current);
    return sections;
  }

  Map<String, String>? findRow(List<Map<String, String>> section, String particulars) {
    for (final row in section) {
      if (row['Particulars'] == particulars) return row;
    }
    return null;
  }

  // Constrains the export to Jan–Feb 2026, so the December Opening_Balance
  // transactions feed the opening balance of the first month without
  // appearing as their own section — matching how a real export (e.g. "This
  // Year") behaves once an account has any transaction history before it.
  final exportRange = DateTimeRange(start: _d(2026, 1, 1), end: _d(2026, 2, 28));

  test('cash book balances across months, per account', () {
    final csv = ExportService.instance.generateCsvString(
      allTransactions: transactions,
      accounts: accounts,
      categories: categories,
      range: exportRange,
    );

    final sections = parseSections(csv);
    expect(sections.length, 2, reason: 'Jan + Feb sections');

    final jan = sections[0];
    final feb = sections[1];

    final janOpening = findRow(jan, 'Opening Balance')!;
    expect(janOpening['Date'], 'January 2026');
    expect(janOpening['Cash Receipt'], '1,000.00');
    expect(janOpening['Bank Receipt'], '500.00');

    final r1 = jan.firstWhere((r) => r['V/R No'] == 'R-1');
    expect(r1['Particulars'], 'Donation');
    expect(r1['Cash Receipt'], '200.00');

    final v1 = jan.firstWhere((r) => r['V/R No'] == 'V-1');
    expect(v1['Particulars'], 'Supplies');
    expect(v1['Cash Payment'], '150.00');

    final c1 = jan.firstWhere((r) => r['V/R No'] == 'C-1');
    expect(c1['Particulars'], 'Contra');
    expect(c1['Cash Payment'], '300.00');
    expect(c1['Bank Receipt'], '300.00');

    final janClosing = findRow(jan, 'Closing Balance')!;
    // Cash: 1000 + 200 - 150 - 300 = 750. Bank: 500 + 300 = 800.
    expect(janClosing['Cash Payment'], '750.00');
    expect(janClosing['Bank Payment'], '800.00');

    final janTotal = findRow(jan, 'Total')!;
    expect(janTotal['Cash Receipt'], janTotal['Cash Payment']);
    expect(janTotal['Bank Receipt'], janTotal['Bank Payment']);

    // February's opening balance must carry January's closing balance.
    final febOpening = findRow(feb, 'Opening Balance')!;
    expect(febOpening['Date'], 'February 2026');
    expect(febOpening['Cash Receipt'], '750.00');
    expect(febOpening['Bank Receipt'], '800.00');

    final febR1 = feb.firstWhere((r) => r['V/R No'] == 'R-1');
    expect(febR1['Particulars'], 'Interest');
    expect(febR1['Bank Receipt'], '100.00');

    final febV1 = feb.firstWhere((r) => r['V/R No'] == 'V-1');
    expect(febV1['Particulars'], 'Fees');
    expect(febV1['Bank Payment'], '50.00');

    final febClosing = findRow(feb, 'Closing Balance')!;
    // Cash unchanged at 750; Bank: 800 + 100 - 50 = 850.
    expect(febClosing['Cash Payment'], '750.00');
    expect(febClosing['Bank Payment'], '850.00');

    final febTotal = findRow(feb, 'Total')!;
    expect(febTotal['Cash Receipt'], febTotal['Cash Payment']);
    expect(febTotal['Bank Receipt'], febTotal['Bank Payment']);
  });

  test('PDF bytes generate without error and start with the PDF magic header', () async {
    final bytes = await ExportService.instance.generatePdfBytes(
      allTransactions: transactions,
      accounts: accounts,
      categories: categories,
    );
    expect(bytes.length, greaterThan(0));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
