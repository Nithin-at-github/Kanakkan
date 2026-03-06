import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class TransactionKeypad extends StatelessWidget {
  final Function(String) onKeyTap;

  const TransactionKeypad({super.key, required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    final keys = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", ".", "⌫"];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(35, 5, 35, 14),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (_, i) {
        final key = keys[i];

        return GestureDetector(
          onTap: () => onKeyTap(key),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent),
            ),
            child: Center(
              child: Text(
                key,
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
