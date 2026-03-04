import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/utils/form_validation.dart';
import 'package:kanakkan/domain/entities/budget_entity.dart';
import 'package:kanakkan/providers/budget_provider.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:provider/provider.dart';

class SetBudgetDialog extends StatefulWidget {
  final BudgetEntity? existingBudget;

  const SetBudgetDialog({super.key, this.existingBudget});

  @override
  State<SetBudgetDialog> createState() => _SetBudgetDialogState();
}

class _SetBudgetDialogState extends State<SetBudgetDialog> {
  int? selectedCategoryId;
  late TextEditingController amountController;
  String? amountError;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    selectedCategoryId = widget.existingBudget?.categoryId;

    amountController = TextEditingController(
      text: widget.existingBudget != null
          ? widget.existingBudget!.allocatedAmount.toStringAsFixed(0)
          : "",
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  /// ================= SAVE =================
  Future<void> _saveBudget() async {
    
    setState(() {
      amountError = FormValidation.budget(amountController.text);
    });
     /// stop if validation fails
    if (amountError != null) return;

    final amount = double.parse(amountController.text);
    setState(() => loading = true);

    try {
      await context.read<BudgetProvider>().addBudget(
        categoryId: selectedCategoryId!,
        amount: amount,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        amountError = "Failed to save budget";
      });
    } finally {
      setState(() => loading = false);
    }
  }

  /// ================= DELETE =================
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Budget"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await context.read<BudgetProvider>().deleteBudget(
      widget.existingBudget!.id!,
    );

    if (mounted) Navigator.pop(context);
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// TITLE
                Text(
                  widget.existingBudget == null
                      ? "Set Monthly Budget"
                      : "Edit Budget",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),

                const SizedBox(height: 22),

                /// CATEGORY
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                  items: categories.categories
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: widget.existingBudget != null
                      ? null
                      : (value) {
                          setState(() => selectedCategoryId = value);
                        },
                ),

                const SizedBox(height: 18),

                /// AMOUNT
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    errorText: amountError,
                    prefixText: "₹ ",
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 26),

                /// ================= ACTION BUTTONS =================
                Row(
                  children: [
                    /// CANCEL
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppTheme.accent.withOpacity(.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// SAVE
                    Expanded(
                      child: ElevatedButton(
                        onPressed: loading ? null : _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Save",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                /// ================= DANGER ZONE =================
                if (widget.existingBudget != null) ...[
                  const SizedBox(height: 30),

                  Divider(color: Colors.red.withOpacity(.3)),

                  const SizedBox(height: 10),

                  TextButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      "Delete this budget",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
