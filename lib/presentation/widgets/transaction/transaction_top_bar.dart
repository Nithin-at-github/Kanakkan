import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/widgets/animations/pressable_scale.dart';

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
            icon: Icon(Icons.close, color: AppTheme.accent),
            label: Text(
              "CANCEL",
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
          PressableScale(
            child: TextButton.icon(
              onPressed: onSave,
              icon: Icon(Icons.check, color: AppTheme.accent),
              label: Text("SAVE", style: TextStyle(color: AppTheme.accent)),
            ),
          ),
        ],
      ),
    );
  }
}
