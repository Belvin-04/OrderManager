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
import 'package:order_manager/views/bills/bills_split.dart';
import 'package:order_manager/views/bills/split_orders_dialog.dart';
import 'package:order_manager/views/bills/split_tables_dialog.dart';

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

Future<void> pumpBillsSplitScreen(
  WidgetTester tester, {
  required AsyncValue<List<Order>> splitOrders,
  required MockOrderRepository orderRepo,
}) async {
  when(
    () =>
        orderRepo.getTotalAmountForTable(any(), splitNo: any(named: 'splitNo')),
  ).thenAnswer((_) => const Stream.empty());

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        splitOrdersProvider('1').overrideWithValue(splitOrders),
        orderRepositoryProvider.overrideWithValue(orderRepo),
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
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('BillsSplit shows loader while split orders are loading', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splitOrdersProvider('1').overrideWithValue(const AsyncLoading()),
          orderRepositoryProvider.overrideWithValue(orderRepo),
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
    final orderRepo = MockOrderRepository();
    final order = baseOrder();

    await pumpBillsSplitScreen(
      tester,
      splitOrders: AsyncData([order]),
      orderRepo: orderRepo,
    );

    expect(find.textContaining(order.item.name), findsOneWidget);
  });

  testWidgets('tapping order opens split dialog', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();

    await pumpBillsSplitScreen(
      tester,
      splitOrders: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(SplitTablesDialog), findsOneWidget);
  });

  testWidgets('selecting split assigns order', (tester) async {
    final orderRepo = MockOrderRepository();
    final order = baseOrder();

    when(
      () => orderRepo.saveOrder(order, isSplit: true),
    ).thenAnswer((_) async => {});

    await pumpBillsSplitScreen(
      tester,
      splitOrders: AsyncData([order]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Split No.: 1'));
    await tester.pump();

    final captured =
        verify(
              () => orderRepo.saveOrder(captureAny(), isSplit: true),
            ).captured.first
            as Order;
    expect(captured.table.splitNo, 1);
  });

  testWidgets('clear split calls resetSplitNo', (tester) async {
    final orderRepo = MockOrderRepository();

    when(() => orderRepo.getSplitOrders('1')).thenAnswer(
      (_) => Stream.value([baseOrder(splitNo: 1), baseOrder(splitNo: 2)]),
    );

    when(
      () => orderRepo.saveOrder(any(), isSplit: true),
    ).thenAnswer((_) async => {});

    await pumpBillsSplitScreen(
      tester,
      splitOrders: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.cancel_outlined).first);
    await tester.pump();

    verify(() => orderRepo.saveOrder(any(), isSplit: true)).called(1);
  });

  testWidgets('back removes split orders', (tester) async {
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.removeSplitOrdersForTable('1'),
    ).thenAnswer((_) async => true);

    await pumpBillsSplitScreen(
      tester,
      splitOrders: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    verify(() => orderRepo.removeSplitOrdersForTable('1')).called(1);
  });

  testWidgets('back removes split orders and pops screen', (tester) async {
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.removeSplitOrdersForTable('1'),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splitOrdersProvider(
            '1',
          ).overrideWithValue(const AsyncData(<Order>[])),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: MaterialApp(
          home: BillsSplit(table: Table1(id: 't1', tableNo: 1), totalSplit: 2),
        ),
      ),
    );

    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    verify(() => orderRepo.removeSplitOrdersForTable('1')).called(1);
  });

  testWidgets('shows error when split orders cannot be removed', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.removeSplitOrdersForTable(any()),
    ).thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splitOrdersProvider('1').overrideWithValue(const AsyncData([])),
          orderRepositoryProvider.overrideWithValue(orderRepo),
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
    verify(() => orderRepo.removeSplitOrdersForTable('1')).called(1);
  });

  testWidgets("tapping split table shows snackbar when no order", (
    WidgetTester tester,
  ) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getOrdersForSplitTable('1', '1'),
    ).thenAnswer((_) async => []);
    await pumpBillsSplitScreen(
      tester,
      splitOrders: AsyncData([baseOrder(id: '1')]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.text("Split No. : 1"));
    await tester.pumpAndSettle();
    expect(find.text("No orders on the split table"), findsOneWidget);
  });

  testWidgets("tapping split table shows split orders dialog", (
    WidgetTester tester,
  ) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getOrdersForSplitTable('1', "1"),
    ).thenAnswer((_) async => [baseOrder(id: "1", splitNo: 1)]);

    await pumpBillsSplitScreen(
      tester,
      splitOrders: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.text("Split No. : 1"));
    await tester.pumpAndSettle();

    verify(() => orderRepo.getOrdersForSplitTable("1", "1")).called(1);
    expect(find.byType(SplitOrdersDialog), findsOneWidget);
  });

  testWidgets(
    """tapping a split order inside the split order dialog calls the change split order method""",
    (WidgetTester tester) async {
      final orderRepo = MockOrderRepository();

      when(
        () => orderRepo.getOrdersForSplitTable(any(), any()),
      ).thenAnswer((_) async => [baseOrder(id: "1", splitNo: 1)]);

      when(
        () => orderRepo.saveOrder(any(), isSplit: true),
      ).thenAnswer((_) async => {});

      await pumpBillsSplitScreen(
        tester,
        splitOrders: const AsyncData([]),
        orderRepo: orderRepo,
      );

      await tester.tap(find.text("Split No. : 1"));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining("Burger"));

      final captured =
          verify(
                () => orderRepo.saveOrder(captureAny(), isSplit: true),
              ).captured.first
              as Order;
      expect(captured.item.name, "Burger");
      expect(captured.table.splitNo, 0);
    },
  );
}
