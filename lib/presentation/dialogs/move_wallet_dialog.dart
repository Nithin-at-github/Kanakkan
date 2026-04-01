import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class MoveWalletDialog extends StatefulWidget {
  const MoveWalletDialog({super.key});

  @override
  State<MoveWalletDialog> createState() => _MoveWalletDialogState();
}

class _MoveWalletDialogState extends State<MoveWalletDialog> {
  int? fromCategoryId;
  int? toCategoryId;

  final amountController = TextEditingController();

  String? errorText;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final balances = context.watch<CategoryBalanceProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// TITLE
              Text(
                "Move Wallet Money",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),

              const SizedBox(height: 18),

              /// FROM WALLET
              DropdownButtonFormField<int>(
                initialValue: fromCategoryId,
                decoration: InputDecoration(
                  labelText: "From Wallet",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((c) {
                  final balance = balances.getBalance(c.id!);

                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      "${c.name} (₹${formatAmt(balance, decimals: false)})",
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    fromCategoryId = v;
                    errorText = null;
                  });
                },
              ),

              const SizedBox(height: 14),

              /// TO WALLET
              DropdownButtonFormField<int>(
                initialValue: toCategoryId,
                decoration: InputDecoration(
                  labelText: "To Wallet",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((c) {
                  final balance = balances.getBalance(c.id!);

                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      "${c.name} (₹${formatAmt(balance, decimals: false)})",
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    toCategoryId = v;
                    errorText = null;
                  });
                },
              ),

              const SizedBox(height: 14),

              /// AMOUNT
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixText: "₹ ",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  setState(() {
                    errorText = null;
                  });
                },
              ),

              /// ERROR MESSAGE
              if (errorText != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              /// ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading ? null : () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                      ),
                      onPressed: loading ? null : _moveMoney,
                      child: loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Move"),
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

  Future<void> _moveMoney() async {
    final balances = context.read<CategoryBalanceProvider>();

    final amount = double.tryParse(amountController.text);

    /// VALIDATION
    if (fromCategoryId == null || toCategoryId == null) {
      setState(() {
        errorText = "Select both wallets";
      });
      return;
    }

    if (fromCategoryId == toCategoryId) {
      setState(() {
        errorText = "Cannot move to same wallet";
      });
      return;
    }

    if (amount == null || amount <= 0) {
      setState(() {
        errorText = "Enter a valid amount";
      });
      return;
    }

    final fromBalance = balances.getBalance(fromCategoryId!);

    if (amount > fromBalance) {
      setState(() {
        errorText = "Insufficient wallet balance";
      });
      return;
    }

    try {
      setState(() => loading = true);

      await balances.moveBalance(
        fromCategoryId: fromCategoryId!,
        toCategoryId: toCategoryId!,
        amount: amount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Money moved successfully!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorText = e.toString();
      });
    }
  }
}
