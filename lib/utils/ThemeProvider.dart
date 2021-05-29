import 'package:flutter/material.dart';
import 'package:order_manager/utils/DarkThemePreference.dart';

class ThemeProvider extends ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  bool _darkTheme = false;

  bool get isdarkMode => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    darkThemePreference.setTheme(value);
    notifyListeners();
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
