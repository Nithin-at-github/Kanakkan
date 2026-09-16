import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:kanakkan/core/utils/safe_iterable.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

/// One printable row of a Receipts & Payments cash book. Amounts are keyed
/// by account id; an account missing from [receipts]/[payments] renders as
/// a blank cell for that row (not a zero).
class _CashBookRow {
  final String date;
  final String vrNo;
  final String particulars;
  final Map<int, double> receipts;
  final Map<int, double> payments;
  final bool isSectionRow;
  final bool isTotalRow;

  _CashBookRow({
    required this.date,
    required this.vrNo,
    required this.particulars,
    Map<int, double>? receipts,
    Map<int, double>? payments,
    this.isSectionRow = false,
    this.isTotalRow = false,
  }) : receipts = receipts ?? const {},
       payments = payments ?? const {};
}

class _MonthSection {
  final String label;
  final List<_CashBookRow> rows;
  _MonthSection({required this.label, required this.rows});
}

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  // ─────────────────────────────────────────────────────────────────────
  // SHARED CASH-BOOK BUILDER
  // ─────────────────────────────────────────────────────────────────────

  DateTimeRange _effectiveRange(
    List<TransactionEntity> allTransactions,
    DateTimeRange? range,
  ) {
    if (range != null) return range;
    if (allTransactions.isEmpty) {
      final now = DateTime.now();
      return DateTimeRange(start: now, end: now);
    }
    final sorted = [...allTransactions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return DateTimeRange(
      start: DateTime.fromMillisecondsSinceEpoch(sorted.first.timestamp),
      end: DateTime.fromMillisecondsSinceEpoch(sorted.last.timestamp),
    );
  }

  String _particulars(String? note, String? categoryName) {
    final n = note?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (categoryName != null && categoryName.isNotEmpty) return categoryName;
    return '-';
  }

  List<_MonthSection> _buildCashBook({
    required List<TransactionEntity> allTransactions,
    required List<Account> accounts,
    required CategoryProvider categories,
    required DateTimeRange range,
  }) {
    final accountIds = accounts.map((a) => a.id!).toSet();
    final sorted = [...allTransactions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final rangeStartMs = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    ).millisecondsSinceEpoch;
    final rangeEndMs = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;

    // Running balance per account, purely from the transaction ledger —
    // matches LedgerProvider.calculateBalances() (SUM(credits) - SUM(debits),
    // no separate use of Account.initialBalance). An account's initial
    // balance is itself stored as a real transaction (note: "Opening_Balance",
    // see LedgerProvider._createOpeningBalanceTransaction), so seeding this
    // map with account.initialBalance as well would double-count it.
    final balances = <int, double>{for (final a in accounts) a.id!: 0.0};
    for (final tx in sorted) {
      if (tx.timestamp >= rangeStartMs) break;
      if (tx.toAccountId != null && accountIds.contains(tx.toAccountId)) {
        balances[tx.toAccountId!] = (balances[tx.toAccountId!] ?? 0) + tx.amount;
      }
      if (tx.fromAccountId != null && accountIds.contains(tx.fromAccountId)) {
        balances[tx.fromAccountId!] = (balances[tx.fromAccountId!] ?? 0) - tx.amount;
      }
    }

    final inRange = sorted
        .where((t) => t.timestamp >= rangeStartMs && t.timestamp <= rangeEndMs)
        .toList();

    // Bucket in-range transactions by calendar month, oldest first.
    final monthKeys = <String>[];
    final byMonth = <String, List<TransactionEntity>>{};
    for (final tx in inRange) {
      final d = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final bucket = byMonth.putIfAbsent(key, () {
        monthKeys.add(key);
        return [];
      });
      bucket.add(tx);
    }
    monthKeys.sort();

    final sections = <_MonthSection>[];

    for (final key in monthKeys) {
      final txs = byMonth[key]!;
      final first = DateTime.fromMillisecondsSinceEpoch(txs.first.timestamp);
      final monthLabel = DateFormat('MMMM yyyy').format(DateTime(first.year, first.month));

      final opening = Map<int, double>.from(balances);
      final rows = <_CashBookRow>[];

      final openingReceipts = <int, double>{};
      final openingPayments = <int, double>{};
      for (final a in accounts) {
        final bal = opening[a.id!] ?? 0;
        if (bal >= 0) {
          openingReceipts[a.id!] = bal;
        } else {
          openingPayments[a.id!] = -bal;
        }
      }
      rows.add(
        _CashBookRow(
          date: monthLabel,
          vrNo: '',
          particulars: 'Opening Balance',
          receipts: openingReceipts,
          payments: openingPayments,
          isSectionRow: true,
        ),
      );

      final monthReceiptTotal = <int, double>{};
      final monthPaymentTotal = <int, double>{};

      int receiptCounter = 0;
      int voucherCounter = 0;
      int contraCounter = 0;
      final handledTransferIds = <int>{};

      for (final tx in txs) {
        if (tx.id != null && handledTransferIds.contains(tx.id)) continue;

        final date = DateFormat('dd-MM-yyyy').format(
          DateTime.fromMillisecondsSinceEpoch(tx.timestamp),
        );

        // Transfers are stored as a paired expense+income leg sharing a
        // transferGroupId (see LedgerProvider.transferFunds) — never as a
        // single tx.type == 'transfer' row. Render the pair as one contra row.
        if (tx.transferGroupId != null) {
          final pair = txs.firstWhereOrNull(
            (t) => t.transferGroupId == tx.transferGroupId && t.id != tx.id,
          );
          if (tx.id != null) handledTransferIds.add(tx.id!);
          if (pair?.id != null) handledTransferIds.add(pair!.id!);

          final expenseLeg = tx.type == 'expense' ? tx : pair;
          final incomeLeg = tx.type == 'income' ? tx : pair;
          if (expenseLeg == null || incomeLeg == null) continue;

          final fromId = expenseLeg.fromAccountId;
          final toId = incomeLeg.toAccountId;
          if (fromId == null ||
              toId == null ||
              !accountIds.contains(fromId) ||
              !accountIds.contains(toId)) {
            continue;
          }

          contraCounter++;
          final contraNote = (tx.note ?? incomeLeg.note)?.trim();
          rows.add(
            _CashBookRow(
              date: date,
              vrNo: 'C-$contraCounter',
              particulars: (contraNote != null && contraNote.isNotEmpty) ? contraNote : 'Contra',
              payments: {fromId: expenseLeg.amount},
              receipts: {toId: incomeLeg.amount},
            ),
          );
          monthPaymentTotal[fromId] = (monthPaymentTotal[fromId] ?? 0) + expenseLeg.amount;
          monthReceiptTotal[toId] = (monthReceiptTotal[toId] ?? 0) + incomeLeg.amount;
          continue;
        }

        final particulars = _particulars(
          tx.note,
          categories.resolveCategory(tx.categoryId)?.name,
        );

        if (tx.type == 'income') {
          final toId = tx.toAccountId;
          if (toId == null || !accountIds.contains(toId)) continue;
          receiptCounter++;
          rows.add(
            _CashBookRow(
              date: date,
              vrNo: 'R-$receiptCounter',
              particulars: particulars,
              receipts: {toId: tx.amount},
            ),
          );
          monthReceiptTotal[toId] = (monthReceiptTotal[toId] ?? 0) + tx.amount;
        } else if (tx.type == 'expense') {
          final fromId = tx.fromAccountId;
          if (fromId == null || !accountIds.contains(fromId)) continue;
          voucherCounter++;
          rows.add(
            _CashBookRow(
              date: date,
              vrNo: 'V-$voucherCounter',
              particulars: particulars,
              payments: {fromId: tx.amount},
            ),
          );
          monthPaymentTotal[fromId] = (monthPaymentTotal[fromId] ?? 0) + tx.amount;
        }
      }

      final closing = <int, double>{};
      for (final a in accounts) {
        final id = a.id!;
        final delta = (monthReceiptTotal[id] ?? 0) - (monthPaymentTotal[id] ?? 0);
        final newBal = (opening[id] ?? 0) + delta;
        closing[id] = newBal;
        balances[id] = newBal;
      }

      final closingReceipts = <int, double>{};
      final closingPayments = <int, double>{};
      for (final a in accounts) {
        final bal = closing[a.id!] ?? 0;
        if (bal >= 0) {
          closingPayments[a.id!] = bal;
        } else {
          closingReceipts[a.id!] = -bal;
        }
      }
      rows.add(
        _CashBookRow(
          date: '',
          vrNo: '',
          particulars: 'Closing Balance',
          receipts: closingReceipts,
          payments: closingPayments,
          isSectionRow: true,
        ),
      );

      final totalReceipts = <int, double>{};
      final totalPayments = <int, double>{};
      for (final a in accounts) {
        final id = a.id!;
        totalReceipts[id] =
            (openingReceipts[id] ?? 0) + (monthReceiptTotal[id] ?? 0) + (closingReceipts[id] ?? 0);
        totalPayments[id] =
            (openingPayments[id] ?? 0) + (monthPaymentTotal[id] ?? 0) + (closingPayments[id] ?? 0);
      }
      rows.add(
        _CashBookRow(
          date: '',
          vrNo: '',
          particulars: 'Total',
          receipts: totalReceipts,
          payments: totalPayments,
          isSectionRow: true,
          isTotalRow: true,
        ),
      );

      sections.add(_MonthSection(label: monthLabel, rows: rows));
    }

    return sections;
  }

  Future<File> _writeToTempFile(String fileName, Uint8List bytes) async {
    final temp = await getTemporaryDirectory();
    final file = File('${temp.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _deliver({
    required File file,
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    required String shareSubject,
    required bool saveToStorage,
  }) async {
    if (saveToStorage) {
      await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        bytes: bytes,
        type: FileType.any,
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: shareSubject),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // CSV
  // ─────────────────────────────────────────────────────────────────────

  /// Pure CSV-string generation, with no file I/O — see [generatePdfBytes].
  String generateCsvString({
    required List<TransactionEntity> allTransactions,
    required List<Account> accounts,
    required CategoryProvider categories,
    DateTimeRange? range,
  }) {
    final effectiveRange = _effectiveRange(allTransactions, range);
    final sections = _buildCashBook(
      allTransactions: allTransactions,
      accounts: accounts,
      categories: categories,
      range: effectiveRange,
    );

    final currency = NumberFormat('#,##0.00');
    final header = <String>['Date', 'V/R No', 'Particulars'];
    for (final a in accounts) {
      header.add('${a.name} Receipt');
      header.add('${a.name} Payment');
    }

    final rows = <List<String>>[header];

    for (final section in sections) {
      for (final row in section.rows) {
        final line = <String>[row.date, row.vrNo, row.particulars];
        for (final a in accounts) {
          final r = row.receipts[a.id];
          final p = row.payments[a.id];
          line.add(r != null ? currency.format(r) : '');
          line.add(p != null ? currency.format(p) : '');
        }
        rows.add(line);
      }
      rows.add(List.filled(header.length, ''));
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<void> exportToCsv({
    required List<TransactionEntity> allTransactions,
    required List<Account> accounts,
    required CategoryProvider categories,
    DateTimeRange? range,
    bool saveToStorage = false,
  }) async {
    final csvString = generateCsvString(
      allTransactions: allTransactions,
      accounts: accounts,
      categories: categories,
      range: range,
    );
    final csvBytes = Uint8List.fromList(csvString.codeUnits);

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'kanakkan_cashbook_$timestamp.csv';
    final file = await _writeToTempFile(fileName, csvBytes);

    await _deliver(
      file: file,
      bytes: csvBytes,
      fileName: fileName,
      dialogTitle: 'Save CSV Export',
      shareSubject: 'Kanakkan Cash Book (CSV)',
      saveToStorage: saveToStorage,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // PDF
  // ─────────────────────────────────────────────────────────────────────

  /// Pure PDF-bytes generation, with no file I/O — exposed so tests can
  /// verify the rendered cash book without needing real plugin bindings
  /// for path_provider/file_picker/share_plus.
  Future<Uint8List> generatePdfBytes({
    required List<TransactionEntity> allTransactions,
    required List<Account> accounts,
    required CategoryProvider categories,
    DateTimeRange? range,
  }) async {
    final effectiveRange = _effectiveRange(allTransactions, range);
    final sections = _buildCashBook(
      allTransactions: allTransactions,
      accounts: accounts,
      categories: categories,
      range: effectiveRange,
    );
    return _buildCashBookPdf(sections, accounts);
  }

  Future<void> exportToPdf({
    required List<TransactionEntity> allTransactions,
    required List<Account> accounts,
    required CategoryProvider categories,
    DateTimeRange? range,
    bool saveToStorage = false,
  }) async {
    final pdfBytes = await generatePdfBytes(
      allTransactions: allTransactions,
      accounts: accounts,
      categories: categories,
      range: range,
    );

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'kanakkan_cashbook_$timestamp.pdf';
    final file = await _writeToTempFile(fileName, pdfBytes);

    await _deliver(
      file: file,
      bytes: pdfBytes,
      fileName: fileName,
      dialogTitle: 'Save PDF Export',
      shareSubject: 'Kanakkan Cash Book (PDF)',
      saveToStorage: saveToStorage,
    );
  }

  Future<Uint8List> _buildCashBookPdf(
    List<_MonthSection> sections,
    List<Account> accounts,
  ) async {
    final pdf = pw.Document();
    final currency = NumberFormat('#,##0.00');

    const pageFormat = PdfPageFormat.a4;
    final landscape = pageFormat.landscape;
    const margin = 24.0;
    final usableWidth = landscape.width - margin * 2;

    const dateW = 65.0;
    const vrW = 45.0;
    const particularsW = 150.0;
    final fixedW = dateW + vrW + particularsW;
    final remaining = (usableWidth - fixedW).clamp(0, double.infinity);
    final subColW = accounts.isEmpty ? 0.0 : remaining / (accounts.length * 2);

    final fontSize = subColW >= 70
        ? 9.0
        : subColW >= 50
        ? 8.0
        : subColW >= 35
        ? 7.0
        : 6.0;

    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(dateW),
      1: const pw.FixedColumnWidth(vrW),
      2: const pw.FixedColumnWidth(particularsW),
    };
    for (var i = 0; i < accounts.length * 2; i++) {
      colWidths[3 + i] = pw.FixedColumnWidth(subColW);
    }

    pw.TextStyle style({bool bold = false, PdfColor? color}) => pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? PdfColors.black,
    );

    pw.Widget cell(
      String text, {
      bool bold = false,
      PdfColor? color,
      pw.Alignment align = pw.Alignment.centerLeft,
    }) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        alignment: align,
        child: pw.Text(text, style: style(bold: bold, color: color)),
      );
    }

    pw.TableRow groupHeaderRow() {
      final cells = <pw.Widget>[
        pw.Container(color: PdfColors.indigo, child: cell('', align: pw.Alignment.center)),
        pw.Container(color: PdfColors.indigo, child: cell('', align: pw.Alignment.center)),
        pw.Container(color: PdfColors.indigo, child: cell('', align: pw.Alignment.center)),
      ];
      for (final a in accounts) {
        cells.add(
          pw.Container(
            color: PdfColors.indigo800,
            child: cell(
              a.name,
              bold: true,
              color: PdfColors.white,
              align: pw.Alignment.center,
            ),
          ),
        );
        cells.add(pw.Container(color: PdfColors.indigo800));
      }
      return pw.TableRow(children: cells);
    }

    pw.TableRow columnHeaderRow() {
      final cells = <pw.Widget>[
        pw.Container(
          color: PdfColors.indigo,
          child: cell('Date', bold: true, color: PdfColors.white, align: pw.Alignment.centerLeft),
        ),
        pw.Container(
          color: PdfColors.indigo,
          child: cell('V/R no', bold: true, color: PdfColors.white, align: pw.Alignment.center),
        ),
        pw.Container(
          color: PdfColors.indigo,
          child: cell('Particulars', bold: true, color: PdfColors.white, align: pw.Alignment.centerLeft),
        ),
      ];
      for (var i = 0; i < accounts.length; i++) {
        cells.add(
          pw.Container(
            color: PdfColors.indigo,
            child: cell('Receipt', bold: true, color: PdfColors.white, align: pw.Alignment.center),
          ),
        );
        cells.add(
          pw.Container(
            color: PdfColors.indigo,
            child: cell('Payment', bold: true, color: PdfColors.white, align: pw.Alignment.center),
          ),
        );
      }
      return pw.TableRow(children: cells);
    }

    pw.TableRow dataRow(_CashBookRow row) {
      final bg = row.isSectionRow ? PdfColors.grey200 : null;
      final cells = <pw.Widget>[
        pw.Container(color: bg, child: cell(row.date, bold: row.isSectionRow)),
        pw.Container(color: bg, child: cell(row.vrNo, bold: row.isSectionRow, align: pw.Alignment.center)),
        pw.Container(color: bg, child: cell(row.particulars, bold: row.isSectionRow)),
      ];
      for (final a in accounts) {
        final r = row.receipts[a.id];
        final p = row.payments[a.id];
        cells.add(
          pw.Container(
            color: bg,
            child: cell(
              r != null ? currency.format(r) : '',
              bold: row.isSectionRow,
              align: pw.Alignment.centerRight,
            ),
          ),
        );
        cells.add(
          pw.Container(
            color: bg,
            child: cell(
              p != null ? currency.format(p) : '',
              bold: row.isSectionRow,
              align: pw.Alignment.centerRight,
            ),
          ),
        );
      }
      return pw.TableRow(children: cells);
    }

    // One pw.Table per month, not one giant table for the whole export.
    // pw.MultiPage caps how many pages a single continuously-spanning widget
    // may consume (TooManyPagesException, default limit 20) — a full year of
    // transactions in one table can blow past that. Splitting per month also
    // means the header repeats above every month, which helps readability
    // since long tables don't otherwise repeat their header across pages.
    final content = <pw.Widget>[
      pw.Text(
        'Kanakkan Cash Book',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 12),
    ];
    for (final section in sections) {
      final rows = <pw.TableRow>[groupHeaderRow(), columnHeaderRow()];
      for (final row in section.rows) {
        rows.add(dataRow(row));
      }
      content.add(
        pw.Table(
          columnWidths: colWidths,
          border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
          children: rows,
        ),
      );
      content.add(pw.SizedBox(height: 16));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: landscape,
        margin: const pw.EdgeInsets.all(margin),
        // Defensive ceiling in case a single month is itself huge; the
        // per-month split above is the real fix for a full-year export.
        maxPages: 200,
        build: (pw.Context context) => content,
      ),
    );

    return await pdf.save();
  }
}
