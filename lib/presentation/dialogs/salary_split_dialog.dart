import 'package:flutter/material.dart';
import 'package:kanakkan/data/repositories/salary_allocation_repository.dart';
import 'package:kanakkan/presentation/providers/salary_allocation_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';

class SalarySplitDialog extends StatefulWidget {
  final double salaryAmount;
  final int salaryCategoryId;
  final int salaryTransactionId;

  const SalarySplitDialog({
    super.key,
    required this.salaryAmount,
    required this.salaryCategoryId,
    required this.salaryTransactionId,
  });

  @override
  State<SalarySplitDialog> createState() => _SalarySplitDialogState();
}

class _SalarySplitDialogState extends State<SalarySplitDialog> {
  final Map<int, TextEditingController> controllers = {};
  bool saveTemplate = false;

  double get allocatedTotal {
    double sum = 0;

    for (final c in controllers.values) {
      sum += double.tryParse(c.text) ?? 0;
    }

    return sum;
  }

  double get remaining => widget.salaryAmount - allocatedTotal;

  @override
  void initState() {
    super.initState();

    final categories = context.read<CategoryProvider>().splitCategories;

    for (final c in categories) {
      controllers[c.id!] = TextEditingController(text: "0");
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().splitCategories;
    final allocationProvider = context.watch<SalaryAllocationProvider>();

    return Dialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// HEADER
              Column(
                children: [
                  const Text(
                    "Split Salary",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "₹${widget.salaryAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),

              /// TEMPLATE BUTTON
              if (allocationProvider.template.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text("Use saved split"),
                    onPressed: _applyTemplate,
                  ),
                ),

              const SizedBox(height: 10),

              /// CATEGORY LIST
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final controller = controllers[category.id]!;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(blurRadius: 6, color: Colors.black12),
                        ],
                      ),
                      child: Row(
                        children: [
                          /// CATEGORY NAME
                          Expanded(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          /// AMOUNT FIELD
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                prefixText: "₹ ",
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              /// REMAINING INDICATOR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: remaining < 0
                      ? AppTheme.error.withOpacity(0.1)
                      : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Remaining",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₹${remaining.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: remaining < 0
                            ? AppTheme.error
                            : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),

              /// SAVE TEMPLATE
              CheckboxListTile(
                value: saveTemplate,
                contentPadding: EdgeInsets.zero,
                title: const Text("Save this split"),
                onChanged: (v) {
                  setState(() {
                    saveTemplate = v ?? false;
                  });
                },
              ),

              /// ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Skip"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                      ),
                      onPressed: remaining < 0 ? null : _applySplit,
                      child: const Text("Apply"),
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

  /// ================= APPLY TEMPLATE =================

  void _applyTemplate() {
    final template = context.read<SalaryAllocationProvider>().template;

    setState(() {
      for (final entry in template.entries) {
        if (controllers.containsKey(entry.key)) {
          controllers[entry.key]!.text = entry.value.toStringAsFixed(0);
        }
      }
    });
  }

  /// ================= APPLY SPLIT =================

  Future<void> _applySplit() async {
    final balanceProvider = context.read<CategoryBalanceProvider>();
    final allocationProvider = context.read<SalaryAllocationProvider>();
    final allocationRepo = SalaryAllocationRepository();

    final Map<int, double> allocations = {};

    for (final entry in controllers.entries) {
      final amount = double.tryParse(entry.value.text) ?? 0;

      if (amount > 0) {
        allocations[entry.key] = amount;
      }
    }

    /// move money from salary wallet
    for (final entry in allocations.entries) {
      await balanceProvider.allocate(entry.key, entry.value);
      await balanceProvider.spend(widget.salaryCategoryId, entry.value);

      await allocationRepo.insertAllocation(
        salaryTransactionId: widget.salaryTransactionId,
        categoryId: entry.key,
        amount: entry.value,
      );
    }

    /// save template if selected
    if (saveTemplate) {
      await allocationProvider.saveTemplate(allocations);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }
}
