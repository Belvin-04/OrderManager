import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/views/tables/table_layout_screen.dart';
import 'package:order_manager/views/tables/table_popup_menu.dart';
import 'package:order_manager/views/tables/table_widget.dart';

import '../fake_viewmodel/fake_tables_viewmodel.dart';

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

Future<void> pumpLayoutWidget(
  WidgetTester tester,
  List<Widget> children,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Stack(children: [Stack(children: children)]),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows loading indicator', (tester) async {
    await pumpTableLayoutScreen(tester, tables: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message', (tester) async {
    await pumpTableLayoutScreen(
      tester,
      tables: AsyncError('error', StackTrace.current),
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('renders tables at their positions', (tester) async {
    final table = Table1(id: 't1', tableNo: 1, position: const Offset(50, 100));

    await pumpTableLayoutScreen(tester, tables: AsyncData([table]));

    final positioned = tester.widget<Positioned>(find.byType(Positioned).last);

    expect(positioned.left, 50);
    expect(positioned.top, 100);
  });

  testWidgets('dragging table updates its position', (tester) async {
    final table = Table1(id: 't1', tableNo: 1, position: const Offset(10, 10));

    final fakeVm = FakeTablesViewModel();

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([table]),
      fakeVm: fakeVm,
    );

    final icon = find.byIcon(Icons.table_restaurant);
    final start = tester.getCenter(icon);

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(80, 120));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(fakeVm.movedId, 't1');
    expect(fakeVm.movedOffset, isNotNull);

    expect(fakeVm.movedOffset!.dx, greaterThan(50));
    expect(fakeVm.movedOffset!.dy, greaterThan(50));

    expect(fakeVm.movedOffset!.dx, 90);
    expect(fakeVm.movedOffset!.dy, 130);
  });

  testWidgets('last table is painted on top (z-order)', (tester) async {
    final t1 = Table1(id: 't1', tableNo: 1, position: const Offset(50, 50));

    final t2 = Table1(id: 't2', tableNo: 2, position: const Offset(50, 50));

    await pumpTableLayoutScreen(tester, tables: AsyncData([t1, t2]));

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

    final fakeVm = FakeTablesViewModel();

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([t1, t2]),
      fakeVm: fakeVm,
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

    expect(fakeVm.movedId, 't2');
  });

  testWidgets('dragging one table does not move the other while overlapped', (
    tester,
  ) async {
    final t1 = Table1(id: 't1', tableNo: 1, position: const Offset(10, 10));

    final t2 = Table1(id: 't2', tableNo: 2, position: const Offset(10, 10));

    final fakeVm = FakeTablesViewModel();

    await pumpTableLayoutScreen(
      tester,
      tables: AsyncData([t1, t2]),
      fakeVm: fakeVm,
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

    expect(fakeVm.movedId, 't2');
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
}
