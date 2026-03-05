import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const ReusableAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primary,
      title: const Text(
        "I-W-¡-³-",
        style: TextStyle(
          fontFamily: 'Ravivarma',
          fontSize: 44,
          color: AppTheme.accent,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
