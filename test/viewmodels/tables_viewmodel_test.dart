import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/providers/table_providers.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';
import '../test_helper.dart';

ProviderContainer createContainer({
  required MockTableRepository tableRepo,
  required MockOrderRepository orderRepo,
}) {
  return ProviderContainer(
    overrides: [
      tableRepositoryProvider.overrideWithValue(tableRepo),
      orderRepositoryProvider.overrideWithValue(orderRepo),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTable1());
    registerFallbackValue(FakeOrder());
    registerFallbackValue(Offset.zero);
  });

  void stubTableBase(
    MockTableRepository repo, {
    List<Table1> tables = const [],
  }) {
    when(() => repo.watchTables()).thenAnswer((_) => Stream.value(tables));
  }

  test('addTable starts from 1 when no tables exist', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubTableBase(tableRepo);

    when(tableRepo.getLastTable).thenAnswer((_) async => null);
    when(() => tableRepo.addTable(any())).thenAnswer((_) async {});

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    await vm.addTable();

    verify(() => tableRepo.addTable(1)).called(1);
  });

  test('addTable increments table number', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubTableBase(tableRepo);

    when(
      tableRepo.getLastTable,
    ).thenAnswer((_) async => Table1(id: 't1', tableNo: 1));
    when(() => tableRepo.addTable(any())).thenAnswer((_) async {});

    final container = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final vm = container.read(tablesViewmodelProvider.notifier);

    await vm.addTable();

    verify(() => tableRepo.addTable(2)).called(1);
  });

  test('removeTable returns noTables when no tables exist', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubTableBase(tableRepo);

    when(tableRepo.getLastTable).thenAnswer((_) async => null);

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.removeTable();

    expect(result, RemoveTableResult.noTables);
  });

  test('removeTable returns hasOrders when last table has orders', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final table = Table1(id: 't1', tableNo: 1);

    stubTableBase(tableRepo, tables: [table]);

    when(tableRepo.getLastTable).thenAnswer((_) async => table);
    when(
      () => orderRepo.hasAnyOrdersForTable('1'),
    ).thenAnswer((_) async => true);

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.removeTable();

    expect(result, RemoveTableResult.hasOrders);
  });

  test('removeTable removes last table when it has no orders', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final table = Table1(id: 't1', tableNo: 1);

    stubTableBase(tableRepo, tables: [table]);

    when(tableRepo.getLastTable).thenAnswer((_) async => table);
    when(
      () => orderRepo.hasAnyOrdersForTable('1'),
    ).thenAnswer((_) async => false);
    when(() => tableRepo.deleteTableById(any())).thenAnswer((_) async {});

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.removeTable();

    expect(result, RemoveTableResult.removed);
    verify(() => tableRepo.deleteTableById('t1')).called(1);
  });

  test('clearTable returns alreadyCleared when no orders exist', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubTableBase(tableRepo);

    when(
      () => orderRepo.hasAnyOrdersForTable('1'),
    ).thenAnswer((_) async => false);

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.clearTable('1');

    expect(result, ClearTableResult.alreadyCleared);
  });

  test('clearTable returns hasPendingOrders when pending exists', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubTableBase(tableRepo);

    when(
      () => orderRepo.hasAnyOrdersForTable('1'),
    ).thenAnswer((_) async => true);
    when(
      () => orderRepo.hasPendingOrdersForTable('1'),
    ).thenAnswer((_) async => true);

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.clearTable('1');

    expect(result, ClearTableResult.hasPendingOrders);
  });

  test(
    'clearTable returns canClear when orders exist but none pending',
    () async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      stubTableBase(tableRepo);

      when(
        () => orderRepo.hasAnyOrdersForTable('1'),
      ).thenAnswer((_) async => true);
      when(
        () => orderRepo.hasPendingOrdersForTable('1'),
      ).thenAnswer((_) async => false);

      final vm = createContainer(
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      ).read(tablesViewmodelProvider.notifier);

      final result = await vm.clearTable('1');

      expect(result, ClearTableResult.canClear);
    },
  );

  test('swapTable returns noOrdersAtAll when no orders exist', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final tables = [Table1(id: 't1', tableNo: 1), Table1(id: 't2', tableNo: 2)];

    stubTableBase(tableRepo, tables: tables);

    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => <int>{});

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final decision = await vm.swapTable('1');

    expect(decision.result, SwapTableResult.noOrdersAtAll);
  });

  test(
    'swapTable returns noOrdersOnSource when source has no orders',
    () async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      final tables = [
        Table1(id: 't1', tableNo: 1),
        Table1(id: 't2', tableNo: 2),
      ];

      stubTableBase(tableRepo, tables: tables);

      when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => <int>{2});
      when(() => orderRepo.getOrdersForTable('1')).thenAnswer((_) async => []);

      final vm = createContainer(
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      ).read(tablesViewmodelProvider.notifier);

      final decision = await vm.swapTable('1');

      expect(decision.result, SwapTableResult.noOrdersOnSource);
    },
  );

  test('swapTable returns noFreeTables when no free tables exist', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final tables = [Table1(id: 't1', tableNo: 1), Table1(id: 't2', tableNo: 2)];

    stubTableBase(tableRepo, tables: tables);

    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => <int>{1, 2});
    when(() => orderRepo.getOrdersForTable('1')).thenAnswer(
      (_) async => [
        Order(
          id: "o1",
          table: Table1(tableNo: 1, id: "t1"),
          type: Type1(type: "Extra", price: 100, id: "ty1"),
          quantity: 1,
          status: "pending",
          note: "special",
          item: Item(name: "Burger", price: 100, id: "i1"),
          amount: 200,
        ),
      ],
    );

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final decision = await vm.swapTable('1');

    expect(decision.result, SwapTableResult.noFreeTables);
  });

  test('swapTable returns free tables when swap is possible', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    final tables = [Table1(id: 't1', tableNo: 1), Table1(id: 't2', tableNo: 2)];

    stubTableBase(tableRepo, tables: tables);

    when(orderRepo.getOccupiedTableNos).thenAnswer((_) async => <int>{1});
    when(() => orderRepo.getOrdersForTable('1')).thenAnswer(
      (_) async => [
        Order(
          id: "o1",
          table: Table1(tableNo: 1, id: "t1"),
          type: Type1(type: "Extra", price: 100, id: "ty1"),
          quantity: 1,
          status: "pending",
          note: "special",
          item: Item(name: "Burger", price: 100, id: "i1"),
          amount: 200,
        ),
      ],
    );

    final container = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final vm = container.read(tablesViewmodelProvider.notifier);

    final decision = await vm.swapTable('1');

    expect(decision.result, SwapTableResult.canSwap);
    expect(decision.availableTables, [2]);
  });

  test('confirmSwap delegates to order repository', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubTableBase(tableRepo);

    when(() => orderRepo.moveOrders(any(), any())).thenAnswer((_) async {});

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    await vm.confirmSwap(fromTableKey: '1', toTableKey: '2');

    verify(() => orderRepo.moveOrders('1', '2')).called(1);
  });

  test('updateTablePosition updates repository', () async {
    final tableRepo = MockTableRepository();
    final orderRepo = MockOrderRepository();

    stubTableBase(tableRepo);

    when(
      () => tableRepo.updateTablePosition(any(), any()),
    ).thenAnswer((_) async {});

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    const pos = Offset(50, 100);
    await vm.updateTablePosition('t1', pos);

    verify(() => tableRepo.updateTablePosition('t1', pos)).called(1);
  });

  group('getTableOrderStatus', () {
    test('returns empty when no orders exist', () async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      stubTableBase(tableRepo);

      when(
        () => orderRepo.watchOrdersForTable('1'),
      ).thenAnswer((_) => Stream.value([]));

      final vm = createContainer(
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      ).read(tablesViewmodelProvider.notifier);

      final result = await vm.getTableOrderStatus('1').first;

      expect(result, TableOrderStatus.empty);
    });

    test('returns pending when any order is pending', () async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      stubTableBase(tableRepo);

      when(() => orderRepo.watchOrdersForTable('1')).thenAnswer(
        (_) => Stream.value([
          Order(
            id: "o1",
            table: Table1(tableNo: 1, id: "t1"),
            type: Type1(type: "Extra", price: 100, id: "ty1"),
            quantity: 1,
            status: "pending",
            note: "",
            item: Item(name: "Burger", price: 100, id: "i1"),
            amount: 200,
          ),
        ]),
      );

      final vm = createContainer(
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      ).read(tablesViewmodelProvider.notifier);

      final result = await vm.getTableOrderStatus('1').first;

      expect(result, TableOrderStatus.pending);
    });

    test(
      'returns completed when orders are completed and none pending',
      () async {
        final tableRepo = MockTableRepository();
        final orderRepo = MockOrderRepository();

        stubTableBase(tableRepo);

        when(() => orderRepo.watchOrdersForTable('1')).thenAnswer(
          (_) => Stream.value([
            Order(
              id: "o1",
              table: Table1(tableNo: 1, id: "t1"),
              type: Type1(type: "Extra", price: 100, id: "ty1"),
              quantity: 1,
              status: "completed",
              note: "",
              item: Item(name: "Burger", price: 100, id: "i1"),
              amount: 200,
            ),
          ]),
        );

        final vm = createContainer(
          tableRepo: tableRepo,
          orderRepo: orderRepo,
        ).read(tablesViewmodelProvider.notifier);

        final result = await vm.getTableOrderStatus('1').first;

        expect(result, TableOrderStatus.completed);
      },
    );

    test('returns canceled when orders are canceled only', () async {
      final tableRepo = MockTableRepository();
      final orderRepo = MockOrderRepository();

      stubTableBase(tableRepo);

      when(() => orderRepo.watchOrdersForTable('1')).thenAnswer(
        (_) => Stream.value([
          Order(
            id: "o1",
            table: Table1(tableNo: 1, id: "t1"),
            type: Type1(type: "Extra", price: 100, id: "ty1"),
            quantity: 1,
            status: "canceled",
            note: "",
            item: Item(name: "Burger", price: 100, id: "i1"),
            amount: 200,
          ),
        ]),
      );

      final vm = createContainer(
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      ).read(tablesViewmodelProvider.notifier);

      final result = await vm.getTableOrderStatus('1').first;

      expect(result, TableOrderStatus.canceled);
    });
  });
}
