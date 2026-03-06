import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class TransactionTopBar extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const TransactionTopBar({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: AppTheme.accent),
            label: const Text(
              "CANCEL",
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
          TextButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.check, color: AppTheme.accent),
            label: const Text("SAVE", style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}
