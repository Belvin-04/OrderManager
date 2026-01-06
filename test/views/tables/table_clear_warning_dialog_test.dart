import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/views/tables/table_clear_warning_dialog.dart';

Future<void> pumpTableClearWarningDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const TableClearWarningDialog(),
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
  testWidgets('shows table clear warning message', (tester) async {
    await pumpTableClearWarningDialog(tester);

    expect(
      find.text('Table cannot be cleared if there are pending orders...!'),
      findsOneWidget,
    );
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('dialog closes when OK is pressed', (tester) async {
    await pumpTableClearWarningDialog(tester);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
