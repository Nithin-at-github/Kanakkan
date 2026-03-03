import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class AddAccountDialog {
  static void show(BuildContext context) {
    final controller = TextEditingController();
    String entityType = "Me";
    String mediumType = "Cash";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "New Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: "Account name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: () {
                            context.read<LedgerProvider>().addAccount(
                              Account(
                                name: controller.text,
                                entityType: entityType,
                                mediumType: mediumType,
                              ),
                            );

                            Navigator.pop(context);
                          },
                          child: const Text("Add Account", style: TextStyle(fontSize: 13),),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
