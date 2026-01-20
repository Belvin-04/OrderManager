import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/utils/tap_functions.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/views/orders/orders.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';

import '../fake_viewmodel/fake_tables_viewmodel.dart';

Future<void> pumpTablePopupMenu(
  WidgetTester tester, {
  FakeTablesViewModel? fakeVm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (fakeVm != null) tablesViewmodelProvider.overrideWith(() => fakeVm),
      ],
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
  FakeTablesViewModel? fakeVm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tablesProvider.overrideWithValue(tables),
        if (fakeVm != null) tablesViewmodelProvider.overrideWith(() => fakeVm),
      ],
      child: MaterialApp(home: TableLayoutScreen()),
    ),
  );
}

void main() {
  testWidgets('popup menu contains necessary options', (tester) async {
    await pumpTablePopupMenu(tester);

    expect(find.byTooltip('Take Order'), findsOneWidget);
    expect(find.byTooltip('Swap Table Order'), findsOneWidget);
    expect(find.byTooltip('Clear Table'), findsOneWidget);
  });

  testWidgets('tapping on take order popup menu option opens orders page', (
    tester,
  ) async {
    await pumpTablePopupMenu(tester);

    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(Orders), findsOneWidget);
  });

  testWidgets(
    'tapping on swap order popup menu option calls the appropriate function',
    (tester) async {
      bool swapCalled = false;

      swapTableOrder = (_, __, ___) async {
        swapCalled = true;
      };

      await pumpTablePopupMenu(tester);

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

      await pumpTablePopupMenu(tester);

      await tester.tap(find.byTooltip('Clear Table'));
      await tester.pump();

      expect(clearCalled, isTrue);
    },
  );

  testWidgets('tapping take order popup menu option closes the popup menu', (
    tester,
  ) async {
    await pumpTablePopupMenu(tester);

    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.byIcon(Icons.event_note_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(TablePopupMenu), findsNothing);
  });

  testWidgets(
    'tapping swap table order popup menu option closes the popup menu',
    (tester) async {
      final fakeVm = FakeTablesViewModel();
      fakeVm.lastSwapDecision = SwapTableDecision(
        result: SwapTableResult.canSwap,
      );

      await pumpTableLayoutScreen(
        tester,
        fakeVm: fakeVm,
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
    final fakeVm = FakeTablesViewModel();
    fakeVm.clearTableResult = ClearTableResult.canClear;
    await pumpTableLayoutScreen(
      tester,
      fakeVm: fakeVm,
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
