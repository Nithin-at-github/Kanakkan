import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class SafeDeleteDialog extends StatefulWidget {
  final Category category;

  const SafeDeleteDialog({super.key, required this.category});

  static Future<bool> show(BuildContext context, Category category) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => SafeDeleteDialog(category: category),
        ) ??
        false;
  }

  @override
  State<SafeDeleteDialog> createState() => _SafeDeleteDialogState();
}

class _SafeDeleteDialogState extends State<SafeDeleteDialog> {
  int? _targetId;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final ledger = context.read<LedgerProvider>();
    final balances = context.watch<CategoryBalanceProvider>();

    final currentBalance = balances.getBalance(widget.category.id!);
    final hasBalance = currentBalance != 0;

    // Filter out the category being deleted from the options
    final options = provider.categories
        .where((c) => c.id != widget.category.id)
        .where((c) => c.isMainCategory == widget.category.isMainCategory)
        .toList();

    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete ${widget.category.name}?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'To preserve your financial history, please choose a destination for all existing transactions and subcategories.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              initialValue: _targetId,
              decoration: InputDecoration(
                labelText: 'Move data to...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: options.map((c) {
                return DropdownMenuItem(value: c.id, child: Text(c.name));
              }).toList(),
              onChanged: (val) => setState(() => _targetId = val),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _targetId == null
                        ? null
                        : () async {
                            await provider.mergeInto(
                              widget.category.id!,
                              _targetId!,
                            );
                            if (provider.lastError == null) {
                              // Reload everything to ensure UI state matches DB
                              await Future.wait([
                                ledger.loadTransactions(),
                                balances.loadBalances(),
                              ]);
                              if (!context.mounted) return;
                              Navigator.pop(context, true);
                            } else {
                              setState(() => _errorText = provider.lastError);
                            }
                          },
                    child: const Text(
                      'Move & Delete',
                      style: TextStyle(color: AppTheme.background),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  if (hasBalance)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Note: This category has a balance of ₹${formatAmt(currentBalance, decimals: false)}. It will be automatically moved to your Salary Wallet (Ready to Assign) to maintain balance integrity.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () async {
                      try {
                        if (hasBalance && ledger.salaryCategoryId != null) {
                          await balances.moveBalance(
                            fromCategoryId: widget.category.id!,
                            toCategoryId: ledger.salaryCategoryId!,
                            amount: currentBalance,
                          );
                        }
                        await provider.deleteCategory(widget.category.id!);
                        if (provider.lastError == null) {
                          // Reload everything to ensure UI state matches DB
                          await Future.wait([
                            ledger.loadTransactions(),
                            balances.loadBalances(),
                          ]);
                          if (!context.mounted) return;
                          Navigator.pop(context, true);
                        } else {
                          setState(() => _errorText = provider.lastError);
                        }
                      } catch (e) {
                        setState(() => _errorText = e.toString());
                      }
                    },
                    child: const Text(
                      'Just Delete (Keep as Deleted Category)',
                      style: TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
