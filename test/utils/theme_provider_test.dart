import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/providers.dart';
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
}
