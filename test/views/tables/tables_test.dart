import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';
import 'package:order_manager/views/home_page/home_page.dart';
import 'package:order_manager/views/tables/tables.dart';
import 'package:order_manager/views/tables/tables_warning_dialog.dart';

class MockTableRepository extends Mock implements TableRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class FakeTable1 extends Fake implements Table1 {}

Future<void> pumpTablesScreen(
  WidgetTester tester, {
  required AsyncValue<List<Table1>> tablesState,
  required MockTableRepository tableRepo,
  required MockOrderRepository orderRepo,
}) async {
  when(
    () =>
        orderRepo.getTotalAmountForTable(any(), splitNo: any(named: 'splitNo')),
  ).thenAnswer((_) => const Stream<int>.empty());

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

  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text("Tables"));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(Offset.zero);
    registerFallbackValue(FakeTable1());
  });

  testWidgets('shows loading indicator', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tablesProvider.overrideWithValue(const AsyncLoading())],
        child: const MaterialApp(home: Tables()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    await pumpTablesScreen(
      tester,
      tablesState: AsyncError('boom', StackTrace.current),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('shows No Items when no tables', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    await pumpTablesScreen(
      tester,
      tablesState: const AsyncData([]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.text('No Items'), findsOneWidget);
  });

  testWidgets('renders sorted tables', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    expect(find.text('Table No. : 1'), findsOneWidget);
    expect(find.text('Table No. : 2'), findsOneWidget);
  });

  testWidgets('renders tables sorted by table number', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([
        Table1(id: 't2', tableNo: 2),
        Table1(id: 't1', tableNo: 1),
      ]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();

    expect(tiles[0].title.toString(), contains('1'));
    expect(tiles[1].title.toString(), contains('2'));
  });

  testWidgets('add table button calls addTable and shows snackbar', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(tableRepo.getLastTable).thenAnswer((_) async => null);
    when(() => tableRepo.addTable(any())).thenAnswer((_) async {});

    await pumpTablesScreen(
      tester,
      tablesState: const AsyncData([]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    verify(() => tableRepo.addTable(1)).called(1);
    expect(find.text('Table added successfully...'), findsOneWidget);
  });

  testWidgets('delete table shows no tables snackbar', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(tableRepo.getLastTable).thenAnswer((_) async => null);

    await pumpTablesScreen(
      tester,
      tablesState: const AsyncData([]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('No Tables found...'), findsOneWidget);
  });

  testWidgets('delete table with orders shows warning dialog', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      tableRepo.getLastTable,
    ).thenAnswer((_) async => Table1(id: 't1', tableNo: 1));

    when(
      () => orderRepo.hasAnyOrdersForTable(any()),
    ).thenAnswer((_) async => true);

    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.byType(TablesWarningDialog), findsOneWidget);
  });

  testWidgets('delete table with no orders deletes table and shows snackbar', (
    tester,
  ) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    when(
      tableRepo.getLastTable,
    ).thenAnswer((_) async => Table1(id: 't1', tableNo: 1));

    when(
      () => orderRepo.hasAnyOrdersForTable(any()),
    ).thenAnswer((_) async => false);

    when(() => tableRepo.deleteTableById(any())).thenAnswer((_) async {});

    await pumpTablesScreen(
      tester,
      tablesState: AsyncData([Table1(id: 't1', tableNo: 1)]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text("Table removed successfully..."), findsOneWidget);
  });

  testWidgets('back arrow navigates to HomePage', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    await pumpTablesScreen(
      tester,
      tablesState: const AsyncData([]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('back navigation button redirects to HomePage', (tester) async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();
    await pumpTablesScreen(
      tester,
      tablesState: const AsyncData([]),
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}
