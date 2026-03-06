import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_router.dart';
import 'package:kanakkan/core/utils/app_theme.dart';
import 'package:kanakkan/presentation/screens/add_transaction_screen.dart';

class GlobalActionSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(),

              const SizedBox(height: 10),

              _actionTile(
                context,
                icon: Icons.swap_vert,
                title: "Add Transaction",
                color: AppTheme.accent,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    AppPageRoute(
                      page: const AddTransactionScreen(),
                    ),
                  );
                },
              ),

              _actionTile(
                context,
                icon: Icons.account_balance,
                title: "Add Account",
                color: AppTheme.success,
                onTap: () {
                  Navigator.pop(context);
                  // call account dialog
                },
              ),

              _actionTile(
                context,
                icon: Icons.category,
                title: "Add Category",
                color: AppTheme.error,
                onTap: () {
                  Navigator.pop(context);
                  // call category dialog
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  static Widget _handle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  static Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  static void showAccountAction(BuildContext context) {
    show(context);
  }

  static void showCategoryAction(BuildContext context) {
    show(context);
  }
}
