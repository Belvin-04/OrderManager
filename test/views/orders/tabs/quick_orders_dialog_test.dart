import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/views/orders/tabs/quick_orders_dialog.dart';
import '../../../test_helper.dart';

Order fakeOrder(String name) {
  return baseOrder(
    id: name,
    item: Item(id: name, name: name, price: 10),
    type: Type1(id: "Regular", type: "Regular", price: 0),
    quantity: 0,
    amount: 0,
  );
}

void main() {
  setUp(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets("Shows loading indicator", (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickOrdersProvider.overrideWithValue(const AsyncLoading()),
        ],
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets("Shows error message", (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickOrdersProvider.overrideWithValue(
            const AsyncError("Failure", StackTrace.empty),
          ),
        ],
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    expect(find.textContaining("Error:"), findsOneWidget);
  });

  testWidgets("Displays sorted quick orders", (WidgetTester tester) async {
    final orders = [
      fakeOrder("Pizza"),
      fakeOrder("Burger"),
      fakeOrder("Coffee"),
      fakeOrder("Apple"),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [quickOrdersProvider.overrideWithValue(AsyncData(orders))],
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    await tester.pumpAndSettle();

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();

    final titles = tiles.map((tile) => (tile.title as Text).data!).toList();

    expect(
      titles,
      equals([
        "Apple Regular",
        "Burger Regular",
        "Coffee Regular",
        "Pizza Regular",
      ]),
    );
  });

  testWidgets("Increment updates quantity", (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickOrdersProvider.overrideWithValue(
            AsyncData([fakeOrder("Coffee")]),
          ),
        ],
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(find.text("1"), findsOneWidget);
  });

  testWidgets("Decrement updates quantity when greater than zero", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickOrdersProvider.overrideWithValue(
            AsyncData([fakeOrder("Coffee")]),
          ),
        ],
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(find.text("2"), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
    await tester.pump();

    expect(find.text("1"), findsOneWidget);
  });

  testWidgets("Decrement does not work when quantity is zero", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickOrdersProvider.overrideWithValue(
            AsyncData([fakeOrder("Coffee")]),
          ),
        ],
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("0"), findsOneWidget);

    final decrementFinder = find.widgetWithIcon(IconButton, Icons.remove);

    final decrementButton = tester.widget<IconButton>(decrementFinder);

    expect(decrementButton.onPressed, isNull);

    await tester.tap(decrementFinder);
    await tester.pump();

    expect(find.text("0"), findsOneWidget);
  });

  testWidgets("Clicking Add Orders calls saveOrder", (
    WidgetTester tester,
  ) async {
    final fakeRepo = MockOrderRepository();

    when(
      () => fakeRepo.saveOrder(any(), isSplit: false),
    ).thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quickOrdersProvider.overrideWithValue(
            AsyncData([fakeOrder("Coffee")]),
          ),
          orderRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    await tester.tap(find.text("Add Orders"));
    await tester.pumpAndSettle();

    verify(() => fakeRepo.saveOrder(any(), isSplit: false)).called(1);
  });

  testWidgets("Cart clears after saving", (WidgetTester tester) async {
    final fakeRepo = MockOrderRepository();

    when(
      () => fakeRepo.saveOrder(any(), isSplit: false),
    ).thenAnswer((_) async => {});

    final container = ProviderContainer(
      overrides: [
        quickOrdersProvider.overrideWithValue(AsyncData([fakeOrder("Coffee")])),
        orderRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: QuickOrdersDialog(table: testTable)),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    await tester.tap(find.text("Add Orders"));
    await tester.pumpAndSettle();

    final cartState = container.read(quickOrderCartProvider);

    expect(cartState.isEmpty, true);
  });
}
