import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/analysis_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/widgets/transaction/transaction_detail_sheet.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';
import 'package:provider/provider.dart';

class AnalysisTransactionsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const AnalysisTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<AnalysisTransactionsScreen> createState() => _AnalysisTransactionsScreenState();
}

class _AnalysisTransactionsScreenState extends State<AnalysisTransactionsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();
    final ledger = context.watch<LedgerProvider>();
    final categories = context.watch<CategoryProvider>();

    final transactions = analysis.getTransactionsForCategory(widget.categoryId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              analysis.periodLabel,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
      body: transactions.isEmpty
          ? _buildEmptyState()
          : Scrollbar(
              controller: _scrollController,
              thickness: 6.0,
              radius: const Radius.circular(8),
              interactive: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return StaggeredEntrance(
                    index: index,
                    child: _buildTransactionItem(context, tx, ledger, categories),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No transactions found for this category.',
        style: TextStyle(color: AppTheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionEntity tx,
    LedgerProvider ledger,
    CategoryProvider categories,
  ) {
    final isIncome = tx.type == "income";
    final accountName = ledger.resolvePrimaryAccountName(tx);
    final categoryName = categories.resolveTransactionCategoryName(tx);
    final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => TransactionDetailSheet.show(context, tx: tx),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withValues(alpha: .2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isIncome ? AppTheme.success : AppTheme.error)
                      .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? AppTheme.success : AppTheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$accountName • ${DateFormat("MMM d").format(date)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "₹${formatAmt(tx.amount)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isIncome ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
