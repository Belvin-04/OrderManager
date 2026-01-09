import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/bills/bills_split.dart';
import 'package:order_manager/views/bills/split_tables_dialog.dart';

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

Future<void> pumpBillsSplitScreen(
  WidgetTester tester, {
  required AsyncValue<List<Order>> splitOrders,
  required FakeOrdersViewModel fakeVm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        splitOrdersProvider('1').overrideWithValue(splitOrders),
        ordersViewModelProvider.overrideWith(() => fakeVm),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BillsSplit(
                      table: Table1(id: 't1', tableNo: 1),
                      totalSplit: 2,
                    ),
                  ),
                );
              },
              child: const Text('Go'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('Go'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('BillsSplit shows loader while split orders are loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splitOrdersProvider('1').overrideWithValue(const AsyncLoading()),
          ordersViewModelProvider.overrideWith(
            () => FakeOrdersViewModel(stream: const Stream.empty()),
          ),
        ],
        child: MaterialApp(
          home: BillsSplit(table: Table1(id: 't1', tableNo: 1), totalSplit: 2),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows split orders', (tester) async {
    final fakeVm = FakeOrdersViewModel(stream: const Stream.empty());
    final order = baseOrder();

    await pumpBillsSplitScreen(
      tester,
      splitOrders: AsyncData([order]),
      fakeVm: fakeVm,
    );

    expect(find.textContaining(order.item.name), findsOneWidget);
  });

  testWidgets('tapping order opens split dialog', (tester) async {
    final fakeVm = FakeOrdersViewModel(stream: const Stream.empty());
    final order = baseOrder();

    await pumpBillsSplitScreen(
      tester,
      splitOrders: AsyncData([order]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(SplitTablesDialog), findsOneWidget);
  });

  testWidgets('selecting split assigns order', (tester) async {
    final fakeVm = FakeOrdersViewModel(stream: const Stream.empty());
    final order = baseOrder();

    await pumpBillsSplitScreen(
      tester,
      splitOrders: AsyncData([order]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Split No.: 1'));
    await tester.pump();

    expect(fakeVm.splitChanged, contains(order));
  });

  testWidgets('clear split calls resetSplitNo', (tester) async {
    final fakeVm = FakeOrdersViewModel(stream: const Stream.empty());

    await pumpBillsSplitScreen(
      tester,
      splitOrders: const AsyncData([]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.cancel_outlined).first);
    await tester.pump();

    expect(fakeVm.clearedSplits, contains('1'));
  });

  testWidgets('back removes split orders', (tester) async {
    final fakeVm = FakeOrdersViewModel(stream: const Stream.empty());

    await pumpBillsSplitScreen(
      tester,
      splitOrders: const AsyncData([]),
      fakeVm: fakeVm,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(fakeVm.removeSplitCalled, true);
  });

  testWidgets('back removes split orders and pops screen', (tester) async {
    final fakeVm = FakeOrdersViewModel(stream: const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splitOrdersProvider(
            '1',
          ).overrideWithValue(const AsyncData(<Order>[])),
          ordersViewModelProvider.overrideWith(() => fakeVm),
        ],
        child: MaterialApp(
          home: BillsSplit(table: Table1(id: 't1', tableNo: 1), totalSplit: 2),
        ),
      ),
    );

    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(fakeVm.removedSplitTableOrders, '1');
  });

  testWidgets('shows error when split orders cannot be removed', (
    tester,
  ) async {
    final fakeVm = FakeOrdersViewModel(
      splitRemovedresult: false,
      stream: const Stream.empty(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splitOrdersProvider('1').overrideWithValue(const AsyncData([])),
          ordersViewModelProvider.overrideWith(() => fakeVm),
        ],
        child: MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                return MaterialPageRoute(builder: (_) => const SizedBox());
              }
              return MaterialPageRoute(
                builder: (_) => BillsSplit(
                  table: Table1(id: 't1', tableNo: 1),
                  totalSplit: 2,
                ),
              );
            },
            initialRoute: '/bills',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pump();

    expect(find.text('Problem removing split orders'), findsOneWidget);
  });
}
