import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';
import 'package:kanakkan/data/repositories/transaction_wallet_split_repository.dart';
import 'package:kanakkan/domain/entities/transaction_entity.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';
import 'package:provider/provider.dart';

/// Drop-in replacement for the inline sheet in DashboardScreen.
///
/// Usage:
/// ```dart
/// void _showTransactionDetails(TransactionEntity tx) {
///   TransactionDetailSheet.show(context, tx: tx);
/// }
/// ```
class TransactionDetailSheet {
  static void show(BuildContext context, {required TransactionEntity tx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheetContent(tx: tx),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatefulWidget so the wallet split future is stored in state — not
// recreated on every rebuild. This eliminates the flicker/trembling.
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionDetailSheetContent extends StatefulWidget {
  final TransactionEntity tx;
  const _TransactionDetailSheetContent({required this.tx});

  @override
  State<_TransactionDetailSheetContent> createState() =>
      _TransactionDetailSheetContentState();
}

class _TransactionDetailSheetContentState
    extends State<_TransactionDetailSheetContent> {
  late final Future<List<WalletSplit>> _splitsFuture;

  bool get _isExpense =>
      widget.tx.type == "expense" && widget.tx.transferGroupId == null;
  bool get _isIncome => widget.tx.type == "income";
  bool get _isTransfer => widget.tx.transferGroupId != null;

  @override
  void initState() {
    super.initState();
    // Fetch once and store — never re-fetched on rebuild
    _splitsFuture = _isExpense && widget.tx.id != null
        ? context.read<LedgerProvider>().getWalletSplits(widget.tx.id!)
        : Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    final ledger = context.read<LedgerProvider>();
    final categories = context.read<CategoryProvider>();

    final tx = widget.tx;
    final accountName = ledger.resolvePrimaryAccountName(tx);
    final categoryName = categories.resolveTransactionCategoryName(tx);
    final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp);

    final typeColor = _isTransfer
        ? AppTheme.accent
        : _isIncome
        ? AppTheme.success
        : AppTheme.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── DRAG HANDLE ──
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // ── CLOSE ──
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── CATEGORY NAME ──
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),

          const SizedBox(height: 8),

          // ── AMOUNT ──
          Text(
            "₹${formatAmt(tx.amount)}",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: typeColor,
            ),
          ),

          const SizedBox(height: 10),

          // ── TYPE BADGE ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isTransfer
                  ? "TRANSFER"
                  : _isIncome
                  ? "INCOME"
                  : "EXPENSE",
              style: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          // ── DETAIL ROWS ──
          _detailRow("Account", accountName),
          _detailRow("Date", DateFormat("MMM d, yyyy").format(date)),
          _detailRow("Time", DateFormat("hh:mm a").format(date)),
          if (tx.note != null && tx.note!.trim().isNotEmpty)
            _detailRow("Note", tx.note!),

          // ── WALLET IMPACT ──
          // Income: single wallet, shown immediately (no async needed)
          if (_isIncome && tx.categoryId != null)
            _WalletImpactSection(
              splits: [
                WalletSplit(categoryId: tx.categoryId!, amount: tx.amount),
              ],
              label: "Added to wallet",
              color: AppTheme.success,
              icon: Icons.add_circle_outline,
            ),

          // Expense: read from DB, but future is stable (stored in initState)
          if (_isExpense)
            FutureBuilder<List<WalletSplit>>(
              future: _splitsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Skeleton placeholder — same height as one wallet row
                  // so the sheet doesn't jump when data arrives
                  return _WalletImpactSkeleton();
                }
                final splits = snapshot.data ?? [];
                if (splits.isEmpty) return const SizedBox.shrink();
                return _WalletImpactSection(
                  splits: splits,
                  label: splits.length > 1
                      ? "Deducted from wallets"
                      : "Deducted from wallet",
                  color: AppTheme.error,
                  icon: Icons.remove_circle_outline,
                );
              },
            ),

          const SizedBox(height: 24),

          // ── ACTIONS ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _iconActionButton(
                icon: Icons.edit,
                color: AppTheme.accent,
                onTap: () => _handleEdit(context, ledger),
              ),
              _iconActionButton(
                icon: Icons.delete,
                color: AppTheme.error,
                onTap: () => _handleDelete(context, ledger),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── EDIT ──

  Future<void> _handleEdit(BuildContext context, LedgerProvider ledger) async {
    Navigator.pop(context); // close detail sheet first

    TransactionEntity? paired;
    if (_isTransfer) {
      paired = await ledger.getPairedTransferLeg(widget.tx);
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          transaction: widget.tx,
          pairedTransaction: paired,
        ),
      ),
    );
  }

  // ── DELETE ──

  Future<void> _handleDelete(
    BuildContext context,
    LedgerProvider ledger,
  ) async {
    final deleteType = await ledger.getDeleteType(widget.tx);

    bool confirm;
    switch (deleteType) {
      case TransactionDeleteType.salaryDistributed:
        if (!context.mounted) return;
        confirm = await ConfirmDeleteDialog.show(
          context: context,
          title: "Delete Salary",
          message:
              "This salary has been distributed to wallets.\n\nDeleting it will revert those allocations.",
        );
        break;
      case TransactionDeleteType.normal:
        if (!context.mounted) return;
        confirm = await ConfirmDeleteDialog.show(
          context: context,
          title: "Delete Transaction",
          message: "This action cannot be undone.",
        );
    }

    if (!confirm) return;

    await ledger.deleteTransaction(widget.tx.id!);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Transaction deleted",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.pop(context);
    }
  }

  // ── SHARED WIDGETS ──

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WALLET IMPACT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _WalletImpactSection extends StatelessWidget {
  final List<WalletSplit> splits;
  final String label;
  final Color color;
  final IconData icon;

  const _WalletImpactSection({
    required this.splits,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...splits.map((split) {
            final walletName = context
                .read<CategoryProvider>()
                .resolveCategoryName(split.categoryId);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        walletName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "₹${formatAmt(split.amount)}",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Fixed-height skeleton so the sheet doesn't jump while splits load
class _WalletImpactSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
