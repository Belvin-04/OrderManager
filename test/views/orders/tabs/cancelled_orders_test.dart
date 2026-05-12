import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/views/orders/tabs/cancelled_orders.dart';
import '../../../test_helper.dart';

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
