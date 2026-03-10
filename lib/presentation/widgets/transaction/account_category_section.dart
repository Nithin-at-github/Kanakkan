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
  final Category? selectedSubcategory;
  final VoidCallback onSelectAccount;
  final VoidCallback onSelectToAccount;
  final VoidCallback onSelectCategory;
  final VoidCallback onSelectSubcategory;

  const AccountCategorySection({
    super.key,
    required this.type,
    required this.selectedAccount,
    required this.selectedToAccount,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.onSelectAccount,
    required this.onSelectToAccount,
    required this.onSelectCategory,
    required this.onSelectSubcategory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          // ── ACCOUNT ROW ──
          if (type == TransactionType.transfer) ...[
            _SelectorBox(
              icon: Icons.account_balance,
              label: "From Account",
              value: selectedAccount?.name,
              onTap: onSelectAccount,
            ),
            const SizedBox(height: 10),
            _SelectorBox(
              icon: Icons.account_balance,
              label: "To Account",
              value: selectedToAccount?.name,
              onTap: onSelectToAccount,
            ),
          ] else ...[
            _SelectorBox(
              icon: Icons.account_balance,
              label: "Account",
              value: selectedAccount?.name,
              onTap: onSelectAccount,
            ),
            const SizedBox(height: 10),

            // ── SUBCATEGORY + CATEGORY ROW ──
            Row(
              children: [
                // Subcategory box (left)
                Expanded(
                  child: _SelectorBox(
                    icon: Icons.subdirectory_arrow_right,
                    label: "Subcategory",
                    value: selectedSubcategory?.name ?? "None",
                    valueColor: selectedSubcategory != null
                        ? null
                        : Colors.white38,
                    onTap: onSelectSubcategory,
                  ),
                ),
                const SizedBox(width: 10),
                // Category box (right)
                Expanded(
                  child: _SelectorBox(
                    icon: Icons.category,
                    label: "Category",
                    value: selectedCategory?.name,
                    // Dim slightly when auto-set by subcategory to hint it's linked
                    valueColor: selectedSubcategory != null
                        ? AppTheme.accent.withValues(alpha: 0.8)
                        : null,
                    onTap: onSelectCategory,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// SELECTOR BOX
// ─────────────────────────────────────────

class _SelectorBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback onTap;

  const _SelectorBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue ? AppTheme.accent.withValues(alpha: 0.5) : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasValue ? AppTheme.accent : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? value! : "Select",
                    style: TextStyle(
                      color:
                          valueColor ??
                          (hasValue ? Colors.white : Colors.white38),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
