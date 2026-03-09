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
import 'package:order_manager/views/orders/tabs/completed_orders.dart';

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

Future<void> pumpCompletedOrders(
  WidgetTester tester, {
  required AsyncValue<List<Order>> ordersState,
  required MockOrderRepository orderRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        completedOrdersProvider('1').overrideWithValue(ordersState),
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: MaterialApp(
        home: CompletedOrders(table: Table1(id: 't1', tableNo: 1)),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('shows loading indicator while completed orders load', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();

    await pumpCompletedOrders(
      tester,
      ordersState: const AsyncLoading(),
      orderRepo: orderRepo,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when completedOrdersProvider errors', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();

    await pumpCompletedOrders(
      tester,
      ordersState: AsyncError(Exception('Failed to load'), StackTrace.empty),
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Error:'), findsOneWidget);
    expect(find.textContaining('Failed to load'), findsOneWidget);
  });

  testWidgets('shows empty message when no completed orders exist', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();

    await pumpCompletedOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    expect(find.text('No completed orders'), findsOneWidget);
  });

  testWidgets('renders list of completed orders', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder(status: 'completed');
    await pumpCompletedOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    expect(find.textContaining(order.item.name), findsOneWidget);
    expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
  });

  testWidgets('repeat icon repeats order and shows snackbar', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder(status: 'completed');

    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    await pumpCompletedOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pumpAndSettle();

    verify(() => orderRepo.saveOrder(any(), isSplit: false)).called(1);
    expect(find.text('Order Repeated Successfully...'), findsOneWidget);
  });
}
