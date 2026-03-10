import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  Future<void> exportToCsv({
    required List<TransactionEntity> transactions,
    required LedgerProvider ledger,
    required CategoryProvider categories,
  }) async {
    final rows = <List<String>>[];
    
    // Headers
    rows.add([
      'Date',
      'Type',
      'Amount',
      'Category',
      'From Account',
      'To Account',
      'Note'
    ]);

    for (final tx in transactions) {
      final date = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(tx.timestamp),
      );
      final category = categories.resolveCategory(tx.categoryId)?.name ?? '-';
      final fromAcc = ledger.resolveAccountName(tx.fromAccountId);
      final toAcc = ledger.resolveAccountName(tx.toAccountId);
      
      rows.add([
        date,
        tx.type.toUpperCase(),
        tx.amount.toStringAsFixed(2),
        category,
        tx.fromAccountId != null ? fromAcc : '-',
        tx.toAccountId != null ? toAcc : '-',
        tx.note ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    
    final temp = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'kanakkan_export_$timestamp.csv';
    final file = File('${temp.path}/$fileName');
    
    await file.writeAsString(csvString);
    await Share.shareXFiles([XFile(file.path)], subject: 'Kanakkan Export (CSV)');
  }

  Future<void> exportToPdf({
    required List<TransactionEntity> transactions,
    required LedgerProvider ledger,
    required CategoryProvider categories,
  }) async {
    final pdf = pw.Document();

    final headers = [
      'Date',
      'Type',
      'Amount',
      'Category',
      'Account Info',
      'Note'
    ];

    final data = <List<String>>[];
    for (final tx in transactions) {
      final date = DateFormat('yyyy-MM-dd').format(
        DateTime.fromMillisecondsSinceEpoch(tx.timestamp),
      );
      final category = categories.resolveCategory(tx.categoryId)?.name ?? '-';
      
      String accountInfo = '-';
      if (tx.type == 'income') {
        accountInfo = 'To: ${ledger.resolveAccountName(tx.toAccountId)}';
      } else if (tx.type == 'expense') {
        accountInfo = 'From: ${ledger.resolveAccountName(tx.fromAccountId)}';
      } else if (tx.type == 'transfer') {
        accountInfo = '${ledger.resolveAccountName(tx.fromAccountId)} -> ${ledger.resolveAccountName(tx.toAccountId)}';
      }

      data.add([
        date,
        tx.type.toUpperCase(),
        tx.amount.toStringAsFixed(2),
        category,
        accountInfo,
        tx.note ?? '',
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Kanakkan Transactions Export', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
      ),
    );

    final temp = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'kanakkan_export_$timestamp.pdf';
    final file = File('${temp.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], subject: 'Kanakkan Export (PDF)');
  }
}
