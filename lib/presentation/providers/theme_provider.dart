import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kanakkan/core/utils/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'user_theme_mode';
  final _storage = const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Loads the persisted theme mode from storage.
  Future<void> loadTheme() async {
    final savedMode = await _storage.read(key: _themeKey);
    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
    updateAppThemeStatic(_themeMode == ThemeMode.dark);
    notifyListeners();
  }

  /// Updates the theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _storage.write(key: _themeKey, value: mode.toString());
    updateAppThemeStatic(mode == ThemeMode.dark);
    notifyListeners();
  }

  /// Toggles between light and dark mode manually.
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Updates the static flag in AppTheme.
  void updateAppThemeStatic(bool isDark) {
    AppTheme.isDarkMode = isDark;
  }
}
