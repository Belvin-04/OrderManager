import 'dart:async';

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
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/tables/table_clear_dialog.dart';
import 'package:order_manager/views/tables/table_clear_warning_dialog.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_swap_dialog.dart';

import '../fake_viewmodel/fake_orders_viewmodel.dart';

class MockTableRepository extends Mock implements TableRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeTable1 extends Fake implements Table1 {}

Future<void> pumpHomePageScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tablesState,
  required MockTableRepository tableRepo,
  required MockOrderRepository orderRepo,
  Stream<int>? stream,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tablesProvider.overrideWithValue(tablesState),
        tableRepositoryProvider.overrideWithValue(tableRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
        ordersViewModelProvider.overrideWith(
          () => FakeOrdersViewModel(stream: stream),
        ),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Offset.zero);
    registerFallbackValue(FakeTable1());
  });

  testWidgets('shows loading indicator while tables load', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: const AsyncLoading(),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when tables fail to load', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncError('boom', StackTrace.current),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows No Items when tables list is empty', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: const AsyncData([]),
      stream: Stream.value(10),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.text('No Items'), findsOneWidget);
  });

  testWidgets('renders tables sorted by table number', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      stream: const Stream.empty(),
    );

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();

    expect(tiles[0].title.toString(), contains('1'));
    expect(tiles[1].title.toString(), contains('2'));
  });

  testWidgets('tapping Take Order navigates to Orders screen', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: Stream.value(0),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(Orders), findsOneWidget);
  });

  testWidgets(
    """clear table icon opens confirm dialog and confirm clear calls clearTableConfirm and shows snackbar""",
    (tester) async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      when(
        () => orderRepo.hasAnyOrdersForTable(any()),
      ).thenAnswer((_) async => true);

      when(
        () => orderRepo.hasPendingOrdersForTable(any()),
      ).thenAnswer((_) async => false);

      when(
        () => orderRepo.deleteOrdersForTable(any()),
      ).thenAnswer((_) async {});

      await pumpHomePageScreen(
        tester,
        tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
        tableRepo: tableRepo,
        orderRepo: orderRepo,
        stream: const Stream.empty(),
      );

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(TableClearDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      verify(() => orderRepo.deleteOrdersForTable('1')).called(1);
      expect(find.text("Table cleared Successfully..."), findsOneWidget);
    },
  );

  testWidgets('clear table icon shows already cleared snackbar', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.hasAnyOrdersForTable(any()),
    ).thenAnswer((_) async => false);

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text("Table is already cleared ..."), findsOneWidget);
  });

  testWidgets('clear table icon shows has pending order warning', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.hasAnyOrdersForTable(any()),
    ).thenAnswer((_) async => true);

    when(
      () => orderRepo.hasPendingOrdersForTable(any()),
    ).thenAnswer((_) async => true);

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.byType(TableClearWarningDialog), findsOneWidget);
  });

  testWidgets("""swap table icon opens dialog and shows snackbar on swap""", (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    when(tableRepo.watchTables).thenAnswer(
      (_) => Stream.value([
        Table1(id: 't1', tableNo: 1),
        Table1(id: 't2', tableNo: 2),
      ]),
    );

    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => {1});

    when(() => orderRepo.getOrdersForTable('1')).thenAnswer(
      (_) async => [
        Order(
          quantity: 1,
          id: 'o1',
          item: Item(name: 'name', price: 10, id: 'i1'),
          table: Table1(id: 't1', tableNo: 1),
          type: Type1(type: 'type', price: 10, id: 'ty1'),
          status: 'pending',
          note: '',
          amount: 20,
        ),
      ],
    );

    when(() => orderRepo.moveOrders(any(), any())).thenAnswer((_) async {});

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(find.byType(TableSwapDialog), findsOneWidget);

    await tester.tap(find.text('Table No. : 2'));
    await tester.pumpAndSettle();

    verify(() => orderRepo.moveOrders('1', '2')).called(1);
    expect(
      find.textContaining('Orders swapped from Table : 1 to Table : 2'),
      findsOneWidget,
    );
  });

  testWidgets('swap table shows no free tables snackbar', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    when(
      tableRepo.watchTables,
    ).thenAnswer((_) => Stream.value([Table1(id: 't1', tableNo: 1)]));

    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => {1});

    when(() => orderRepo.getOrdersForTable(any())).thenAnswer(
      (_) async => [
        Order(
          quantity: 1,
          id: 'o1',
          item: Item(name: 'name', price: 10, id: 'i1'),
          table: Table1(id: 't1', tableNo: 1),
          type: Type1(type: 'type', price: 10, id: 'ty1'),
          status: 'pending',
          note: '',
          amount: 20,
        ),
      ],
    );

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('There are no free tables....!'),
      findsOneWidget,
    );
  });

  testWidgets('swap table shows no orders snackbar', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      tableRepo.watchTables,
    ).thenAnswer((_) => Stream.value([Table1(id: 't1', tableNo: 1)]));
    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => {});

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(find.textContaining('All tables are free...!'), findsOneWidget);
  });

  testWidgets("""swap table shows no order on source table snackbar""", (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      tableRepo.watchTables,
    ).thenAnswer((_) => Stream.value([Table1(id: 't1', tableNo: 1)]));
    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => {1});
    when(() => orderRepo.getOrdersForTable(any())).thenAnswer((_) async => []);

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('There are no orders on the table...!'),
      findsOneWidget,
    );
  });

  testWidgets('tapping layout icon navigates to TableLayoutScreen', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: const Stream.empty(),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.design_services));
    await tester.pumpAndSettle();

    expect(find.byType(TableLayoutScreen), findsOneWidget);
  });

  testWidgets('open navigation drawer', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: const Stream.empty(),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
  });

  testWidgets('back button closes drawer when open', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: const Stream.empty(),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });
}
