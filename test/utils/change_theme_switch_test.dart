import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/change_theme_switch.dart';
import 'package:order_manager/utils/theme_provider.dart';

class DarkThemeNotifier extends ThemeNotifier {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }
}

void main() {
  testWidgets('switch is OFF when theme is light', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: ChangeThemeSwitch())),
      ),
    );

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, false);
  });

  testWidgets('switch is ON when theme is dark', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themeProvider.overrideWith(DarkThemeNotifier.new)],
        child: const MaterialApp(home: Scaffold(body: ChangeThemeSwitch())),
      ),
    );

    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, true);
  });

  testWidgets('switch toggles to dark mode', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: ChangeThemeSwitch())),
      ),
    );

    Switch sw = tester.widget(find.byType(Switch));
    expect(sw.value, false);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    sw = tester.widget(find.byType(Switch));
    expect(sw.value, true);
  });
}
