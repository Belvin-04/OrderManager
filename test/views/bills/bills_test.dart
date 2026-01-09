import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/bills/bills.dart';
import 'package:order_manager/views/bills/bills_split.dart';
import 'package:order_manager/views/bills/split_bill_dialog.dart';

import '../fake_viewmodel/fake_orders_viewmodel.dart';

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
    item: item ?? Item(id: 'i', name: 'Burger', price: 100),
    type: type ?? Type1(id: 't', type: 'None', price: 0),
    table:
        table?.copyWith(splitNo: splitNo) ??
        testTable.copyWith(splitNo: splitNo),
    status: status,
    note: '',
    amount: amount,
  );
}

Future<void> pumpBillsScreen(
  WidgetTester tester, {
  required AsyncValue<List<Order>> orders,
  FakeOrdersViewModel? fakeVm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billOrdersProvider('1').overrideWithValue(orders),
        billTotalsProvider(
          '1',
        ).overrideWithValue({'quantity': 3, 'amount': 450}),
        if (fakeVm != null) ordersViewModelProvider.overrideWith(() => fakeVm),
      ],
      child: MaterialApp(home: Bills(Table1(id: 't1', tableNo: 1))),
    ),
  );
}

void main() {
  testWidgets('shows loading indicator', (tester) async {
    await pumpBillsScreen(tester, orders: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error when billOrdersProvider fails', (tester) async {
    await pumpBillsScreen(
      tester,
      orders: AsyncError('error', StackTrace.current),
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows No orders found when list empty', (tester) async {
    await pumpBillsScreen(tester, orders: const AsyncData([]));

    expect(find.text('No orders found.'), findsOneWidget);
  });

  testWidgets('renders bill rows correctly', (tester) async {
    final orders = [
      baseOrder(
        item: Item(id: 'i1', name: 'Burger', price: 100),
        quantity: 2,
        amount: 200,
        type: Type1(id: 't1', type: 'Extra', price: 20),
      ),
    ];

    await pumpBillsScreen(tester, orders: AsyncData(orders));

    expect(find.textContaining('Burger'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('100.0'), findsOneWidget);
  });

  testWidgets('shows totals in footer', (tester) async {
    final orders = [baseOrder()];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billOrdersProvider('1').overrideWithValue(AsyncData(orders)),
          billTotalsProvider(
            '1',
          ).overrideWithValue({'quantity': 3, 'amount': 450}),
        ],
        child: MaterialApp(home: Bills(Table1(id: 't1', tableNo: 1))),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('450'), findsOneWidget);
  });

  testWidgets('receipt icon opens SplitBillDialog', (tester) async {
    await pumpBillsScreen(tester, orders: const AsyncData([]));

    await tester.tap(find.byIcon(Icons.receipt_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SplitBillDialog), findsOneWidget);
  });

  testWidgets('split bill creates split orders and navigates', (tester) async {
    final fakeVm = FakeOrdersViewModel(stream: const Stream.empty());
    fakeVm.createSplitResult = true;

    await pumpBillsScreen(
      tester,
      orders: AsyncData([baseOrder()]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.receipt_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '3');
    await tester.tap(find.text('Split'));
    await tester.pumpAndSettle();

    expect(fakeVm.splitTableKey, '1');
    expect(find.byType(BillsSplit), findsOneWidget);
  });
}
