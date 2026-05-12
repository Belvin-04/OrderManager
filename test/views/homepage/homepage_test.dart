import 'dart:async';

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
import 'package:order_manager/providers/utils_provider.dart';
import 'package:order_manager/utils/startup_screen_provider.dart';
import 'package:order_manager/utils/theme_provider.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/startup/preferred_startup_screen.dart';
import 'package:order_manager/views/tables/table_clear_dialog.dart';
import 'package:order_manager/views/tables/table_clear_warning_dialog.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_swap_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helper.dart';

Future<void> pumpHomePageScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tablesState,
  required MockTableRepository tableRepo,
  required MockOrderRepository orderRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tablesProvider.overrideWithValue(tablesState),
        tableRepositoryProvider.overrideWithValue(tableRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );
}

Future<void> pumpPreferredScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tablesState,
  required MockTableRepository tableRepo,
  required MockOrderRepository orderRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tablesProvider.overrideWithValue(tablesState),
        tableRepositoryProvider.overrideWithValue(tableRepo),
        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: const MaterialApp(home: PreferredStartupScreen()),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(Offset.zero);
    registerFallbackValue(FakeTable1());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'startupScreen': 'home',
      'themeStatus': false,
    });
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

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpHomePageScreen(
      tester,
      tablesState: const AsyncData([]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.text('No Items'), findsOneWidget);
  });

  testWidgets('renders tables sorted by table number', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();

    expect(tiles[0].title.toString(), contains('1'));
    expect(tiles[1].title.toString(), contains('2'));
  });

  testWidgets('tapping Take Order navigates to Orders screen', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => Stream.value(0));

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

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
        () => orderRepo.getTotalAmountForTable(
          any(),
          splitNo: any(named: 'splitNo'),
        ),
      ).thenAnswer((_) => const Stream.empty());

      when(
        () => orderRepo.hasAnyOrdersForTable(any()),
      ).thenAnswer((_) async => true);

      when(
        () => orderRepo.hasPendingOrdersForTable(any()),
      ).thenAnswer((_) async => false);

      when(
        () => orderRepo.deleteOrdersForTable(any()),
      ).thenAnswer((_) async {});

      when(
        () => orderRepo.watchOrdersForTable(any()),
      ).thenAnswer((_) => Stream.value([]));

      await pumpHomePageScreen(
        tester,
        tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      );

      await tester.pumpAndSettle();

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
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.hasAnyOrdersForTable(any()),
    ).thenAnswer((_) async => false);

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

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
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.hasAnyOrdersForTable(any()),
    ).thenAnswer((_) async => true);

    when(
      () => orderRepo.hasPendingOrdersForTable(any()),
    ).thenAnswer((_) async => true);

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.byType(TableClearWarningDialog), findsOneWidget);
  });

  testWidgets("""swap table icon opens dialog and shows snackbar on swap""", (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

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

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

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
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

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

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

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
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      tableRepo.watchTables,
    ).thenAnswer((_) => Stream.value([Table1(id: 't1', tableNo: 1)]));
    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => {});

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

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
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      tableRepo.watchTables,
    ).thenAnswer((_) => Stream.value([Table1(id: 't1', tableNo: 1)]));
    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => {1});
    when(() => orderRepo.getOrdersForTable(any())).thenAnswer((_) async => []);

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

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

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpPreferredScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.design_services));
    await tester.pumpAndSettle();

    expect(find.byType(TableLayoutScreen), findsOneWidget);
  });

  testWidgets(
    'tapping layout icon updates startup preference to table layout',
    (tester) async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      when(
        () => orderRepo.getTotalAmountForTable(
          any(),
          splitNo: any(named: 'splitNo'),
        ),
      ).thenAnswer((_) => const Stream.empty());

      final container = ProviderContainer(
        overrides: [
          tablesProvider.overrideWithValue(
            AsyncData([Table1(id: 't1', tableNo: 1)]),
          ),
          tableRepositoryProvider.overrideWithValue(tableRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PreferredStartupScreen()),
        ),
      );

      await tester.tap(find.byIcon(Icons.design_services));
      await tester.pumpAndSettle();

      expect(container.read(startupScreenProvider), StartupScreen.tableLayout);
      expect(find.byType(TableLayoutScreen), findsOneWidget);
    },
  );

  testWidgets('open navigation drawer', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
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

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets("table list background in orange color for pending table", (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([baseOrder()]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    final cards = tester.widgetList<Card>(find.byType(Card)).toList();

    expect(cards[0].color, Colors.orange[900]);
  });

  testWidgets("table list background in green color for completed table", (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([baseOrder(status: "completed")]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    final cards = tester.widgetList<Card>(find.byType(Card)).toList();

    expect(cards[0].color, Colors.green[900]);
  });

  testWidgets("table list background in red color for canceled table", (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([baseOrder(status: "canceled")]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    final cards = tester.widgetList<Card>(find.byType(Card)).toList();

    expect(cards[0].color, Colors.red[900]);
  });

  testWidgets("table list background has no color for empty table", (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    final cards = tester.widgetList<Card>(find.byType(Card)).toList();

    expect(cards[0].color, isNull);
  });

  testWidgets('shows Loading... when tableOrderStatus is loading', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => const Stream.empty());

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pump();

    expect(find.text('Loading...'), findsOneWidget);
  });

  testWidgets('shows Error when tableOrderStatus throws error', (tester) async {
    final tableRepo = MockTableRepository();
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
          tablesProvider.overrideWithValue(
            AsyncData([Table1(id: 't1', tableNo: 1)]),
          ),
          tableRepositoryProvider.overrideWithValue(tableRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
          tableOrderStatus('1').overrideWithValue(
            AsyncError(Exception("Error"), StackTrace.current),
          ),
        ],
        child: MaterialApp(home: HomePage()),
      ),
    );

    await tester.pump();

    expect(find.text('Error'), findsOneWidget);
  });

  testWidgets('changing dark theme switch updates app theme', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    SharedPreferences.setMockInitialValues({'themeStatus': false});

    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    when(
      () => orderRepo.watchOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tablesProvider.overrideWithValue(
            AsyncData([Table1(id: 't1', tableNo: 1)]),
          ),
          tableRepositoryProvider.overrideWithValue(tableRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeProvider);

            return MaterialApp(
              theme: MyThemes.lightTheme,
              darkTheme: MyThemes.darkTheme,
              themeMode: themeMode,
              home: HomePage(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final homeElement = tester.element(find.byType(HomePage));
    expect(Theme.of(homeElement).primaryColor, Colors.white);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(Switch),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final updatedHomeElement = tester.element(find.byType(HomePage));
    expect(Theme.of(updatedHomeElement).primaryColor, Colors.black);
  });
}
