import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/dialogs/edit_category_dialog.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:kanakkan/presentation/dialogs/subcategory_dialog.dart';

class CategoryTile extends StatelessWidget {
  final Category category;
  final Color accent;

  const CategoryTile({super.key, required this.category, required this.accent});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CategoryProvider>();
    final balances = context.watch<CategoryBalanceProvider>();
    final subcategories = provider.subcategoriesOf(category.id!);

    return ListTile(
      onTap: () => showDialog(
        context: context,
        builder: (_) => SubcategoryDialog(parent: category, accent: accent),
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: accent.withOpacity(0.15),
        child: Icon(
          category.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
          color: accent,
          size: 18,
        ),
      ),
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subcategories.isNotEmpty
          ? Text(
              "${subcategories.length} subcategories",
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "₹${balances.getBalance(category.id!).toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == "edit") {
                editCategoryDialog(context, category);
              } else {
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                final confirm = await ConfirmDeleteDialog.show(
                  context: context,
                  title: "Delete Category",
                  message: subcategories.isNotEmpty
                      ? "This will also delete all ${subcategories.length} subcategories permanently."
                      : "This will remove the category permanently.",
                );

                if (!confirm) return;

                final error = await provider.deleteCategory(category.id!);

                if (error != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        error,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }else{
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        "Category deleted",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "edit", child: Text("Edit")),
              PopupMenuItem(value: "delete", child: Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }
}
