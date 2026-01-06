import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/views/items/item_edit_dialog.dart';

Future<void> pumpItemEditDialog(
  WidgetTester tester, {
  required Item initialItem,
  required Future<void> Function(Item) onSave,
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
                      ItemEditDialog(initialItem: initialItem, onSave: onSave),
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
  testWidgets('shows item edit dialog with fields', (tester) async {
    final item = Item(id: 'i1', name: 'Burger', price: 100);

    await pumpItemEditDialog(tester, initialItem: item, onSave: (_) async {});

    expect(find.text('Item Detail'), findsOneWidget);
    expect(find.text('Item Name'), findsOneWidget);
    expect(find.text('Item Price'), findsOneWidget);
    expect(find.text('Save Item'), findsOneWidget);
  });

  testWidgets('shows initial item values', (tester) async {
    final item = Item(id: 'i1', name: 'Burger', price: 100);

    await pumpItemEditDialog(tester, initialItem: item, onSave: (_) async {});

    expect(find.text('Burger'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('does not submit when fields are empty', (tester) async {
    bool called = false;

    await pumpItemEditDialog(
      tester,
      initialItem: Item(id: 'i1', name: '', price: 0),
      onSave: (_) async {
        called = true;
      },
    );

    await tester.tap(find.text('Save Item'));
    await tester.pumpAndSettle();

    expect(find.text('Please Enter Product Name'), findsOneWidget);
    expect(find.text('Please Enter Product Price'), findsOneWidget);
    expect(called, false);
  });

  testWidgets('calls onSave with updated item', (tester) async {
    Item? savedItem;

    final item = Item(id: 'i1', name: 'Burger', price: 100);

    await pumpItemEditDialog(
      tester,
      initialItem: item,
      onSave: (i) async {
        savedItem = i;
      },
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Pizza');
    await tester.enterText(find.byType(TextFormField).at(1), '150');

    await tester.tap(find.text('Save Item'));
    await tester.pumpAndSettle();

    expect(savedItem, isNotNull);
    expect(savedItem!.name, 'Pizza');
    expect(savedItem!.price, 150);
  });

  testWidgets('dialog closes after saving', (tester) async {
    await pumpItemEditDialog(
      tester,
      initialItem: Item(id: 'i1', name: 'Burger', price: 100),
      onSave: (_) async {},
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Pizza');
    await tester.enterText(find.byType(TextFormField).at(1), '150');

    await tester.tap(find.text('Save Item'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
