import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class ConfirmDeleteDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: AppTheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text("Delete", style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
