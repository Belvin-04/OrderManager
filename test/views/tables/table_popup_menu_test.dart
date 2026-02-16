import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/utils/tap_functions.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';

class MockTableRepository extends Mock implements TableRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeTable1 extends Fake implements Table1 {}

Future<void> pumpTablePopupMenu(
  WidgetTester tester, {
  required void Function(TablePopupAction action) onAction,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TablePopupMenu(
          table: Table1(id: 't1', tableNo: 1),
          onAction: onAction,
        ),
      ),
    ),
  );
}

Future<void> pumpTableLayoutScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tables,
  required MockTableRepository tableRepo,
  required MockOrderRepository orderRepo,
}) async {
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
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTable1());
  });
  testWidgets('popup menu contains necessary options', (tester) async {
    await pumpTablePopupMenu(tester, onAction: (_) {});

    expect(find.byTooltip('Take Order'), findsOneWidget);
    expect(find.byTooltip('Swap Table Order'), findsOneWidget);
    expect(find.byTooltip('Clear Table'), findsOneWidget);
  });

  testWidgets('tapping take order emits correct action', (tester) async {
    TablePopupAction? receivedAction;

    await pumpTablePopupMenu(
      tester,
      onAction: (action) {
        receivedAction = action;
      },
    );

    await tester.tap(find.byTooltip('Take Order'));
    await tester.pump();

    expect(receivedAction, TablePopupAction.takeOrder);
  });

  testWidgets('tapping swap emits correct action', (tester) async {
    TablePopupAction? receivedAction;

    await pumpTablePopupMenu(
      tester,
      onAction: (action) {
        receivedAction = action;
      },
    );

    await tester.tap(find.byTooltip('Swap Table Order'));
    await tester.pump();

    expect(receivedAction, TablePopupAction.swap);
  });

  testWidgets('tapping clear emits correct action', (tester) async {
    TablePopupAction? receivedAction;

    await pumpTablePopupMenu(
      tester,
      onAction: (action) {
        receivedAction = action;
      },
    );

    await tester.tap(find.byTooltip('Clear Table'));
    await tester.pump();

    expect(receivedAction, TablePopupAction.clear);
  });

  testWidgets('tapping take order popup menu option closes the popup menu', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      tableRepo.watchTables,
    ).thenAnswer((_) => Stream.value([Table1(tableNo: 1, id: 't1')]));

    await pumpTableLayoutScreen(
      tester,
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      tables: AsyncData([Table1(tableNo: 1, id: 't1')]),
    );

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsNothing);
  });

  testWidgets(
    'tapping swap table order popup menu option closes the popup menu',
    (tester) async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      when(
        tableRepo.watchTables,
      ).thenAnswer((_) => Stream.value([Table1(tableNo: 1, id: 't1')]));
      when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => {});

      await pumpTableLayoutScreen(
        tester,
        tableRepo: tableRepo,
        orderRepo: orderRepo,
        tables: AsyncData([Table1(tableNo: 1, id: 't1')]),
      );

      await tester.tap(find.byIcon(Icons.table_restaurant));
      await tester.pumpAndSettle();

      expect(find.byType(TablePopupMenu), findsOneWidget);

      await tester.tap(find.byTooltip('Swap Table Order'));
      await tester.pumpAndSettle();

      expect(find.byType(TablePopupMenu), findsNothing);
    },
  );

  testWidgets('tapping clear table popup menu option closes the popup menu', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      () => orderRepo.hasAnyOrdersForTable('1'),
    ).thenAnswer((_) async => true);
    when(
      () => orderRepo.hasPendingOrdersForTable('1'),
    ).thenAnswer((_) async => false);

    await pumpTableLayoutScreen(
      tester,
      tableRepo: tableRepo,
      orderRepo: orderRepo,
      tables: AsyncData([Table1(tableNo: 1, id: 't1')]),
    );

    await tester.tap(find.byIcon(Icons.table_restaurant));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsNothing);
  });
}
