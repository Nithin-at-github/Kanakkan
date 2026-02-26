import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/providers/category_provider.dart';
import 'package:kanakkan/providers/ledger_provider.dart';
import 'package:provider/provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final lprovider = context.watch<LedgerProvider>();
    final accounts = lprovider.accounts;

    final totalBalance = accounts.fold(
      0.0,
      (sum, a) => sum + (lprovider.accountBalances[a.id] ?? 0.0),
    );

    final totalIncome = lprovider.transactions
        .where((t) => t.type == "income")
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = lprovider.transactions
        .where((t) => t.type == "expense")
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          "കണക്കൻ",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  "[ All Accounts ₹${totalBalance.toStringAsFixed(2)} ]",
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _summaryColumn(
                      "EXPENSE SO FAR",
                      totalExpense,
                      AppTheme.error,
                    ),
                    _summaryColumn(
                      "INCOME SO FAR",
                      totalIncome,
                      AppTheme.success,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _sectionTitle("Income categories"),

                ...provider.incomeCategories.map(
                  (c) => _categoryTile(context, c),
                ),

                _sectionTitle("Expense categories"),

                ...provider.expenseCategories.map(
                  (c) => _categoryTile(context, c),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _addCategoryDialog(context),
                    icon: const Icon(Icons.add, color: AppTheme.accent),
                    label: const Text(
                      "ADD NEW CATEGORY",
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryColumn(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _categoryTile(BuildContext context, Category category) {
    final provider = context.read<CategoryProvider>();

    return ListTile(
      title: Text(category.name),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == "edit") {
            _editDialog(context, category);
          } else if (value == "delete") {
            provider.deleteCategory(category.id!);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: "edit", child: Text("Edit")),
          PopupMenuItem(value: "delete", child: Text("Delete")),
        ],
      ),
    );
  }

  void _addCategoryDialog(BuildContext context) {
    final controller = TextEditingController();

    String type = "expense";

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              title: const Text(
                "Add Category",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              content: SizedBox(
                width: 350, // makes dialog bigger
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Category Name
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: "Category name",
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// TYPE SELECTOR
                    Row(
                      children: [
                        Expanded(
                          child: _typeSelector(
                            label: "Income",
                            selected: type == "income",
                            color: Colors.green,
                            onTap: () {
                              setState(() {
                                type = "income";
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _typeSelector(
                            label: "Expense",
                            selected: type == "expense",
                            color: Colors.red,
                            onTap: () {
                              setState(() {
                                type = "expense";
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () {
                    context.read<CategoryProvider>().addCategory(
                      Category(name: controller.text, type: type),
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _typeSelector({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
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

  void _editDialog(BuildContext context, Category category) {
    final controller = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Category"),
        content: TextField(controller: controller),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.read<CategoryProvider>().updateCategory(
                category.id!,
                controller.text,
              );

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
