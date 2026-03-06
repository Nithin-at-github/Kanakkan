// ============================================================
// FIX 1: Replace MaterialPageRoute with a custom route that
// uses your app's background color and a clean slide transition.
// Put this in a shared file e.g. lib/core/utils/app_router.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({required this.page})
    : super(
        // This is the key — sets the barrier/background color to your
        // primary color so no white ever shows through during transition
        barrierColor: AppTheme.primary,
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up on push, slide down on pop — matches bottom sheet feel
          const begin = Offset(0.0, 0.04);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          final fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      );
}


// ============================================================
// FIX 2: Set scaffoldBackgroundColor in your MaterialApp theme
// so the navigator background is never white between routes.
//
// In your MaterialApp (likely main.dart or app.dart):
// ============================================================

/*
MaterialApp(
  theme: ThemeData(
    scaffoldBackgroundColor: AppTheme.primary,  // ADD THIS
    // ... rest of your theme
  ),
)
*/


// ============================================================
// FIX 3: Use AppPageRoute instead of MaterialPageRoute
// wherever you push AddTransactionScreen.
//
// In your transaction detail sheet (_editTransaction):
// ============================================================

/*
void _editTransaction(TransactionEntity tx, {TransactionEntity? pairedTransaction}) {
  Navigator.push(
    context,
    AppPageRoute(                           // <-- was MaterialPageRoute
      page: AddTransactionScreen(
        transaction: tx,
        pairedTransaction: pairedTransaction,
      ),
    ),
  );
}

// And wherever you push AddTransactionScreen for a new transaction:
Navigator.push(
  context,
  AppPageRoute(
    page: const AddTransactionScreen(),
  ),
);
*/