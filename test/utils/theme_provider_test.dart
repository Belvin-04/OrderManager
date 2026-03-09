import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/utils_provider.dart';
import 'package:order_manager/utils/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('toggleTheme updates state to dark', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(themeProvider.notifier);

    await notifier.toggleTheme(isDark: true);

    expect(container.read(themeProvider), ThemeMode.dark);
  });

  test('darkTheme has correct dark colors', () {
    final theme = MyThemes.darkTheme;

    expect(theme.scaffoldBackgroundColor, Colors.grey.shade900);
    expect(theme.primaryColor, Colors.black);
    expect(theme.colorScheme.brightness, Brightness.dark);
  });

  test('lightTheme has correct light colors', () {
    final theme = MyThemes.lightTheme;

    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(theme.primaryColor, Colors.white);
    expect(theme.colorScheme.brightness, Brightness.light);
  });

  test('getTheme returns ThemeMode.dark when isDarkMode is true', () {
    final mode = MyThemes.getTheme(isDarkMode: true);
    expect(mode, ThemeMode.dark);
  });

  test('getTheme returns ThemeMode.light when isDarkMode is false', () {
    final mode = MyThemes.getTheme(isDarkMode: false);
    expect(mode, ThemeMode.light);
  });
}
