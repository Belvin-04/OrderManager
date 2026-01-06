import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/views/tables/table_clear_dialog.dart';

Future<void> pumpTableClearDialog(
  WidgetTester tester, {
  required Table1 table,
  required Future<void> Function(String) onClear,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) =>
                      TableClearDialog(table: table, onClear: onClear),
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
  testWidgets('shows table clear warning dialog', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await pumpTableClearDialog(tester, table: table, onClear: (_) async {});

    expect(find.text('WARNING...!'), findsOneWidget);
    expect(
      find.text('All order details will be lost after clearing the table...!'),
      findsOneWidget,
    );
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('calls onClear with table number as string', (tester) async {
    String? clearedTableKey;
    final table = Table1(id: 't1', tableNo: 1);

    await pumpTableClearDialog(
      tester,
      table: table,
      onClear: (key) async {
        clearedTableKey = key;
      },
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(clearedTableKey, '1');
  });

  testWidgets('dialog closes after clearing table', (tester) async {
    final table = Table1(id: 't1', tableNo: 1);

    await pumpTableClearDialog(tester, table: table, onClear: (_) async {});

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
