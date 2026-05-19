import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/item_providers.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/type_providers.dart';
import 'package:order_manager/views/orders/order_save_dialog.dart';
import 'package:order_manager/views/quick_orders.dart';
import '../test_helper.dart';

Future<void> pumpQuickOrders(
  WidgetTester tester, {
  required AsyncValue<List<Order>> ordersState,
  required MockOrderRepository orderRepo,
  MockItemsRepository? itemRepo,
  MockTypeRepository? typeRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quickOrdersProvider.overrideWithValue(ordersState),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        itemsProvider.overrideWithValue(
          AsyncData([Item(id: 'i1', name: 'Burger', price: 100)]),
        ),
        typesProvider.overrideWithValue(
          AsyncData([Type1(id: 't1', type: 'None', price: 0)]),
        ),
        if (itemRepo != null)
          itemRepositoryProvider.overrideWithValue(itemRepo),
        if (typeRepo != null)
          typeRepositoryProvider.overrideWithValue(typeRepo),
      ],
      child: const MaterialApp(home: Scaffold(body: QuickOrders())),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('shows loading indicator', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpQuickOrders(
      tester,
      ordersState: const AsyncLoading(),
      orderRepo: orderRepo,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpQuickOrders(
      tester,
      ordersState: AsyncError('boom', StackTrace.current),
      orderRepo: orderRepo,
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows no quick orders message', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpQuickOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
    );

    expect(find.text('No quick orders'), findsOneWidget);
  });

  testWidgets('renders pending orders list', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();

    await pumpQuickOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    expect(find.text(order.getData()), findsOneWidget);
  });

  testWidgets('FAB opens order save dialog when items and types exist', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();
    final itemRepo = MockItemsRepository();
    final typeRepo = MockTypeRepository();

    when(itemRepo.watchItems).thenAnswer(
      (_) => Stream.value([Item(id: 'i1', name: 'Burger', price: 100)]),
    );
    when(typeRepo.watchTypes).thenAnswer(
      (_) => Stream.value([Type1(id: 't1', type: 'None', price: 0)]),
    );
    when(itemRepo.itemsExist).thenAnswer((_) async => true);
    when(typeRepo.typesExist).thenAnswer((_) async => true);

    await pumpQuickOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
      itemRepo: itemRepo,
      typeRepo: typeRepo,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
  });

  testWidgets('FAB shows snackbar when types are empty', (tester) async {
    final orderRepo = MockOrderRepository();
    final itemRepo = MockItemsRepository();
    final typeRepo = MockTypeRepository();
    when(itemRepo.watchItems).thenAnswer(
      (_) => Stream.value([Item(id: 'i', name: 'Burger', price: 100)]),
    );
    when(typeRepo.watchTypes).thenAnswer((_) => Stream.value([]));
    when(itemRepo.itemsExist).thenAnswer((_) async => true);
    when(typeRepo.typesExist).thenAnswer((_) async => false);

    await pumpQuickOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
      itemRepo: itemRepo,
      typeRepo: typeRepo,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Please add items and types first'), findsOneWidget);
    expect(find.byType(OrderSaveDialog), findsNothing);
  });

  testWidgets('cancel icon deletes order and shows snackbar', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();
    when(
      () => orderRepo.deleteOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpQuickOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();

    verify(() => orderRepo.deleteOrder(any(), isSplit: false)).called(1);
    expect(find.text('Quick Order Deleted Successfully...'), findsOneWidget);
  });

  testWidgets('saving order saves order and shows snackbar', (tester) async {
    final orderRepo = MockOrderRepository();
    final itemRepo = MockItemsRepository();
    final typeRepo = MockTypeRepository();

    when(itemRepo.watchItems).thenAnswer(
      (_) => Stream.value([Item(id: 'i1', name: 'Burger', price: 100)]),
    );
    when(typeRepo.watchTypes).thenAnswer(
      (_) => Stream.value([Type1(id: 't1', type: 'None', price: 0)]),
    );
    when(itemRepo.itemsExist).thenAnswer((_) async => true);
    when(typeRepo.typesExist).thenAnswer((_) async => true);
    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpQuickOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
      itemRepo: itemRepo,
      typeRepo: typeRepo,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, "1");
    await tester.tap(find.text("Save Order"));
    await tester.pumpAndSettle();
    final captured =
        verify(
              () => orderRepo.saveOrder(captureAny(), isSplit: false),
            ).captured.first
            as Order;
    expect(captured.table.tableNo, 0);
    expect(find.text("Quick Order Created Successfully...!"), findsOneWidget);
  });
}
