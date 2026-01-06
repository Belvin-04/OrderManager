import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/views/tables/tables_warning_dialog.dart';

Future<void> pumpTablesWarningDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const TablesWarningDialog(),
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
  testWidgets('shows tables delete warning message', (tester) async {
    await pumpTablesWarningDialog(tester);

    expect(find.text('Please clear the table to delete...!'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('dialog closes when OK is pressed', (tester) async {
    await pumpTablesWarningDialog(tester);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
