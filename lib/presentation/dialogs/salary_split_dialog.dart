import 'package:flutter/material.dart';
import 'package:kanakkan/data/repositories/salary_allocation_repository.dart';
import 'package:kanakkan/presentation/providers/salary_allocation_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/widgets/animations/animated_amount.dart';
import 'package:kanakkan/presentation/widgets/animations/staggered_entrance.dart';

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
              // HEADER
              Column(
                children: [
                  Text(
                    "Split Salary",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedAmount(
                    amount: widget.salaryAmount,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),

              // TEMPLATE BUTTON
              if (allocationProvider.template.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(Icons.download, color: AppTheme.onSurface),
                    label: Text(
                      "Use saved split",
                      style: TextStyle(color: AppTheme.onSurface),
                    ),
                    onPressed: _applyTemplate,
                  ),
                ),

              const SizedBox(height: 10),

              // CATEGORY LIST
              Expanded(
                child: ListView.separated(
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final controller = controllers[category.id]!;

                    return StaggeredEntrance(
                      index: index,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6,
                              color: AppTheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  prefixText: "₹ ",
                                  prefixStyle: TextStyle(color: AppTheme.onSurface),
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // REMAINING INDICATOR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: remaining < 0
                      ? AppTheme.error.withValues(alpha: 0.1)
                      : AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      "Remaining",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    AnimatedAmount(
                      amount: remaining,
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

              // SAVE TEMPLATE
              CheckboxListTile(
                value: saveTemplate,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Save this split",
                  style: TextStyle(color: AppTheme.onSurface),
                ),
                activeColor: AppTheme.accent,
                checkColor: Colors.white,
                onChanged: (v) {
                  setState(() {
                    saveTemplate = v ?? false;
                  });
                },
              ),

              // ACTIONS
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

    // Move money between wallets silently (no notifyListeners per call)
    for (final entry in allocations.entries) {
      await balanceProvider.allocate(entry.key, entry.value);
      await balanceProvider.spend(widget.salaryCategoryId, entry.value);

      await allocationRepo.insertAllocation(
        salaryTransactionId: widget.salaryTransactionId,
        categoryId: entry.key,
        amount: entry.value,
      );
    }

    // Notify once after all balance changes are done
    await balanceProvider.loadBalances();

    if (saveTemplate) {
      await allocationProvider.saveTemplate(allocations);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }
}
