import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/views/orders/tabs/cancelled_orders.dart';

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

Future<void> pumpCancelledOrders(
  WidgetTester tester, {
  required AsyncValue<List<Order>> ordersState,
  required MockOrderRepository orderRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cancelledOrdersProvider('1').overrideWithValue(ordersState),
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: MaterialApp(
        home: CancelledOrders(table: Table1(id: 't1', tableNo: 1)),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('shows loading indicator while loading', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpCancelledOrders(
      tester,
      ordersState: const AsyncLoading(),
      orderRepo: orderRepo,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when cancelledOrdersProvider errors', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();
    await pumpCancelledOrders(
      tester,
      ordersState: AsyncError(
        Exception('Something went wrong'),
        StackTrace.empty,
      ),
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Error:'), findsOneWidget);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('shows empty message when no cancelled orders', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpCancelledOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
    );

    expect(find.text('No cancelled orders'), findsOneWidget);
  });

  testWidgets('renders cancelled orders list', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder(status: 'canceled');

    await pumpCancelledOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    expect(find.textContaining('Item Name'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsOneWidget);
  });

  testWidgets('restore button calls restoreOrder and shows snackbar', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder(status: 'canceled');

    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    await pumpCancelledOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.restore));
    await tester.pumpAndSettle();

    verify(() => orderRepo.saveOrder(any(), isSplit: false)).called(1);
    expect(find.text('Order Restored Successfully...'), findsOneWidget);
  });
}
