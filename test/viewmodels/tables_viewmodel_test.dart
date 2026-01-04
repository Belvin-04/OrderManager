import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/tables_viewmodel.dart';

import '../fake_orders_repository.dart';
import '../fake_table_repository.dart';

ProviderContainer createContainer({
  required FakeTableRepository tableRepo,
  required FakeOrdersRepository orderRepo,
}) {
  return ProviderContainer(
    overrides: [
      tableRepositoryProvider.overrideWithValue(tableRepo),
      orderRepositoryProvider.overrideWithValue(orderRepo),
    ],
  );
}

void main() {
  test('addTable starts from 1 when no tables exist', () async {
    final tableRepo = FakeTableRepository();
    final orderRepo = FakeOrdersRepository();

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    await vm.addTable();

    expect(tableRepo.addedTableNo, 1);
  });

  test('addTable increments table number', () async {
    final tableRepo = FakeTableRepository()
      ..tables = [Table1(id: 't1', tableNo: 1)];
    final orderRepo = FakeOrdersRepository();

    final container = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    );

    final vm = container.read(tablesViewmodelProvider.notifier);

    await vm.addTable();

    expect(tableRepo.addedTableNo, 2);
  });

  test('removeTable returns noTables when no tables exist', () async {
    final tableRepo = FakeTableRepository();
    final orderRepo = FakeOrdersRepository();

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.removeTable();

    expect(result, RemoveTableResult.noTables);
  });

  test('removeTable returns hasOrders when last table has orders', () async {
    final table = Table1(id: 't1', tableNo: 1);
    final order = Order(
      id: "o1",
      table: table,
      type: Type1(type: "Extra", price: 100, id: "ty1"),
      quantity: 1,
      status: "pending",
      note: "special",
      item: Item(name: "Burger", price: 100, id: "i1"),
      amount: 200,
    );

    final tableRepo = FakeTableRepository()..tables = [table];
    final orderRepo = FakeOrdersRepository()..orders.add(order);

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.removeTable();

    expect(result, RemoveTableResult.hasOrders);
  });

  test('removeTable removes last table when it has no orders', () async {
    final table = Table1(id: 't1', tableNo: 1);

    final tableRepo = FakeTableRepository()..tables = [table];
    final orderRepo = FakeOrdersRepository();

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.removeTable();

    expect(result, RemoveTableResult.removed);
    expect(tableRepo.deletedTableId, 't1');
  });

  test('clearTable returns alreadyCleared when no orders exist', () async {
    final tableRepo = FakeTableRepository();
    final orderRepo = FakeOrdersRepository();

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final result = await vm.clearTable('1');

    expect(result, ClearTableResult.alreadyCleared);
  });

  test('clearTable returns hasPendingOrders when pending exists', () async {
    final tableRepo = FakeTableRepository();
    final order = Order(
      id: "o1",
      table: Table1(tableNo: 1, id: "t1"),
      type: Type1(type: "Extra", price: 100, id: "ty1"),
      quantity: 1,
      status: "pending",
      note: "special",
      item: Item(name: "Burger", price: 100, id: "i1"),
      amount: 200,
    );
    final orderRepo = FakeOrdersRepository()..orders.add(order);

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
      final tableRepo = FakeTableRepository();
      final order = Order(
        id: "o1",
        table: Table1(tableNo: 1, id: "t1"),
        type: Type1(type: "Extra", price: 100, id: "ty1"),
        quantity: 1,
        status: "completed",
        note: "special",
        item: Item(name: "Burger", price: 100, id: "i1"),
        amount: 200,
      );
      final orderRepo = FakeOrdersRepository()..orders.add(order);

      final vm = createContainer(
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      ).read(tablesViewmodelProvider.notifier);

      final result = await vm.clearTable('1');

      expect(result, ClearTableResult.canClear);
    },
  );

  test('swapTable returns noOrdersAtAll when no orders exist', () async {
    final tableRepo = FakeTableRepository()
      ..tables = [Table1(id: 't1', tableNo: 1), Table1(id: 't2', tableNo: 2)];

    final orderRepo = FakeOrdersRepository();

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
      final tableRepo = FakeTableRepository()
        ..tables = [Table1(id: 't1', tableNo: 1), Table1(id: 't2', tableNo: 2)];

      final order = Order(
        id: "o1",
        table: Table1(tableNo: 2, id: "t2"),
        type: Type1(type: "Extra", price: 100, id: "ty1"),
        quantity: 1,
        status: "pending",
        note: "special",
        item: Item(name: "Burger", price: 100, id: "i1"),
        amount: 200,
      );

      final orderRepo = FakeOrdersRepository()..orders.add(order);

      final vm = createContainer(
        tableRepo: tableRepo,
        orderRepo: orderRepo,
      ).read(tablesViewmodelProvider.notifier);

      final decision = await vm.swapTable('1');

      expect(decision.result, SwapTableResult.noOrdersOnSource);
    },
  );

  test('swapTable returns noFreeTables when no free tables exist', () async {
    final tableRepo = FakeTableRepository()
      ..tables = [Table1(id: 't1', tableNo: 1), Table1(id: 't2', tableNo: 2)];

    final order = Order(
      id: "o1",
      table: Table1(tableNo: 1, id: "t1"),
      type: Type1(type: "Extra", price: 100, id: "ty1"),
      quantity: 1,
      status: "pending",
      note: "special",
      item: Item(name: "Burger", price: 100, id: "i1"),
      amount: 200,
    );
    final anotherOrder = Order(
      id: "o2",
      table: Table1(tableNo: 2, id: "t2"),
      type: Type1(type: "Extra", price: 100, id: "ty1"),
      quantity: 1,
      status: "pending",
      note: "special",
      item: Item(name: "Burger", price: 100, id: "i1"),
      amount: 200,
    );

    final orderRepo = FakeOrdersRepository()
      ..orders.add(order)
      ..orders.add(anotherOrder);

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    final decision = await vm.swapTable('1');

    expect(decision.result, SwapTableResult.noFreeTables);
  });

  test('swapTable returns free tables when swap is possible', () async {
    final tableRepo = FakeTableRepository()
      ..tables = [Table1(id: 't1', tableNo: 1), Table1(id: 't2', tableNo: 2)];

    final order = Order(
      id: "o1",
      table: Table1(tableNo: 1, id: "t1"),
      type: Type1(type: "Extra", price: 100, id: "ty1"),
      quantity: 1,
      status: "pending",
      note: "special",
      item: Item(name: "Burger", price: 100, id: "i1"),
      amount: 200,
    );

    final orderRepo = FakeOrdersRepository()..orders.add(order);

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
    final tableRepo = FakeTableRepository();
    final orderRepo = FakeOrdersRepository();

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    await vm.confirmSwap(fromTableKey: '1', toTableKey: '2');

    expect(orderRepo.movedOrders, {'from': '1', 'to': '2'});
  });

  test('updateTablePosition updates repository', () async {
    final tableRepo = FakeTableRepository();
    final orderRepo = FakeOrdersRepository();

    final vm = createContainer(
      tableRepo: tableRepo,
      orderRepo: orderRepo,
    ).read(tablesViewmodelProvider.notifier);

    const pos = Offset(50, 100);
    await vm.updateTablePosition('t1', pos);

    expect(tableRepo.updatedPositions['t1'], pos);
  });
}
