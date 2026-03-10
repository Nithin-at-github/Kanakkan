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

    scaffoldBackgroundColor: background,

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
