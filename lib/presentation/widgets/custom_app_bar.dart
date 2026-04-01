import 'package:flutter/material.dart';
import 'package:kanakkan/presentation/screens/root/root_scaffold.dart';

class ReusableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  const ReusableAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.menu, color: theme.colorScheme.secondary),
        // Use the global key — always opens RootScaffold's drawer
        // regardless of which screen's Scaffold this AppBar is inside.
        onPressed: () => rootScaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(
        "I-W-¡-³-",
        style: TextStyle(
          fontFamily: 'Ravivarma',
          fontSize: 44,
          color: theme.colorScheme.secondary,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
