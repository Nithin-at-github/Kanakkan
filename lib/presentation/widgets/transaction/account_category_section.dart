import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/domain/entities/account.dart';
import 'package:kanakkan/domain/entities/category.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';

class AccountCategorySection extends StatelessWidget {
  final TransactionType type;
  final Account? selectedAccount;
  final Account? selectedToAccount;
  final Category? selectedCategory;
  final VoidCallback onSelectAccount;
  final VoidCallback onSelectToAccount;
  final VoidCallback onSelectCategory;

  const AccountCategorySection({
    super.key,
    required this.type,
    required this.selectedAccount,
    required this.selectedToAccount,
    required this.selectedCategory,
    required this.onSelectAccount,
    required this.onSelectToAccount,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _selectionBox(
            label: type == TransactionType.transfer
                ? "From Account"
                : "Account",
            value: selectedAccount?.name ?? "Select",
            onTap: onSelectAccount,
          ),

          const SizedBox(height: 8),

          if (type == TransactionType.transfer)
            _selectionBox(
              label: "To Account",
              value: selectedToAccount?.name ?? "Select",
              onTap: onSelectToAccount,
            ),

          if (type != TransactionType.transfer)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _selectionBox(
                label: "Category",
                value: selectedCategory?.name ?? "Select",
                onTap: onSelectCategory,
              ),
            ),
        ],
      ),
    );
  }

  Widget _selectionBox({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54)),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
