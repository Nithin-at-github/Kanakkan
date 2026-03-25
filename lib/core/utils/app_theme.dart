import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  /// Core Palette
  static const Color primary = Color(0xFF2D2438);
  static const Color background = Color(0xFFF5F5DC);
  static const Color accent = Color(0xFFC5A059);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Lato',

    // Refined Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
    ),

    scaffoldBackgroundColor: primary,
    canvasColor: Colors.white,

    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: primary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Colors.white,
      surfaceContainerHighest: Colors.white,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),

    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: accent,
      selectionColor: Color(0x40C5A059), // 25% opacity accent
      selectionHandleColor: accent,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false, // Left align title
      titleTextStyle: TextStyle(
        fontFamily: 'Lato',
        fontSize: 20,
        fontWeight: FontWeight.normal, // Remove bold
        color: Colors.white,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: accent,
      unselectedItemColor: Colors.black45,
    ),

    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0, // Flat design for modern look
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black54, // Muted color for "Cancel"
        side: const BorderSide(color: Colors.black12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// Formats a rupee amount with comma separators.
///
/// Examples:
///   formatAmt(999)                  → "999"
///   formatAmt(1200)                 → "1,200"
///   formatAmt(1200.50)              → "1,200.50"
///   formatAmt(1200, decimals: false)→ "1,200"
String formatAmt(double value, {bool decimals = true}) {
  if (decimals) {
    // #,##0.## → shows up to 2 decimal places, strips trailing zeros
    // 1200.00 → "1,200"   |   1200.50 → "1,200.50"
    return NumberFormat('#,##0.##', 'en_IN').format(value);
  } else {
    return NumberFormat('#,##0', 'en_IN').format(value);
  }
}
