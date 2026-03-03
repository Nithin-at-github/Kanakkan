import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {

  const ReusableAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text(
          "I-W-¡-³-",
          style: TextStyle(
            fontFamily: 'Ravivarma',
            fontSize: 44,
            color: AppTheme.accent),
        ),
      );
  }

  @override
  // This is required to make the AppBar work with Scaffold
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
