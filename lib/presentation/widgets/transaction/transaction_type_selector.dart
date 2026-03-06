import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';

class TransactionTypeSelector extends StatelessWidget {
  final TransactionType type;
  final bool multiMode;
  final Function(TransactionType) onTypeChanged;

  const TransactionTypeSelector({
    super.key,
    required this.type,
    required this.multiMode,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _typeButton("INCOME", TransactionType.income),
        _divider(),
        _typeButton("EXPENSE", TransactionType.expense),
        if (!multiMode) _divider(),
        if (!multiMode) _typeButton("TRANSFER", TransactionType.transfer),
      ],
    );
  }

  Widget _typeButton(String label, TransactionType t) {
    final selected = type == t;

    return GestureDetector(
      onTap: () => onTypeChanged(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: selected
              ? const Border(
                  bottom: BorderSide(color: AppTheme.accent, width: 2),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.accent : Colors.white54,
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
