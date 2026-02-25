import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/views/orders/order_save_dialog.dart';
import 'package:order_manager/views/quick_orders.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeOrder extends Fake implements Order {}

final testTable = Table1(id: 't', tableNo: 1);

Order baseOrder({
  String id = '',
  int quantity = 1,
  String status = 'pending',
  int amount = 100,
  int splitNo = 0,
  Table1? table,
  Type1? type,
  Item? item,
}) {
  return Order(
    id: id,
    quantity: quantity,
    item: item ?? Item(id: 'i1', name: 'Burger', price: 100),
    type: type ?? Type1(id: 't1', type: 'None', price: 0),
    table:
        table?.copyWith(splitNo: splitNo) ??
        testTable.copyWith(splitNo: splitNo),
    status: status,
    note: '',
    amount: amount,
  );
}

Future<void> pumpQuickOrders(
  WidgetTester tester, {
  required AsyncValue<List<Order>> ordersState,
  required MockOrderRepository orderRepo,
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

  testWidgets('FAB opens order save dialog', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpQuickOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
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

    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpQuickOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
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
