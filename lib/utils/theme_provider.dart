import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = "themeStatus";

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDark = prefs.getBool(_themeKey) ?? false;
    state = savedDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, dark);
    state = dark ? ThemeMode.dark : ThemeMode.light;
  }
}

class MyThemes {
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: Colors.grey.shade900,
    primaryColor: Colors.black,
    colorScheme: ColorScheme.dark(),
  );
  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.white,
    colorScheme: ColorScheme.light(),
  );
  static ThemeMode getTheme(bool darkMode) {
    if (darkMode) {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }
}
