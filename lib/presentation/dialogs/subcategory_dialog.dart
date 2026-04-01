import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/dialogs/add_subcategory_row.dart';
import 'package:kanakkan/presentation/dialogs/edit_subcategory_dialog.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';

class SubcategoryDialog extends StatelessWidget {
  final Category parent;
  final Color accent;

  const SubcategoryDialog({
    super.key,
    required this.parent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final subcategories = provider.subcategoriesOf(parent.id!);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(Icons.label_outline, color: accent, size: 16),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    parent.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              "Subcategories",
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),

            const SizedBox(height: 12),

            /// SUBCATEGORY LIST
            if (subcategories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    "No subcategories yet.\nTap + to add one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: subcategories.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AppTheme.divider),
                  itemBuilder: (context, i) {
                    final sub = subcategories[i];

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(
                        Icons.subdirectory_arrow_right,
                        color: accent,
                        size: 18,
                      ),
                      title: Row(
                        children: [
                          Text(sub.name, style: const TextStyle(fontSize: 14)),
                          if (sub.excludeFromAnalysis) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.onSurface.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.visibility_off_outlined,
                                    size: 8,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Ignored',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: AppTheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            onPressed: () =>
                                editSubcategoryDialog(context, sub),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),

                          const SizedBox(width: 8),

                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirm = await ConfirmDeleteDialog.show(
                                context: context,
                                title: "Delete Subcategory",
                                message: "Remove '${sub.name}' permanently?",
                              );

                              if (!confirm) return;

                              if (!context.mounted) return;
                              final catProvider = context
                                  .read<CategoryProvider>();
                              await catProvider.deleteCategory(sub.id!);
                              // No further context usage needed after await
                              // (dialog auto-rebuilds via provider watch)
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 20),

            /// ADD SUBCATEGORY
            AddSubcategoryRow(parent: parent, accent: accent),
          ],
        ),
      ),
    );
  }
}
