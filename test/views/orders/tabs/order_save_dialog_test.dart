import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/item_providers.dart';
import 'package:order_manager/providers/type_providers.dart';
import 'package:order_manager/views/orders/order_save_dialog.dart';

import '../../../test_helper.dart';

final testItems = [
  Item(id: 'i1', name: 'Burger', price: 100),
  Item(id: 'i2', name: 'Pizza', price: 150),
];

final testTypes = [
  Type1(id: 't1', type: 'None', price: 0),
  Type1(id: 't2', type: 'Extra', price: 20),
];

Future<void> pumpOrderSaveDialog(
  WidgetTester tester, {
  required Order initialOrder,
  required Future<void> Function(Order) onSave,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itemsProvider.overrideWithValue(AsyncValue.data(testItems)),
        typesProvider.overrideWithValue(AsyncValue.data(testTypes)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => OrderSaveDialog(
                    initialOrder: initialOrder,
                    onSave: onSave,
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
  testWidgets('renders order save dialog', (tester) async {
    await pumpOrderSaveDialog(
      tester,
      initialOrder: baseOrder(),
      onSave: (_) async {},
    );

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Item Name: '), findsOneWidget);
    expect(find.text('Item Type: '), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.text('Save Order'), findsOneWidget);
  });

  testWidgets("""renders sorted items and types in order save dialog""", (
    tester,
  ) async {
    await pumpOrderSaveDialog(
      tester,
      initialOrder: baseOrder(),
      onSave: (_) async {},
    );

    final itemDropdownButton = tester.widget<DropdownButton<Item>>(
      find.byType(DropdownButton<Item>),
    );
    final typeDropdownButton = tester.widget<DropdownButton<Type1>>(
      find.byType(DropdownButton<Type1>),
    );

    expect(itemDropdownButton.items![0].value!.name, "Burger");
    expect(itemDropdownButton.items![1].value!.name, "Pizza");
    expect(typeDropdownButton.items![0].value!.type, "Extra");
    expect(typeDropdownButton.items![1].value!.type, "None");
  });

  testWidgets('shows error when quantity is empty', (tester) async {
    await pumpOrderSaveDialog(
      tester,
      initialOrder: baseOrder(quantity: 0),
      onSave: (_) async {},
    );

    await tester.tap(find.text('Save Order'));
    await tester.pumpAndSettle();

    expect(find.text('Please Enter Quantity'), findsOneWidget);
  });

  testWidgets('shows error when quantity is 0', (tester) async {
    await pumpOrderSaveDialog(
      tester,
      initialOrder: baseOrder(quantity: 0),
      onSave: (_) async {},
    );

    await tester.enterText(find.byType(TextFormField).first, '0');

    await tester.tap(find.text('Save Order'));
    await tester.pumpAndSettle();

    expect(find.text('Please Enter Valid Quantity'), findsOneWidget);
  });

  testWidgets('calls onSave with edited order', (tester) async {
    Order? savedOrder;

    await pumpOrderSaveDialog(
      tester,
      initialOrder: baseOrder(),
      onSave: (order) async {
        savedOrder = order;
      },
    );

    await tester.enterText(find.byType(TextFormField).first, '2');

    await tester.enterText(find.byType(TextFormField).last, 'No onions');

    await tester.tap(find.text('Save Order'));
    await tester.pumpAndSettle();

    expect(savedOrder, isNotNull);
    expect(savedOrder!.quantity, 2);
    expect(savedOrder!.note, 'No onions');
  });

  testWidgets('changing item and type updates editedOrder', (tester) async {
    Order? savedOrder;

    await pumpOrderSaveDialog(
      tester,
      initialOrder: baseOrder(),
      onSave: (order) async {
        savedOrder = order;
      },
    );

    await tester.tap(find.text('Burger'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pizza').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Extra').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '1');

    await tester.tap(find.text('Save Order'));
    await tester.pumpAndSettle();

    expect(savedOrder!.item.name, 'Pizza');
    expect(savedOrder!.type.type, 'Extra');
  });

  testWidgets('shows loading indicator while types and items are loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typesProvider.overrideWithValue(const AsyncValue.loading()),
          itemsProvider.overrideWithValue(const AsyncValue.loading()),
        ],
        child: MaterialApp(
          home: OrderSaveDialog(
            initialOrder: baseOrder(),
            onSave: (_) async {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
  });

  testWidgets('shows error text when types and items fail to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          typesProvider.overrideWithValue(
            const AsyncValue.error('fail', StackTrace.empty),
          ),
          itemsProvider.overrideWithValue(
            const AsyncValue.error('fail', StackTrace.empty),
          ),
        ],
        child: MaterialApp(
          home: OrderSaveDialog(
            initialOrder: baseOrder(),
            onSave: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('Error loading types'), findsOneWidget);
    expect(find.text('Error loading items'), findsOneWidget);
  });

  testWidgets(
    'defaults to first item and type when initial order has no type and item',
    (tester) async {
      Order? savedOrder;

      await pumpOrderSaveDialog(
        tester,
        initialOrder: baseOrder(
          item: Item(name: '', price: 0, id: ''),
          type: Type1(id: '', type: '', price: 0),
        ),
        onSave: (order) async {
          savedOrder = order;
        },
      );

      await tester.enterText(find.byType(TextFormField).first, '1');

      await tester.tap(find.text('Save Order'));
      await tester.pumpAndSettle();

      expect(savedOrder!.type.type, 'Extra');
      expect(savedOrder!.item.name, 'Burger');
    },
  );
}
