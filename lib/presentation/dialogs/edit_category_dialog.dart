import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';
import 'package:kanakkan/presentation/validators/category_validator.dart';

void editCategoryDialog(BuildContext context, Category category) {
  final controller = TextEditingController(text: category.name);
  String? localError;

  // Track the currently selected linked account, initialised from category
  final allAccounts = context.read<LedgerProvider>().accounts;
  Account? currentLinked = allAccounts
      .where((a) => a.id == category.linkedAccountId)
      .firstOrNull;
  bool excludeFromAnalysis = category.excludeFromAnalysis;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final provider = context.watch<CategoryProvider>();

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
                Text(
                  'Edit Category',
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
                    labelText: 'Category name',
                    filled: true,
                    fillColor: Colors.white,
                    errorText: localError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) {
                    if (localError != null) {
                      setState(() => localError = null);
                    }
                  },
                ),

                const SizedBox(height: 16),

                /// LINKED ACCOUNT DROPDOWN
                if (category.isMainCategory)
                  DropdownButtonFormField<Account?>(
                    initialValue: currentLinked,
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
                      ...allAccounts.map(
                        (a) => DropdownMenuItem<Account?>(
                          value: a,
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 16,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(a.name),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => currentLinked = val),
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
                  onChanged: (val) => setState(() => excludeFromAnalysis = val),
                  activeThumbColor: AppTheme.accent,
                  contentPadding: EdgeInsets.zero,
                ),

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
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
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
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = controller.text.trim();

                          final validationError = validateSubcategoryName(name);

                          if (validationError != null) {
                            setState(() => localError = validationError);
                            return;
                          }

                          provider.clearError();

                          await provider.updateCategory(
                            category.id!,
                            name,
                            excludeFromAnalysis,
                          );

                          // Update linked account if it's a main category
                          if (category.isMainCategory &&
                              provider.lastError == null) {
                            await provider.updateLinkedAccount(
                              category.id!,
                              currentLinked?.id,
                            );
                          }

                          if (provider.lastError == null && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
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
