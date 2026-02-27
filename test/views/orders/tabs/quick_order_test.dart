import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/views/orders/tabs/quick_order.dart';

Item fakeItem(String name) => Item(id: name, name: name, price: 10);

Type1 fakeType(String type) => Type1(id: type, type: type, price: 0);

Table1 fakeTable() => Table1(id: "1", tableNo: 1);

Order fakeOrder(String name) {
  return Order(
    id: name,
    item: fakeItem(name),
    table: fakeTable(),
    type: fakeType("Regular"),
    quantity: 0,
    status: "pending",
    note: "",
    amount: 0,
  );
}

void main() {
  testWidgets("Displays item name and type", (WidgetTester tester) async {
    final order = fakeOrder("Coffee");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickOrder(
            order: order,
            quantity: 1,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );

    expect(find.text("Coffee Regular"), findsOneWidget);
  });

  testWidgets("Displays correct quantity", (WidgetTester tester) async {
    final order = fakeOrder("Burger");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickOrder(
            order: order,
            quantity: 3,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );

    expect(find.text("3"), findsOneWidget);
  });

  testWidgets("Increment button calls onIncrement", (
    WidgetTester tester,
  ) async {
    bool incrementCalled = false;
    final order = fakeOrder("Coffee");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickOrder(
            order: order,
            quantity: 1,
            onIncrement: () => incrementCalled = true,
            onDecrement: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(incrementCalled, true);
  });

  testWidgets("Decrement button is disabled when quantity is 0", (
    WidgetTester tester,
  ) async {
    final order = fakeOrder("Coffee");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickOrder(
            order: order,
            quantity: 0,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );

    final decrementFinder = find.widgetWithIcon(IconButton, Icons.remove);

    final decrementButton = tester.widget<IconButton>(decrementFinder);

    expect(decrementButton.onPressed, isNull);
  });

  testWidgets("Decrement button is enabled when quantity > 0", (
    WidgetTester tester,
  ) async {
    final order = fakeOrder("Coffee");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickOrder(
            order: order,
            quantity: 2,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );

    final decrementFinder = find.widgetWithIcon(IconButton, Icons.remove);

    final decrementButton = tester.widget<IconButton>(decrementFinder);

    expect(decrementButton.onPressed, isNotNull);
  });

  testWidgets("Decrement button calls onDecrement when enabled", (
    WidgetTester tester,
  ) async {
    bool decrementCalled = false;
    final order = fakeOrder("Coffee");

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickOrder(
            order: order,
            quantity: 2,
            onIncrement: () {},
            onDecrement: () => decrementCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(decrementCalled, true);
  });
}
