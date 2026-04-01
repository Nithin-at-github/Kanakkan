import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';
import 'package:kanakkan/domain/entities/budget_entity.dart';
import 'package:kanakkan/presentation/providers/budget_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:provider/provider.dart';

Future<void> showSetBudgetDialog(
  BuildContext context, {
  BudgetEntity? existingBudget,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SetBudgetDialog(existingBudget: existingBudget),
  );
}

class _SetBudgetDialog extends StatefulWidget {
  final BudgetEntity? existingBudget;
  const _SetBudgetDialog({this.existingBudget});

  @override
  State<_SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<_SetBudgetDialog> {
  int? _selectedCategoryId;
  late TextEditingController _amountController;
  String? _categoryError;
  String? _amountError;
  bool _loading = false;

  bool get _isEdit => widget.existingBudget != null;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.existingBudget?.categoryId;
    _amountController = TextEditingController(
      text: _isEdit
          ? widget.existingBudget!.allocatedAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool _validate(BudgetProvider budgetProvider) {
    String? categoryErr;
    String? amountErr;

    if (_selectedCategoryId == null) {
      categoryErr = 'Please select a category';
    }

    final text = _amountController.text.trim();
    if (text.isEmpty) {
      amountErr = 'Amount is required';
    } else {
      final amount = double.tryParse(text);
      if (amount == null) {
        amountErr = 'Enter a valid amount';
      } else if (amount <= 0) {
        amountErr = 'Amount must be greater than 0';
      } else if (amount > 1000000) {
        amountErr = 'Amount seems too large — please check';
      }
    }

    if (!_isEdit && categoryErr == null && _selectedCategoryId != null) {
      final alreadyExists = budgetProvider.budgets.any(
        (b) => b.categoryId == _selectedCategoryId,
      );
      if (alreadyExists) {
        categoryErr = 'A budget for this category already exists this month';
      }
    }

    setState(() {
      _categoryError = categoryErr;
      _amountError = amountErr;
    });
    return categoryErr == null && amountErr == null;
  }

  Future<void> _saveBudget() async {
    if (_loading) return;
    final budgetProvider = context.read<BudgetProvider>();
    if (!_validate(budgetProvider)) return;

    setState(() => _loading = true);
    try {
      await budgetProvider.addBudget(
        categoryId: _selectedCategoryId!,
        amount: double.parse(_amountController.text.trim()),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Budget updated' : 'Budget created',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      setState(() => _amountError = 'Failed to save budget. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.existingBudget?.id == null) return;

    final confirm = await ConfirmDeleteDialog.show(
      context: context,
      title: 'Delete Budget',
      message: 'This action cannot be undone.',
    );
    if (!confirm || !mounted) return;

    try {
      await context.read<BudgetProvider>().deleteBudget(
        widget.existingBudget!.id!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Budget deleted',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete budget. Please try again.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    final budgetProvider = context.watch<BudgetProvider>();

    final usedCategoryIds = _isEdit
        ? <int>{}
        : budgetProvider.budgets.map((b) => b.categoryId).toSet();

    // Budgets apply to all main categories — subcategories are excluded.
    final budgetableCategories = categories.mainCategories;

    // Key insight: give the dialog an EXPLICIT width and let content
    // flow naturally — no IntrinsicHeight, no mainAxisSize.min fighting
    // unbounded constraints from the dialog surface.
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        // Explicit fixed width — dialog knows its size before painting
        width: double.infinity,
        // Explicit max height — scroll if content overflows, never intrinsic
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            // SingleChildScrollView gives Column a bounded height context
            // so Flutter never needs to measure intrinsic dropdown height
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              // crossAxisAlignment stretch works fine here — width is known
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  _isEdit ? 'Edit Budget' : 'Set Monthly Budget',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),

                const SizedBox(height: 20),

                // Category dropdown
                // Inside SingleChildScrollView, dropdown measures itself
                // correctly without needing intrinsic height pass
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: const OutlineInputBorder(),
                    errorText: _categoryError,
                  ),
                  items: budgetableCategories.map((c) {
                    final isUsed = usedCategoryIds.contains(c.id);
                    return DropdownMenuItem(
                      value: c.id,
                      enabled: !isUsed,
                      child: Row(
                        children: [
                          Expanded(child: Text(c.name)),
                          if (isUsed)
                            Text(
                              '• set',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _isEdit
                      ? null
                      : (value) => setState(() {
                          _selectedCategoryId = value;
                          _categoryError = null;
                        }),
                ),

                const SizedBox(height: 18),

                // Amount
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  autofocus: true,
                  onChanged: (_) {
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    errorText: _amountError,
                    prefixText: '₹ ',
                    border: const OutlineInputBorder(),
                  ),
                ),

                // Danger zone
                if (_isEdit) ...[
                  const SizedBox(height: 24),
                  Divider(color: Colors.red.withValues(alpha: .3)),
                  TextButton.icon(
                    onPressed: _loading ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete this budget',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        side: BorderSide(
                          color: AppTheme.accent.withValues(alpha: .5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _saveBudget,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
