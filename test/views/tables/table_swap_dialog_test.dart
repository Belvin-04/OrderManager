import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/tables/table_swap_dialog.dart';

import '../utils.dart';

Future<void> pumpTableSwapDialog(
  WidgetTester tester, {
  required List<int> availableTables,
  required void Function(int) onSelect,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith(() => FakeThemeNotifier(themeMode)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => TableSwapDialog(
                      availableTables: availableTables,
                      onSelect: onSelect,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows available tables in swap dialog', (tester) async {
    await pumpTableSwapDialog(
      tester,
      availableTables: [1, 3, 5],
      onSelect: (_) {},
    );

    expect(find.text('Select Table No. to swap the order'), findsOneWidget);
    expect(find.text('Table No. : 1'), findsOneWidget);
    expect(find.text('Table No. : 3'), findsOneWidget);
    expect(find.text('Table No. : 5'), findsOneWidget);
  });

  testWidgets('selecting a table calls onSelect and closes dialog', (
    tester,
  ) async {
    int? selected;

    await pumpTableSwapDialog(
      tester,
      availableTables: [2, 4],
      onSelect: (value) {
        selected = value;
      },
    );

    await tester.tap(find.text('Table No. : 4'));
    await tester.pumpAndSettle();

    expect(selected, 4);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    await pumpTableSwapDialog(
      tester,
      availableTables: [1],
      onSelect: (_) {},
      themeMode: ThemeMode.dark,
    );

    expect(find.text('Table No. : 1'), findsOneWidget);
  });
}
