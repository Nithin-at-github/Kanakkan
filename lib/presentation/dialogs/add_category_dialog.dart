import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/core/utils/form_validation.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:provider/provider.dart';

class AddCategoryDialog {
  static void show(BuildContext context) {
    final controller = TextEditingController();
    
    String type = "expense";
    String? nameError;

    showDialog(
      context: context,
      builder: (_) => Consumer<CategoryProvider>(
        builder: (context, provider, __) {
          return StatefulBuilder(
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
                      /// TITLE
                      const Text(
                        "New Category",
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
                          labelText: "Category name",
                          errorText: nameError,
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// TYPE SELECTOR
                      Row(
                        children: [
                          Expanded(
                            child: _typeChip(
                              "Income",
                              type == "income",
                              AppTheme.success,
                              () => setState(() => type = "income"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _typeChip(
                              "Expense",
                              type == "expense",
                              AppTheme.error,
                              () => setState(() => type = "expense"),
                            ),
                          ),
                        ],
                      ),

                      /// ERROR MESSAGE (NEW)
                      if (provider.lastError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
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
                              child: const Text("Cancel"),
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

                                /// VALIDATION USING HELPER
                                setState(() {
                                  nameError = FormValidation.categoryName(name);
                                });

                                if (nameError != null) {
                                  return;
                                }

                                await context
                                    .read<CategoryProvider>()
                                    .addCategory(
                                      Category(
                                        name: controller.text.trim(),
                                        type: type,
                                      ),
                                    );

                                /// close ONLY if success
                                if (context
                                        .read<CategoryProvider>()
                                        .lastError ==
                                    null) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Add"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _typeChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? color : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
