import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/tables/tables.dart';
import 'package:order_manager/views/tables/tables_warning_dialog.dart';

import '../fake_viewmodel/fake_tables_viewmodel.dart';

Future<void> pumpTablesScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tablesState,
  FakeTablesViewModel? fakeVm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tablesProvider.overrideWithValue(tablesState),
        if (fakeVm != null) tablesViewmodelProvider.overrideWith(() => fakeVm),
      ],
      child: const MaterialApp(home: Tables()),
    ),
  );
}

void main() {
  testWidgets('shows loading indicator', (tester) async {
    await pumpTablesScreen(tester, tablesState: const AsyncLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message', (tester) async {
    await pumpTablesScreen(
      tester,
      tablesState: AsyncError('boom', StackTrace.current),
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows No Items when no tables', (tester) async {
    await pumpTablesScreen(tester, tablesState: const AsyncData([]));

    expect(find.text('No Items'), findsOneWidget);
  });

  testWidgets('renders sorted tables', (tester) async {
    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
    );

    expect(find.text('Table No. : 1'), findsOneWidget);
    expect(find.text('Table No. : 2'), findsOneWidget);
  });

  testWidgets('renders tables sorted by table number', (tester) async {
    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
    );

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();

    expect(tiles[0].title.toString(), contains('1'));
    expect(tiles[1].title.toString(), contains('2'));
  });

  testWidgets('add table button calls addTable and shows snackbar', (
    tester,
  ) async {
    final fakeVm = FakeTablesViewModel();

    await pumpTablesScreen(
      tester,
      tablesState: const AsyncData([]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(fakeVm.addCalled, true);
    expect(find.text('Table added successfully...'), findsOneWidget);
  });

  testWidgets('delete table shows no tables snackbar', (tester) async {
    final fakeVm = FakeTablesViewModel()
      ..removeResult = RemoveTableResult.noTables;

    await pumpTablesScreen(
      tester,
      tablesState: const AsyncData([]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('No Tables found...'), findsOneWidget);
  });

  testWidgets('delete table with orders shows warning dialog', (tester) async {
    final fakeVm = FakeTablesViewModel()
      ..removeResult = RemoveTableResult.hasOrders;

    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(TablesWarningDialog), findsOneWidget);
  });

  testWidgets('delete table with no orders deletes table and shows snackbar', (
    tester,
  ) async {
    final fakeVm = FakeTablesViewModel()
      ..removeResult = RemoveTableResult.removed;

    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      fakeVm: fakeVm,
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text("Table removed successfully..."), findsOneWidget);
  });

  testWidgets('back arrow navigates to HomePage', (tester) async {
    await pumpTablesScreen(tester, tablesState: const AsyncData([]));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('back navigation button redirects to HomePage', (tester) async {
    await pumpTablesScreen(tester, tablesState: const AsyncData([]));

    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
