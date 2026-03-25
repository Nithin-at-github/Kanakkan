import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class MergeCategoriesDialog extends StatefulWidget {
  const MergeCategoriesDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const MergeCategoriesDialog());
  }

  @override
  State<MergeCategoriesDialog> createState() => _MergeCategoriesDialogState();
}

class _MergeCategoriesDialogState extends State<MergeCategoriesDialog> {
  final _nameController = TextEditingController();
  final Set<int> _selectedIds = {};
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleMerge() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Please enter a name for the new category');
      return;
    }

    if (_selectedIds.length < 2) {
      setState(() => _errorText = 'Select at least 2 categories to merge');
      return;
    }

    final provider = context.read<CategoryProvider>();
    final ledger = context.read<LedgerProvider>();
    final balances = context.read<CategoryBalanceProvider>();

    await provider.mergeCategories(_selectedIds.toList(), name);

    if (provider.lastError == null) {
      // Reload ledger and balances so that stale references in memory are updated.
      // This prevents transactions from showing as 'Deleted Category'
      // and ensures the new category reflects the consolidated wallet total.
      await Future.wait([ledger.loadTransactions(), balances.loadBalances()]);
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _errorText = provider.lastError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final categories = provider.mainCategories;

    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Merge Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Consolidate multiple categories into one. All transactions and subcategories will be moved.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              const Text(
                'New Category Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Household',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Select Categories to Merge (${_selectedIds.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isSelected = _selectedIds.contains(cat.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(cat.id!);
                            } else {
                              _selectedIds.remove(cat.id);
                            }
                          });
                        },
                        title: Text(
                          cat.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        activeColor: AppTheme.accent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: 12),
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
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: _handleMerge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Merge'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
