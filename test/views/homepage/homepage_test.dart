import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/tables/table_clear_dialog.dart';
import 'package:order_manager/views/tables/table_clear_warning_dialog.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_swap_dialog.dart';

import '../fake_viewmodel/fake_orders_viewmodel.dart';
import '../fake_viewmodel/fake_tables_viewmodel.dart';

Future<void> pumpHomePageScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tablesState,
  FakeTablesViewModel? fakeVm,
  Stream<int>? stream,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tablesProvider.overrideWithValue(tablesState),
        if (fakeVm != null) tablesViewmodelProvider.overrideWith(() => fakeVm),
        ordersViewModelProvider.overrideWith(
          () => FakeOrdersViewModel(stream: stream),
        ),
      ],
      child: MaterialApp(home: HomePage()),
    ),
  );
}

void main() {
  testWidgets('shows loading indicator while tables load', (tester) async {
    await pumpHomePageScreen(tester, tablesState: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when tables fail to load', (tester) async {
    await pumpHomePageScreen(
      tester,
      tablesState: AsyncError('boom', StackTrace.current),
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows No Items when tables list is empty', (tester) async {
    await pumpHomePageScreen(
      tester,
      tablesState: const AsyncData([]),
      stream: Stream.value(10),
    );

    expect(find.text('No Items'), findsOneWidget);
  });

  testWidgets('renders tables sorted by table number', (tester) async {
    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      stream: const Stream.empty(),
    );

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();

    expect(tiles[0].title.toString(), contains('1'));
    expect(tiles[1].title.toString(), contains('2'));
  });

  testWidgets('tapping Take Order navigates to Orders screen', (tester) async {
    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: Stream.value(0),
    );

    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(Orders), findsOneWidget);
  });

  testWidgets(
    """clear table icon opens confirm dialog and confirm clear calls clearTableConfirm and shows snackbar""",
    (tester) async {
      final fakeVm = FakeTablesViewModel();
      fakeVm.clearTableResult = ClearTableResult.canClear;

      await pumpHomePageScreen(
        tester,
        tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
        fakeVm: fakeVm,
        stream: const Stream.empty(),
      );

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(TableClearDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(fakeVm.confirmedClearKey, '1');
      expect(find.text("Table cleared Successfully..."), findsOneWidget);
    },
  );

  testWidgets('clear table icon shows already cleared snackbar', (
    tester,
  ) async {
    final fakeVm = FakeTablesViewModel();
    fakeVm.clearTableResult = ClearTableResult.alreadyCleared;

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text("Table is already cleared ..."), findsOneWidget);
  });

  testWidgets('clear table icon shows has pending order warning', (
    tester,
  ) async {
    final fakeVm = FakeTablesViewModel();
    fakeVm.clearTableResult = ClearTableResult.hasPendingOrders;

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.byType(TableClearWarningDialog), findsOneWidget);
  });

  testWidgets("""swap table icon opens dialog and shows snackbar on swap""", (
    tester,
  ) async {
    final fakeVm = FakeTablesViewModel();
    fakeVm.lastSwapDecision = SwapTableDecision(
      result: SwapTableResult.canSwap,
      availableTables: const [2],
    );

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(find.byType(TableSwapDialog), findsOneWidget);

    await tester.tap(find.text('Table No. : 2'));
    await tester.pumpAndSettle();

    expect(fakeVm.from, '1');
    expect(fakeVm.to, '2');
    expect(
      find.textContaining('Orders swapped from Table : 1 to Table : 2'),
      findsOneWidget,
    );
  });

  testWidgets('swap table shows no free tables snackbar', (tester) async {
    final fakeVm = FakeTablesViewModel();
    fakeVm.lastSwapDecision = SwapTableDecision(
      result: SwapTableResult.noFreeTables,
    );

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
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
    final fakeVm = FakeTablesViewModel();
    fakeVm.lastSwapDecision = SwapTableDecision(
      result: SwapTableResult.noOrdersAtAll,
    );

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(find.textContaining('All tables are free...!'), findsOneWidget);
  });

  testWidgets("""swap table shows no order on source table snackbar""", (
    tester,
  ) async {
    final fakeVm = FakeTablesViewModel();
    fakeVm.lastSwapDecision = SwapTableDecision(
      result: SwapTableResult.noOrdersOnSource,
    );

    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
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
    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: const Stream.empty(),
    );

    await tester.tap(find.byIcon(Icons.design_services));
    await tester.pumpAndSettle();

    expect(find.byType(TableLayoutScreen), findsOneWidget);
  });

  testWidgets('open navigation drawer', (tester) async {
    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: const Stream.empty(),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
  });

  testWidgets('back button closes drawer when open', (tester) async {
    await pumpHomePageScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      stream: const Stream.empty(),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
  });
}
