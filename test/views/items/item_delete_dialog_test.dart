import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/views/items/item_delete_dialog.dart';

Future<void> pumpItemDeleteDialog(
  WidgetTester tester, {
  required Item initialItem,
  required Future<void> Function(Item) onDelete,
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
                  builder: (_) => ItemDeleteDialog(
                    initialItem: initialItem,
                    onDelete: onDelete,
                  ),
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
  testWidgets('shows item delete confirmation dialog', (tester) async {
    final item = Item(id: 'i1', name: 'Burger', price: 100);

    await pumpItemDeleteDialog(
      tester,
      initialItem: item,
      onDelete: (_) async {},
    );

    expect(find.text('Delete Item ?'), findsOneWidget);
    expect(find.text('This action cannot be undone...'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('calls onDelete with the given item', (tester) async {
    Item? deletedItem;
    final item = Item(id: 'i1', name: 'Burger', price: 100);

    await pumpItemDeleteDialog(
      tester,
      initialItem: item,
      onDelete: (i) async {
        deletedItem = i;
      },
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(deletedItem, isNotNull);
    expect(deletedItem, item);
  });

  testWidgets('dialog closes after deleting item', (tester) async {
    final item = Item(id: 'i1', name: 'Burger', price: 100);

    await pumpItemDeleteDialog(
      tester,
      initialItem: item,
      onDelete: (_) async {},
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
