import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/validators/category_validator.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

void editSubcategoryDialog(BuildContext context, Category sub) {
  final controller = TextEditingController(text: sub.name);
  bool excludeFromAnalysis = sub.excludeFromAnalysis;

  String? error;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final provider = context.watch<CategoryProvider>();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Edit Subcategory"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: "Subcategory name",
                  filled: true,
                  fillColor: AppTheme.surface,
                  errorText: error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 8),

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
                const SizedBox(height: 10),
                Text(
                  provider.lastError!,
                  style: TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.clearError();
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: AppTheme.onSurface),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () async {
                final name = controller.text.trim();

                final validationError = validateSubcategoryName(name);

                if (validationError != null) {
                  setState(() => error = validationError);
                  return;
                }

                provider.clearError();

                await provider.updateCategory(
                  sub.id!,
                  name,
                  excludeFromAnalysis,
                );

                if (provider.lastError == null && context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    ),
  );
}
