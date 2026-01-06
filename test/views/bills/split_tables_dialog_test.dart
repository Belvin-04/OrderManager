import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/bills/split_tables_dialog.dart';

import '../utils.dart';

Future<void> pumpSplitTablesDialog(
  WidgetTester tester, {
  required int totalSplit,
  required void Function(int) onTap,
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
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) =>
                      SplitTablesDialog(totalSplit: totalSplit, onTap: onTap),
                );
              },
              child: const Text('Open'),
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
  testWidgets('shows split list based on totalSplit', (tester) async {
    await pumpSplitTablesDialog(tester, totalSplit: 3, onTap: (_) {});

    expect(find.text('Select Split No to Split'), findsOneWidget);
    expect(find.text('Split No.: 1'), findsOneWidget);
    expect(find.text('Split No.: 2'), findsOneWidget);
    expect(find.text('Split No.: 3'), findsOneWidget);
  });

  testWidgets('calls onTap with selected split number', (tester) async {
    int? selectedSplit;

    await pumpSplitTablesDialog(
      tester,
      totalSplit: 4,
      onTap: (value) {
        selectedSplit = value;
      },
    );

    await tester.tap(find.text('Split No.: 2'));
    await tester.pumpAndSettle();

    expect(selectedSplit, 2);
  });

  testWidgets('dialog closes after selecting split', (tester) async {
    await pumpSplitTablesDialog(tester, totalSplit: 2, onTap: (_) {});

    await tester.tap(find.text('Split No.: 1'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    await pumpSplitTablesDialog(
      tester,
      totalSplit: 2,
      onTap: (_) {},
      themeMode: ThemeMode.dark,
    );

    expect(find.text('Split No.: 1'), findsOneWidget);
  });
}
