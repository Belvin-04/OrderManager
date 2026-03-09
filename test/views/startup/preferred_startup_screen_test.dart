import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/startup/preferred_startup_screen.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'startupScreen': 'home'});
  });

  testWidgets('shows home page when startup preference is home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'startupScreen': 'home'});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tablesProvider.overrideWithValue(const AsyncData(<Table1>[])),
        ],
        child: const MaterialApp(home: PreferredStartupScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets(
    'shows table layout page when startup preference is table layout',
    (tester) async {
      SharedPreferences.setMockInitialValues({'startupScreen': 'table_layout'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tablesProvider.overrideWithValue(const AsyncData(<Table1>[])),
          ],
          child: const MaterialApp(home: PreferredStartupScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TableLayoutScreen), findsOneWidget);
    },
  );
}
