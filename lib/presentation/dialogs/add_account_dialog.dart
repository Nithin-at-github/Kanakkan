import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/utils/form_validation.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class AddAccountDialog {
  static void show(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');

    String? nameError;
    String? balanceError;

    showDialog(
      context: context,
      builder: (_) => Consumer<LedgerProvider>(
        builder: (context, ledger, _) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "New Account",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// ACCOUNT NAME
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "Account name",
                            errorText: nameError,
                            filled: true,
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// INITIAL BALANCE
                        TextField(
                          controller: balanceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: "Initial balance",
                            errorText: balanceError,
                            filled: true,
                            fillColor: AppTheme.background,
                            prefixText: "₹ ",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        /// PROVIDER ERROR
                        if (ledger.lastError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              ledger.lastError!,
                              style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        /// ACTION BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ledger.clearError();
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  ledger.clearError();

                                  final name = nameController.text.trim();
                                  final balanceText = balanceController.text;

                                  /// VALIDATION USING HELPER
                                  setState(() {
                                    nameError = FormValidation.accountName(
                                      name,
                                    );
                                    balanceError = FormValidation.balance(
                                      balanceText,
                                    );
                                  });

                                  if (nameError != null ||
                                      balanceError != null) {
                                    return;
                                  }

                                  final balance =
                                      double.tryParse(balanceText) ?? 0.0;

                                  /// CALL PROVIDER
                                  final providerRef = context
                                      .read<LedgerProvider>();
                                  await providerRef.addAccount(
                                    Account(
                                      name: name,
                                      initialBalance: balance,
                                    ),
                                  );

                                  /// CLOSE ONLY IF SUCCESS
                                  if (providerRef.lastError == null) {
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                },
                                child: const Text("Add Account"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
