import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';

class TransactionTypeSelector extends StatelessWidget {
  final TransactionType type;
  final bool multiMode;
  // Nullable — pass null to lock the selector (e.g. during transfer edit)
  final Function(TransactionType)? onTypeChanged;

  const TransactionTypeSelector({
    super.key,
    required this.type,
    required this.multiMode,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final locked = onTypeChanged == null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _typeButton("INCOME", TransactionType.income, locked),
        _divider(),
        _typeButton("EXPENSE", TransactionType.expense, locked),
        if (!multiMode) _divider(),
        if (!multiMode)
          _typeButton("TRANSFER", TransactionType.transfer, locked),
      ],
    );
  }

  Widget _typeButton(String label, TransactionType t, bool locked) {
    final selected = type == t;

    return GestureDetector(
      // No-op when locked — prevents orphaned transfer legs
      onTap: locked ? null : () => onTypeChanged!(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: selected
              ? Border(
                  bottom: BorderSide(color: AppTheme.accent, width: 2),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            // Dim all unselected labels further when locked to signal disabled state
            color: selected
                ? AppTheme.accent
                : locked
                ? Colors.white24
                : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Text("|", style: TextStyle(color: Colors.white54)),
  );
}
