import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/orders/tabs/completed_orders.dart';

import '../../fake_viewmodel/fake_orders_viewmodel.dart';

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
  FakeOrdersViewModel? fakeVm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        completedOrdersProvider('1').overrideWithValue(ordersState),
        if (fakeVm != null) ordersViewModelProvider.overrideWith(() => fakeVm),
      ],
      child: MaterialApp(
        home: CompletedOrders(table: Table1(id: 't1', tableNo: 1)),
      ),
    ),
  );
}

void main() {
  testWidgets('shows loading indicator while completed orders load', (
    tester,
  ) async {
    await pumpCompletedOrders(tester, ordersState: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when completedOrdersProvider errors', (
    tester,
  ) async {
    await pumpCompletedOrders(
      tester,
      ordersState: AsyncError(Exception('Failed to load'), StackTrace.empty),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Error:'), findsOneWidget);
    expect(find.textContaining('Failed to load'), findsOneWidget);
  });

  testWidgets('shows empty message when no completed orders exist', (
    tester,
  ) async {
    await pumpCompletedOrders(tester, ordersState: const AsyncData([]));

    await tester.pumpAndSettle();

    expect(find.text('No completed orders'), findsOneWidget);
  });

  testWidgets('renders list of completed orders', (tester) async {
    final order = baseOrder(status: 'completed');
    await pumpCompletedOrders(tester, ordersState: AsyncData([order]));

    await tester.pumpAndSettle();

    expect(find.textContaining(order.item.name), findsOneWidget);
    expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
  });

  testWidgets('repeat icon repeats order and shows snackbar', (tester) async {
    final order = baseOrder(status: 'completed');
    final fakeVm = FakeOrdersViewModel();

    await pumpCompletedOrders(
      tester,
      ordersState: AsyncData([order]),
      fakeVm: fakeVm,
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pumpAndSettle();

    expect(fakeVm.repeatedOrder, order);
    expect(find.text('Order Repeated Successfully...'), findsOneWidget);
  });
}
