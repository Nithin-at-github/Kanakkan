import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:provider/provider.dart';

class AddCategoryDialog {
  static void show(BuildContext context) {
    final controller = TextEditingController();
    String type = "expense";

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
                      filled: true,
                      fillColor: Colors.white,
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
                          ),
                          onPressed: () {
                            context.read<CategoryProvider>().addCategory(
                              Category(name: controller.text, type: type),
                            );

                            Navigator.pop(context);
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
