import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/views/bills/split_bill_dialog.dart';

Future<void> pumpSplitBillDialog(
  WidgetTester tester, {
  required Table1 table,
  required void Function(int) onSplit,
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
                      SplitBillDialog(table: table, onSplit: onSplit),
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
  testWidgets('shows split bill dialog', (tester) async {
    await pumpSplitBillDialog(
      tester,
      table: Table1(id: 't1', tableNo: 1),
      onSplit: (_) {},
    );

    expect(find.text('Split Bill for how many persons?'), findsOneWidget);
    expect(find.text('Number of Persons'), findsOneWidget);
    expect(find.text('Split'), findsOneWidget);
  });

  testWidgets('shows error when input is empty', (tester) async {
    await pumpSplitBillDialog(
      tester,
      table: Table1(id: 't1', tableNo: 1),
      onSplit: (_) {},
    );

    await tester.tap(find.text('Split'));
    await tester.pumpAndSettle();

    expect(find.text('Please Enter Quantity'), findsOneWidget);
  });

  testWidgets('shows error when value is less than 2', (tester) async {
    await pumpSplitBillDialog(
      tester,
      table: Table1(id: 't1', tableNo: 1),
      onSplit: (_) {},
    );

    await tester.enterText(find.byType(TextFormField), '1');
    await tester.tap(find.text('Split'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bill should be split for at least 2 persons'),
      findsOneWidget,
    );
  });

  testWidgets('shows error for invalid number', (tester) async {
    await pumpSplitBillDialog(
      tester,
      table: Table1(id: 't1', tableNo: 1),
      onSplit: (_) {},
    );

    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('Split'));
    await tester.pumpAndSettle();

    expect(find.text('Please Enter Quantity'), findsOneWidget);
  });

  testWidgets('calls onSplit with valid number', (tester) async {
    int? splitValue;

    await pumpSplitBillDialog(
      tester,
      table: Table1(id: 't1', tableNo: 1),
      onSplit: (value) {
        splitValue = value;
      },
    );

    await tester.enterText(find.byType(TextFormField), '4');
    await tester.tap(find.text('Split'));
    await tester.pumpAndSettle();

    expect(splitValue, 4);
  });
}
