import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/utils/form_validation.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class AddCategoryDialog {
  static void show(BuildContext context) {
    final controller = TextEditingController();
    String? nameError;
    Account? selectedAccount;
    bool excludeFromAnalysis = false;

    showDialog(
      context: context,
      builder: (_) => Consumer2<CategoryProvider, LedgerProvider>(
        builder: (context, provider, ledger, _) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                backgroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// TITLE
                        const Text(
                          'New Category',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// NAME FIELD
                        TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Category name',
                            errorText: nameError,
                            filled: true,
                            fillColor: AppTheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) {
                            if (nameError != null) {
                              setState(() => nameError = null);
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        /// LINKED ACCOUNT DROPDOWN
                        DropdownButtonFormField<Account?>(
                          initialValue: selectedAccount,
                          decoration: InputDecoration(
                            labelText: 'Linked account (optional)',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<Account?>(
                              value: null,
                              child: Text(
                                'None',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                            ...ledger.accounts.map(
                              (a) => DropdownMenuItem<Account?>(
                                value: a,
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance,
                                        size: 16, color: AppTheme.accent),
                                    const SizedBox(width: 8),
                                    Text(a.name),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => selectedAccount = val),
                        ),

                        const SizedBox(height: 8),

                        /// EXCLUDE FROM ANALYSIS TOGGLE
                        SwitchListTile(
                          title: const Text(
                            'Exclude from Analysis',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: const Text(
                            'Hide from all summaries and charts',
                            style: TextStyle(fontSize: 11),
                          ),
                          value: excludeFromAnalysis,
                          onChanged: (val) =>
                              setState(() => excludeFromAnalysis = val),
                          activeThumbColor: AppTheme.accent,
                          contentPadding: EdgeInsets.zero,
                        ),

                        /// ERROR MESSAGE
                        if (provider.lastError != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              provider.lastError!,
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        /// ACTIONS
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  provider.clearError();
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                ),
                                onPressed: () async {
                                  provider.clearError();

                                  final name = controller.text.trim();

                                  setState(() {
                                    nameError =
                                        FormValidation.categoryName(name);
                                  });

                                  if (nameError != null) return;

                                  final catProvider =
                                      context.read<CategoryProvider>();
                                  await catProvider.addCategory(
                                    Category(
                                      name: name,
                                      linkedAccountId: selectedAccount?.id,
                                      excludeFromAnalysis: excludeFromAnalysis,
                                    ),
                                  );

                                  /// close ONLY if success
                                  if (catProvider.lastError == null) {
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                },
                                child: const Text('Add'),
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
