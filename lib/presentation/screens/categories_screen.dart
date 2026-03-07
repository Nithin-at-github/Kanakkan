import 'package:flutter/material.dart';
import 'package:kanakkan/core/widgets/confirm_delete_dialog.dart';
import 'package:kanakkan/presentation/dialogs/move_wallet_dialog.dart';
import 'package:kanakkan/presentation/widgets/custom_app_bar.dart';
import 'package:kanakkan/presentation/providers/category_balance_provider.dart';
import 'package:provider/provider.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/providers/category_provider.dart';
import 'package:kanakkan/presentation/providers/ledger_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final ledger = context.watch<LedgerProvider>();

    final totalIncome = ledger.transactions
        .where((t) => t.type == "income")
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = ledger.transactions
        .where((t) => t.type == "expense")
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ReusableAppBar(
        actions: [
          IconButton(
            icon: const Icon(
              Icons.swap_horiz,
              color: AppTheme.accent,
              size: 35,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const MoveWalletDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// ================= HEADER =================
          _header(context, totalIncome, totalExpense),

          /// ================= LIST =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                _categorySection(
                  context,
                  "Income Categories",
                  provider.incomeCategories,
                  AppTheme.success,
                ),

                _categorySection(
                  context,
                  "Expense Categories",
                  provider.expenseCategories,
                  AppTheme.error,
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _header(BuildContext context, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: Column(
        children: [
          const Text(
            "Categories",
            style: TextStyle(
              color: AppTheme.accent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard("Income", income, AppTheme.success),
              _summaryCard("Expense", expense, AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= CATEGORY SECTION =================

  Widget _categorySection(
    BuildContext context,
    String title,
    List<Category> categories,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Column(
          children: [
            /// SECTION TITLE
            Container(
              padding: const EdgeInsets.all(14),
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontSize: 16,
                ),
              ),
            ),

            const Divider(height: 1, color: AppTheme.accent,),
            if (categories.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "No categories added",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...categories.map((c) => _categoryTile(context, c, accent)),
            ],
          ],
        ),
      ),
    );
  }

  // ================= CATEGORY TILE =================

  Widget _categoryTile(BuildContext context, Category category, Color accent) {
    final provider = context.read<CategoryProvider>();
    final balances = context.watch<CategoryBalanceProvider>();

    return ListTile(
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Wallet ₹${balances.getBalance(category.id!).toStringAsFixed(0)}",
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
                _editDialog(context, category);
              } else {
                final confirm = await ConfirmDeleteDialog.show(
                  context: context,
                  title: "Delete Category",
                  message: "This will remove the category permanently.",
                );

                if (!confirm) return;

                await provider.deleteCategory(category.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Category deleted",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );

                if (provider.lastError != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.lastError!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.error,
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
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

  // ================= EDIT =================

  void _editDialog(BuildContext context, Category category) {
    final controller = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (_) => Consumer<CategoryProvider>(
        builder: (context, provider, __) {
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
                    "Edit Category",
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

                            await context
                                .read<CategoryProvider>()
                                .updateCategory(
                                  category.id!,
                                  controller.text.trim(),
                                );

                            /// close ONLY if success
                            if (context.read<CategoryProvider>().lastError ==
                                null) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Save"),
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
