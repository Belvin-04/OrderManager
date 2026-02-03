import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/utils/tap_functions.dart';
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';

class MockTableRepository extends Mock implements TableRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeTable1 extends Fake implements Table1 {}

Future<void> pumpTablePopupMenu(
  WidgetTester tester, {
  required MockTableRepository tableRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tableRepositoryProvider.overrideWithValue(tableRepo)],
      child: MaterialApp(
        home: Scaffold(
          body: TablePopupMenu(table: Table1(id: 't1', tableNo: 1)),
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
    final tableRepo = MockTableRepository();
    await pumpTablePopupMenu(tester, tableRepo: tableRepo);

    expect(find.byTooltip('Take Order'), findsOneWidget);
    expect(find.byTooltip('Swap Table Order'), findsOneWidget);
    expect(find.byTooltip('Clear Table'), findsOneWidget);
  });

  testWidgets('tapping on take order popup menu option opens orders page', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    await pumpTablePopupMenu(tester, tableRepo: tableRepo);

    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(Orders), findsOneWidget);
  });

  testWidgets(
    'tapping on swap order popup menu option calls the appropriate function',
    (tester) async {
      final tableRepo = MockTableRepository();

      bool swapCalled = false;

      swapTableOrder = (_, __, ___) async {
        swapCalled = true;
      };

      await pumpTablePopupMenu(tester, tableRepo: tableRepo);

      await tester.tap(find.byTooltip('Swap Table Order'));
      await tester.pump();

      expect(swapCalled, isTrue);
    },
  );

  testWidgets(
    'tapping on clear table popup menu option calls the appropriate function',
    (tester) async {
      bool clearCalled = false;

      clearTable = (_, __, ___) async {
        clearCalled = true;
      };

      final tableRepo = MockTableRepository();

      await pumpTablePopupMenu(tester, tableRepo: tableRepo);

      await tester.tap(find.byTooltip('Clear Table'));
      await tester.pump();

      expect(clearCalled, isTrue);
    },
  );

  testWidgets('tapping take order popup menu option closes the popup menu', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();

    await pumpTablePopupMenu(tester, tableRepo: tableRepo);

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
      () => orderRepo.hasAnyOrdersForTable('t1'),
    ).thenAnswer((_) async => true);
    when(
      () => orderRepo.hasPendingOrdersForTable('t1'),
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
