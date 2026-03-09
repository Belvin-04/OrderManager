import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/views/bills/bills.dart';
import 'package:order_manager/views/home_page/home_page.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockTableRepository extends Mock implements TableRepository {}

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
}) {
  return Order(
    id: id,
    quantity: quantity,
    item: Item(id: 'i', name: 'Burger', price: 100),
    type: type ?? Type1(id: 't', type: 'None', price: 0),
    table:
        table?.copyWith(splitNo: splitNo) ??
        testTable.copyWith(splitNo: splitNo),
    status: status,
    note: '',
    amount: amount,
  );
}

Future<void> pumpOrdersScreen(
  WidgetTester tester, {
  required MockOrderRepository orderRepo,
}) async {
  final table = Table1(id: 't1', tableNo: 1);
  final MockTableRepository mockTableRepo = MockTableRepository();
  when(
    () => orderRepo.watchOrdersForTable(any()),
  ).thenAnswer((_) => Stream.value([]));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tableRepositoryProvider.overrideWithValue(mockTableRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        tablesProvider.overrideWithValue(AsyncData([table])),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );

  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.event_note_outlined));

  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
  });
  testWidgets('shows all order tabs', (tester) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    expect(find.text('Pending Orders'), findsOneWidget);
    expect(find.text('Completed Orders'), findsOneWidget);
    expect(find.text('Canceled Orders'), findsOneWidget);
  });

  testWidgets('repeat all shows success snackbar', (tester) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.getOrdersForTable('1'),
    ).thenAnswer((_) async => [baseOrder(), baseOrder()]);

    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Repeat all'));
    await tester.pumpAndSettle();

    verify(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).called(2);
    expect(find.text('All orders repeated successfully...!'), findsOneWidget);
  });

  testWidgets('repeat all shows empty snackbar when no orders', (tester) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(() => orderRepo.getOrdersForTable('1')).thenAnswer((_) async => []);

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Repeat all'));
    await tester.pumpAndSettle();

    verifyNever(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    );

    expect(find.text('There are no orders to repeat...!'), findsOneWidget);
  });

  testWidgets('restore all shows success snackbar', (tester) async {
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(() => orderRepo.getOrdersForTable('1')).thenAnswer(
      (_) async => [
        baseOrder(status: 'canceled'),
        baseOrder(status: 'canceled'),
      ],
    );

    when(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async => {});

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();

    verify(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).called(2);
    expect(find.text('All orders restored successfully...!'), findsOneWidget);
  });

  testWidgets('restore all shows empty snackbar when no orders', (
    tester,
  ) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(() => orderRepo.getOrdersForTable('1')).thenAnswer((_) async => []);

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore all'));
    await tester.pumpAndSettle();

    verifyNever(
      () => orderRepo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    );

    expect(find.text('There are no canceled orders...!'), findsOneWidget);
  });

  testWidgets('bill option navigates to Bills screen', (tester) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bill'));
    await tester.pumpAndSettle();

    expect(find.byType(Bills), findsOneWidget);
  });

  testWidgets('back button navigates to home page', (tester) async {
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('back navigation button redirects to HomePage', (tester) async {
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpOrdersScreen(tester, orderRepo: orderRepo);

    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
