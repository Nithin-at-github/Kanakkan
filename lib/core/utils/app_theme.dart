import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  /// Global bridge for legacy static calls that don't have context.
  /// Set by ThemeProvider when the app starts or theme changes.
  static bool isDarkMode = false;

  /// Core Palette - Now dynamic based on [isDarkMode]
  static Color get primary =>
      isDarkMode ? const Color(0xFF1E1E2C) : const Color(0xFF2D2438);
  static Color get background =>
      isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5DC);
  static Color get accent =>
      isDarkMode ? const Color(0xFFC5A059) : const Color(0xFFC5A059);
  static Color get success =>
      isDarkMode ? const Color(0xFF43A047) : const Color(0xFF2E7D32);
  static Color get error =>
      isDarkMode ? const Color(0xFFE53935) : const Color(0xFFC62828);

  /// Surface colors for cards and sheets
  static Color get surface =>
      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  static Color get onSurface =>
      isDarkMode ? Colors.white.withValues(alpha: 0.9) : Colors.black87;
  static Color get onSurfaceVariant =>
      isDarkMode ? Colors.white60 : Colors.black54;
  static Color get divider => isDarkMode ? Colors.white12 : Colors.black12;
  static Color get outline => isDarkMode ? Colors.white24 : Colors.black26;

  static ThemeData lightTheme = _buildTheme(Brightness.light);
  static ThemeData darkTheme = _buildTheme(Brightness.dark);

  static Color get warning => isDarkMode
      ? const Color.fromARGB(190, 255, 153, 0)
      : const Color.fromARGB(190, 255, 153, 0);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primaryColor = isDark
        ? const Color(0xFF1E1E2C)
        : const Color(0xFF2D2438);
    final Color backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5DC);
    final Color accentColor = isDark
        ? const Color(0xFFC5A059)
        : const Color(0xFFC5A059);
    final Color surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color onSurfaceColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black87;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Lato',

      // Refined Text Theme
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: onSurfaceColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: onSurfaceColor),
        bodyMedium: TextStyle(fontSize: 14, color: onSurfaceColor),
      ),

      scaffoldBackgroundColor: backgroundColor,
      canvasColor: surfaceColor,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        error: isDark ? const Color(0xFFE53935) : const Color(0xFFC62828),
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        surfaceContainer: surfaceColor,
        surfaceContainerHigh: surfaceColor,
        surfaceContainerHighest: surfaceColor,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withValues(alpha: 0.25),
        selectionHandleColor: accentColor,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'Lato',
          fontSize: 20,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: accentColor,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black45,
      ),

      popupMenuTheme: PopupMenuThemeData(color: surfaceColor),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : Colors.black54,
          side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black54),
        floatingLabelStyle: TextStyle(color: accentColor),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        prefixIconColor: isDark ? Colors.white : Colors.black54,
        suffixIconColor: isDark ? Colors.white : Colors.black54,
      ),
    );
  }
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
