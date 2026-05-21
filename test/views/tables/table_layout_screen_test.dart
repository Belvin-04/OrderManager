import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/providers/utils_provider.dart';
import 'package:order_manager/utils/startup_screen_provider.dart';
import 'package:order_manager/utils/table_popup_overlay.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/startup/preferred_startup_screen.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';
import 'package:order_manager/views/tables/table_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../test_helper.dart';

Future<void> pumpTableLayoutScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tables,
  required MockTableRepository tableRepo,
  required MockOrderRepository orderRepo,
}) async {
  stubOrderRepoStatus(orderRepo);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tablesProvider.overrideWithValue(tables),

        tableRepositoryProvider.overrideWithValue(tableRepo),

        orderRepositoryProvider.overrideWithValue(orderRepo),
      ],
      child: MaterialApp(home: TableLayoutScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpLayoutWidget(
  WidgetTester tester,
  List<Widget> children,
) async {
  final orderRepo = MockOrderRepository();
  final tableRepo = MockTableRepository();
  stubOrderRepoStatus(orderRepo);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(orderRepo),
        tableRepositoryProvider.overrideWithValue(tableRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(children: [Stack(children: children)]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'startupScreen': 'home'});
    TablePopupOverlay.hide();
  });
  setUpAll(() {
    registerFallbackValue(Offset.zero);
  });
  testWidgets('shows loading indicator', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    stubOrderRepoStatus(orderRepo);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tablesProvider.overrideWithValue(const AsyncLoading()),

          tableRepositoryProvider.overrideWithValue(tableRepo),

          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: MaterialApp(home: TableLayoutScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncError('error', StackTrace.current),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('renders tables at their positions', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final table = Table1(id: 't1', tableNo: 1, position: const Offset(50, 100));

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([table]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final positioned = tester.widget<Positioned>(find.byType(Positioned).last);

    expect(positioned.left, 50);
    expect(positioned.top, 100);
  });

  testWidgets('dragging table updates its position', (tester) async {
    final table = Table1(id: 't1', tableNo: 1, position: const Offset(10, 10));

    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => tableRepo.updateTablePosition(any(), any()),
    ).thenAnswer((_) async {});

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([table]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final icon = find.byIcon(Icons.table_restaurant);
    final start = tester.getCenter(icon);

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(80, 120));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final captured =
        verify(
              () => tableRepo.updateTablePosition('t1', captureAny()),
            ).captured.single
            as Offset;

    expect(captured.dx, 90);
    expect(captured.dy, 130);
  });

  testWidgets('last table is painted on top (z-order)', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final t1 = Table1(id: 't1', tableNo: 1, position: const Offset(50, 50));

    final t2 = Table1(id: 't2', tableNo: 2, position: const Offset(50, 50));

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([t1, t2]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final stackFinder = find.byWidgetPredicate(
      (w) => w is Stack && w.children.any((c) => c is Positioned),
    );

    final stack = tester.widget<Stack>(stackFinder);

    final children = stack.children.whereType<Positioned>().toList();

    final last = children.last.child as TableWidget;
    final first = children.toList()[1].child as TableWidget;

    expect(last.table.id, 't2');
    expect(first.table.id, 't1');
  });

  testWidgets('dragging one table does not move the other', (tester) async {
    final t1 = Table1(id: 't1', tableNo: 1, position: const Offset(10, 10));

    final t2 = Table1(id: 't2', tableNo: 2, position: const Offset(200, 200));

    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => tableRepo.updateTablePosition(any(), any()),
    ).thenAnswer((_) async {});

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([t1, t2]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final icons = find.byIcon(Icons.table_restaurant);
    final secondTable = icons.at(1);

    final start = tester.getCenter(secondTable);

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    verify(() => tableRepo.updateTablePosition('t2', any())).called(1);
    verifyNever(() => tableRepo.updateTablePosition('t1', any()));
  });

  testWidgets('dragging one table does not move the other while overlapped', (
    tester,
  ) async {
    final t1 = Table1(id: 't1', tableNo: 1, position: const Offset(10, 10));

    final t2 = Table1(id: 't2', tableNo: 2, position: const Offset(10, 10));

    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => tableRepo.updateTablePosition(any(), any()),
    ).thenAnswer((_) async {});

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([t1, t2]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final icons = find.byIcon(Icons.table_restaurant);
    final secondTable = icons.at(1);

    final start = tester.getCenter(secondTable);

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    verify(() => tableRepo.updateTablePosition('t2', any())).called(1);
    verifyNever(() => tableRepo.updateTablePosition('t1', any()));
  });

  testWidgets('popup menu is always on top of all the tables - 1', (
    tester,
  ) async {
    await pumpLayoutWidget(tester, [
      Positioned(
        left: 0,
        top: 0,
        child: TableWidget(table: Table1(id: 'T1', tableNo: 1)),
      ),
      Positioned(
        left: 0,
        top: 50,
        child: TableWidget(table: Table1(id: 'T2', tableNo: 2)),
      ),
    ]);
    await tester.tap(find.text('T2'));
    await tester.pumpAndSettle();

    final popupFinder = find.byType(TablePopupMenu);
    expect(popupFinder, findsOneWidget);

    final popupRect = tester.getRect(popupFinder);
    final otherTableRect = tester.getRect(find.text('T1'));

    expect(popupRect.overlaps(otherTableRect), isTrue);
  });

  testWidgets('popup menu is always on top of all the tables - 2', (
    tester,
  ) async {
    await pumpLayoutWidget(tester, [
      Positioned(
        left: 0,
        top: 0,
        child: TableWidget(table: Table1(id: 'T2', tableNo: 2)),
      ),
      Positioned(
        left: 0,
        top: 50,
        child: TableWidget(table: Table1(id: 'T1', tableNo: 1)),
      ),
    ]);
    await tester.tap(find.text('T1'));
    await tester.pumpAndSettle();

    final popupFinder = find.byType(TablePopupMenu);
    expect(popupFinder, findsOneWidget);

    final popupRect = tester.getRect(popupFinder);
    final otherTableRect = tester.getRect(find.text('T2'));

    expect(popupRect.overlaps(otherTableRect), isTrue);
  });

  testWidgets('popup menu open and close behavior', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final tables = [
      Table1(id: 't1', tableNo: 1, position: const Offset(50, 100)),
      Table1(id: 't2', tableNo: 2, position: const Offset(150, 200)),
    ];

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData(tables),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final tableIcons = find.byIcon(Icons.table_restaurant);
    expect(tableIcons, findsNWidgets(2));

    await tester.tap(tableIcons.at(0));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);

    await tester.tap(tableIcons.at(1));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);

    await tester.tap(tableIcons.at(0));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);
  });

  testWidgets('popup menu closes on pressing back button', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final tables = [
      Table1(id: 't1', tableNo: 1, position: const Offset(50, 100)),
    ];

    stubOrderRepoStatus(orderRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tablesProvider.overrideWithValue(AsyncValue.data(tables)),
          tableRepositoryProvider.overrideWithValue(tableRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: const MaterialApp(home: PreferredStartupScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.design_services));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsNothing);
    expect(find.byType(HomePage), findsNothing);
    expect(find.byType(TableLayoutScreen), findsOneWidget);
  });

  testWidgets('back button keeps table layout when opened via replacement', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final tables = [
      Table1(id: 't1', tableNo: 1, position: const Offset(50, 100)),
    ];

    stubOrderRepoStatus(orderRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tablesProvider.overrideWithValue(AsyncValue.data(tables)),
          tableRepositoryProvider.overrideWithValue(tableRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: const MaterialApp(home: PreferredStartupScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.design_services));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsNothing);
    expect(find.byType(TableLayoutScreen), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets(
    """popup menu closes on first back, second back stays on table layout when opened via replacement""",
    (tester) async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      final tables = [
        Table1(id: 't1', tableNo: 1, position: const Offset(50, 100)),
      ];

      stubOrderRepoStatus(orderRepo);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tablesProvider.overrideWithValue(AsyncValue.data(tables)),
            tableRepositoryProvider.overrideWithValue(tableRepo),
            orderRepositoryProvider.overrideWithValue(orderRepo),
          ],
          child: const MaterialApp(home: PreferredStartupScreen()),
        ),
      );

      await tester.tap(find.byIcon(Icons.design_services));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.table_restaurant));
      await tester.pumpAndSettle();

      expect(find.byType(TablePopupMenu), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TablePopupMenu), findsNothing);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(TableLayoutScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TablePopupMenu), findsNothing);
      expect(find.byType(TableLayoutScreen), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
  );

  testWidgets('table layout screen has working navigation drawer', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubOrderRepoStatus(orderRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tablesProvider.overrideWithValue(
            AsyncValue.data([Table1(id: 't1', tableNo: 1)]),
          ),
          tableRepositoryProvider.overrideWithValue(tableRepo),
          orderRepositoryProvider.overrideWithValue(orderRepo),
        ],
        child: MaterialApp(home: TableLayoutScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
  });

  testWidgets('home icon updates startup preference and navigates to home', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'startupScreen': 'table_layout'});

    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubOrderRepoStatus(orderRepo);
    when(
      () => orderRepo.getTotalAmountForTable(
        any(),
        splitNo: any(named: 'splitNo'),
      ),
    ).thenAnswer((_) => const Stream.empty());

    final container = ProviderContainer(
      overrides: [
        tablesProvider.overrideWithValue(
          AsyncData([
            Table1(id: 't1', tableNo: 1, position: const Offset(10, 10)),
          ]),
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
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Home Screen'));
    await tester.pumpAndSettle();

    expect(container.read(startupScreenProvider), StartupScreen.home);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
