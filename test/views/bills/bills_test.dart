import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/bills_provider.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/views/bills/bills.dart';
import 'package:order_manager/views/bills/bills_split.dart';
import 'package:order_manager/views/bills/split_bill_dialog.dart';
import '../../test_helper.dart';

Future<void> pumpBillsScreen(
  WidgetTester tester, {
  required AsyncValue<List<Order>> orders,
  required MockOrderRepository orderRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billOrdersProvider('1').overrideWithValue(orders),
        billTotalsProvider(
          '1',
        ).overrideWithValue({'quantity': 3, 'amount': 450}),
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: MaterialApp(home: Bills(Table1(id: 't1', tableNo: 1))),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('shows loading indicator', (tester) async {
    final orderRepo = MockOrderRepository();

    await pumpBillsScreen(
      tester,
      orders: const AsyncLoading(),
      orderRepo: orderRepo,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error when billOrdersProvider fails', (tester) async {
    final orderRepo = MockOrderRepository();

    await pumpBillsScreen(
      tester,
      orders: AsyncError('error', StackTrace.current),
      orderRepo: orderRepo,
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows No orders found when list empty', (tester) async {
    final orderRepo = MockOrderRepository();

    await pumpBillsScreen(
      tester,
      orders: const AsyncData([]),
      orderRepo: orderRepo,
    );

    expect(find.text('No orders found.'), findsOneWidget);
  });

  testWidgets('renders bill rows correctly', (tester) async {
    final orderRepo = MockOrderRepository();

    final orders = [
      baseOrder(
        item: Item(id: 'i1', name: 'Burger', price: 100),
        quantity: 2,
        amount: 200,
        type: Type1(id: 't1', type: 'Extra', price: 20),
      ),
    ];

    await pumpBillsScreen(
      tester,
      orders: AsyncData(orders),
      orderRepo: orderRepo,
    );

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
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.hasAnyOrdersForTable(any(), isSplit: true),
    ).thenAnswer((_) async => false);

    await pumpBillsScreen(
      tester,
      orders: const AsyncData([]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.receipt_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SplitBillDialog), findsOneWidget);
  });

  testWidgets('split bill creates split orders and navigates', (tester) async {
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream<int>.empty());

    when(
      () => orderRepo.saveOrders(any(), isSplit: true),
    ).thenAnswer((_) async => {});

    when(
      () => orderRepo.watchNonCanceledOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([baseOrder()]));

    when(
      () => orderRepo.hasAnyOrdersForTable(any(), isSplit: true),
    ).thenAnswer((_) async => false);

    await pumpBillsScreen(
      tester,
      orders: AsyncData([baseOrder()]),
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.receipt_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '3');
    await tester.tap(find.text('Split'));
    await tester.pumpAndSettle();

    verify(() => orderRepo.saveOrders(any(), isSplit: true)).called(1);
    verify(() => orderRepo.hasAnyOrdersForTable("1", isSplit: true)).called(1);
    expect(find.byType(SplitBillDialog), findsNothing);
    expect(find.byType(BillsSplit), findsOneWidget);
  });

  testWidgets(
    """split bill does not create split orders if already present and shows snackbar""",
    (tester) async {
      final orderRepo = MockOrderRepository();

      when(
        () => orderRepo.getTotalAmountForTable(
          any(),
          splitNo: any(named: 'splitNo'),
        ),
      ).thenAnswer((_) => const Stream<int>.empty());

      when(
        () => orderRepo.saveOrders(any(), isSplit: true),
      ).thenAnswer((_) async => {});

      when(
        () => orderRepo.watchNonCanceledOrdersForTable(any()),
      ).thenAnswer((_) => Stream.value([baseOrder()]));

      when(
        () => orderRepo.hasAnyOrdersForTable(any(), isSplit: true),
      ).thenAnswer((_) async => true);

      await pumpBillsScreen(
        tester,
        orders: AsyncData([baseOrder()]),
        orderRepo: orderRepo,
      );

      await tester.tap(find.byIcon(Icons.receipt_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '3');
      await tester.tap(find.text('Split'));
      await tester.pumpAndSettle();

      verifyNever(() => orderRepo.saveOrders(any(), isSplit: true));
      verify(
        () => orderRepo.hasAnyOrdersForTable("1", isSplit: true),
      ).called(1);
      expect(find.byType(SplitBillDialog), findsNothing);
      expect(find.byType(BillsSplit), findsNothing);
      expect(
        find.text("Someone has already created split orders"),
        findsOneWidget,
      );
    },
  );
}
