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
import 'package:order_manager/views/orders/tabs/pending_orders.dart';
import 'package:order_manager/views/orders/tabs/quick_orders_dialog.dart';

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

Future<void> pumpPendingOrders(
  WidgetTester tester, {
  required AsyncValue<List<Order>> ordersState,
  required MockOrderRepository orderRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pendingOrdersProvider('1').overrideWithValue(ordersState),
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PendingOrders(table: Table1(id: 't1', tableNo: 1)),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('shows loading indicator', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpPendingOrders(
      tester,
      ordersState: const AsyncLoading(),
      orderRepo: orderRepo,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpPendingOrders(
      tester,
      ordersState: AsyncError('boom', StackTrace.current),
      orderRepo: orderRepo,
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows no pending orders message', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpPendingOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
    );

    expect(find.text('No pending orders'), findsOneWidget);
  });

  testWidgets('renders pending orders list', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    expect(find.text(order.getData()), findsOneWidget);
  });

  testWidgets('FAB opens order save dialog', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpPendingOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
  });

  testWidgets('Quick Order FAB opens quick order dialog', (tester) async {
    final orderRepo = MockOrderRepository();
    await pumpPendingOrders(
      tester,
      ordersState: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.library_add_sharp));
    await tester.pumpAndSettle();

    expect(find.byType(QuickOrdersDialog), findsOneWidget);
  });

  testWidgets('complete icon completes order and shows snackbar', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();
    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    verify(() => orderRepo.saveOrder(any(), isSplit: false)).called(1);
    expect(find.text('Order Completed Successfully...'), findsOneWidget);
  });

  testWidgets('edit icon opens order save dialog', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
  });

  testWidgets('cancel icon cancels order and shows snackbar', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();
    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();

    verify(() => orderRepo.saveOrder(any(), isSplit: false)).called(1);
    expect(find.text('Order Canceled Successfully...'), findsOneWidget);
  });

  testWidgets('saving order saves order and shows snackbar', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();

    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
    await tester.tap(find.text("Save Order"));
    await tester.pumpAndSettle();
    verify(() => orderRepo.saveOrder(any(), isSplit: false)).called(1);
    expect(find.text("Order Saved Successfully...!"), findsOneWidget);
  });
}
