import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/orders/order_save_dialog.dart';
import 'package:order_manager/views/orders/tabs/pending_orders.dart';

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

Future<void> pumpPendingOrders(
  WidgetTester tester, {
  required AsyncValue<List<Order>> ordersState,
  FakeOrdersViewModel? fakeVm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pendingOrdersProvider('1').overrideWithValue(ordersState),
        if (fakeVm != null) ordersViewModelProvider.overrideWith(() => fakeVm),
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
  testWidgets('shows loading indicator', (tester) async {
    await pumpPendingOrders(tester, ordersState: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message', (tester) async {
    await pumpPendingOrders(
      tester,
      ordersState: AsyncError('boom', StackTrace.current),
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows no pending orders message', (tester) async {
    await pumpPendingOrders(tester, ordersState: const AsyncData([]));

    expect(find.text('No pending orders'), findsOneWidget);
  });

  testWidgets('renders pending orders list', (tester) async {
    final order = baseOrder();

    await pumpPendingOrders(tester, ordersState: AsyncData([order]));

    expect(find.text(order.getData()), findsOneWidget);
  });

  testWidgets('FAB opens order save dialog', (tester) async {
    await pumpPendingOrders(tester, ordersState: const AsyncData([]));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
  });

  testWidgets('complete icon completes order and shows snackbar', (
    tester,
  ) async {
    final order = baseOrder();
    final fakeVm = FakeOrdersViewModel();

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(fakeVm.completedOrder, order);
    expect(find.text('Order Completed Successfully...'), findsOneWidget);
  });

  testWidgets('edit icon opens order save dialog', (tester) async {
    final order = baseOrder();

    await pumpPendingOrders(tester, ordersState: AsyncData([order]));

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
  });

  testWidgets('cancel icon cancels order and shows snackbar', (tester) async {
    final order = baseOrder();
    final fakeVm = FakeOrdersViewModel();

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();

    expect(fakeVm.canceledOrder, order);
    expect(find.text('Order Canceled Successfully...'), findsOneWidget);
  });

  testWidgets('saving order saves order and shows snackbar', (tester) async {
    final order = baseOrder();

    final fakeVM = FakeOrdersViewModel();

    await pumpPendingOrders(
      tester,
      ordersState: AsyncData([order]),
      fakeVm: fakeVM,
    );

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.byType(OrderSaveDialog), findsOneWidget);
    await tester.tap(find.text("Save Order"));
    await tester.pumpAndSettle();
    expect(find.text("Order Saved Successfully...!"), findsOneWidget);
  });
}
