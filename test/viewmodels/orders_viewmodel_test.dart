import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';

import 'fake_repositories/fake_orders_repository.dart';
import 'fake_repositories/fake_table_repository.dart';

ProviderContainer createContainer(FakeOrdersRepository repo) {
  return ProviderContainer(
    overrides: [orderRepositoryProvider.overrideWithValue(repo)],
  );
}

ProviderContainer createTableContainer(
  FakeOrdersRepository repo,
  FakeTableRepository tableRepo,
) {
  return ProviderContainer(
    overrides: [
      orderRepositoryProvider.overrideWithValue(repo),
      tableRepositoryProvider.overrideWithValue(tableRepo),
    ],
  );
}

final testTable = Table1(id: 't', tableNo: 1);

Order baseOrder({
  String id = '',
  int quantity = 1,
  String status = 'pending',
  int amount = 100,
  int splitNo = 0,
  Table1? table,
  Type1? type,
}) {
  return Order(
    id: id,
    quantity: quantity,
    item: Item(id: 'i', name: 'Burger', price: 100),
    type: type ?? Type1(id: 't', type: 'None', price: 0),
    table:
        table?.copyWith(splitNo: splitNo) ??
        testTable.copyWith(splitNo: splitNo),
    status: status,
    note: '',
    amount: amount,
  );
}

void main() {
  test('saveOrder calculates amount correctly', () async {
    final repo = FakeOrdersRepository();
    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final order = Order(
      id: '',
      quantity: 2,
      item: Item(id: 'i', name: 'Burger', price: 100),
      type: Type1(id: 't', type: 'Extra', price: 20),
      table: Table1(id: 'tb', tableNo: 1),
      status: 'pending',
      note: '',
      amount: 0,
    );

    await vm.saveOrder(order);

    final saved = repo.savedOrders.single;
    expect(saved.amount, 240);
  });

  test('completeOrder sets status to completed', () async {
    final repo = FakeOrdersRepository();
    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final order = baseOrder();

    await vm.completeOrder(order);

    final saved = repo.savedOrders.single;
    expect(saved.status, 'completed');
  });

  test('cancelOrder sets status to canceled', () async {
    final repo = FakeOrdersRepository();
    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final order = baseOrder();

    await vm.cancelOrder(order);

    final saved = repo.savedOrders.single;
    expect(saved.status, 'canceled');
  });

  test('restoreOrder sets status to pending', () async {
    final repo = FakeOrdersRepository();
    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final order = baseOrder(status: 'canceled');

    await vm.restoreOrder(order);

    final saved = repo.savedOrders.single;
    expect(saved.status, 'pending');
  });

  test('repeatOrder resets id and sets status to pending', () async {
    final repo = FakeOrdersRepository();
    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final order = baseOrder(id: 'o1', status: 'completed');

    await vm.repeatOrder(order);

    final saved = repo.savedOrders.single;
    expect(saved.id, '');
    expect(saved.status, 'pending');
  });

  test('restoreAllOrders restores only canceled orders', () async {
    final repo = FakeOrdersRepository()
      ..orders.add(baseOrder(id: '1', status: 'canceled'))
      ..orders.add(baseOrder(id: '2'));

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final result = await vm.restoreAllOrders(testTable);

    expect(result, true);
    expect(repo.savedOrders.length, 1);
    expect(repo.savedOrders.first.status, 'pending');
  });

  test('repeatAllOrders repeats only non-canceled orders', () async {
    final table = Table1(id: 't1', tableNo: 1);
    final item = Item(id: 'i', name: 'Burger', price: 100);
    final type = Type1(id: 't', type: 'None', price: 0);

    final repo = FakeOrdersRepository()
      ..orders.add(
        Order(
          id: 'o1',
          quantity: 1,
          item: item,
          type: type,
          table: table,
          status: 'pending',
          note: '',
          amount: 100,
        ),
      )
      ..orders.add(
        Order(
          id: 'o2',
          quantity: 1,
          item: item,
          type: type,
          table: table,
          status: 'canceled',
          note: '',
          amount: 100,
        ),
      );

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final result = await vm.repeatAllOrders(table);

    expect(result, true);
    expect(repo.savedOrders.length, 1);
    expect(repo.savedOrders.first.id, '');
  });

  test(
    'repeatAllOrders returns false when no non-canceled orders exist',
    () async {
      final repo = FakeOrdersRepository()
        ..orders.add(baseOrder(id: '1', status: 'canceled'));

      final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

      final result = await vm.repeatAllOrders(testTable);

      expect(result, false);
      expect(repo.savedOrders, isEmpty);
    },
  );

  test(
    'restoreAllOrders returns false when no canceled orders exist',
    () async {
      final repo = FakeOrdersRepository()..orders.add(baseOrder(id: '1'));

      final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

      final result = await vm.restoreAllOrders(testTable);

      expect(result, false);
      expect(repo.savedOrders, isEmpty);
    },
  );

  test('getBillOrdersForTable aggregates orders', () async {
    final table = Table1(id: 't', tableNo: 1);
    final item = Item(id: 'i', name: 'Burger', price: 100);
    final type = Type1(id: 't', type: 'Extra', price: 20);

    final repo = FakeOrdersRepository()
      ..orders.add(
        Order(
          id: 'o1',
          quantity: 1,
          item: item,
          type: type,
          table: table,
          status: 'pending',
          note: '',
          amount: 120,
        ),
      )
      ..orders.add(
        Order(
          id: 'o2',
          quantity: 2,
          item: item,
          type: type,
          table: table,
          status: 'completed',
          note: '',
          amount: 240,
        ),
      );

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final aggregated = await vm.getBillOrdersForTable('1').first;

    expect(aggregated.length, 1);
    expect(aggregated.first.quantity, 3);
    expect(aggregated.first.amount, 360);
  });

  test('getBillOrdersForTable separates orders with different types', () async {
    final repo = FakeOrdersRepository()
      ..orders.add(
        baseOrder(
          id: '1',
          type: Type1(id: 't1', type: 'Extra', price: 20),
          amount: 120,
        ),
      )
      ..orders.add(
        baseOrder(
          id: '2',
          type: Type1(id: 't2', type: 'None', price: 0),
        ),
      );

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final bill = await vm.getBillOrdersForTable('1').first;

    expect(bill.length, 2);
  });

  test(
    'createSplitOrders creates one split order when quantity is 1',
    () async {
      final repo = FakeOrdersRepository()..orders.add(baseOrder());

      final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

      final result = await vm.createSplitOrders('1');

      expect(result, true);
      expect(repo.splitOrdersSaved.length, 1);
    },
  );

  test('createSplitOrders splits orders by quantity', () async {
    final table = Table1(id: 't', tableNo: 1);
    final item = Item(id: 'i', name: 'Burger', price: 100);
    final type = Type1(id: 't', type: 'None', price: 0);

    final repo = FakeOrdersRepository()
      ..orders.add(
        Order(
          id: 'o1',
          quantity: 3,
          item: item,
          type: type,
          table: table,
          status: 'pending',
          note: '',
          amount: 300,
        ),
      );

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final result = await vm.createSplitOrders('1');

    expect(result, true);
    expect(repo.splitOrdersSaved.length, 3);
  });

  test('changeOrderSplitNo updates split number correctly', () async {
    final repo = FakeOrdersRepository();
    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final order = baseOrder();

    final result = await vm.changeOrderSplitNo(order, 2);

    expect(result, true);
    final saved = repo.splitOrdersSaved.single;
    expect(saved.table.splitNo, 2);
  });

  test('resetSplitNo resets only matching split orders', () async {
    final repo = FakeOrdersRepository()
      ..splitOrders.add(baseOrder(splitNo: 1))
      ..splitOrders.add(baseOrder(splitNo: 2));

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);
    expect(repo.splitOrders.any((o) => o.table.splitNo == 0), false);
    final result = await vm.resetSplitNo('1', '1');

    expect(result, true);
    expect(repo.splitOrdersSaved.any((o) => o.table.splitNo == 0), true);
    expect(repo.splitOrdersSaved.where((o) => o.table.splitNo == 0).length, 1);
    expect(repo.splitOrdersSaved.every((o) => o.table.splitNo == 0), true);
  });

  test('removeSplitOrdersForTable removes orders for given table', () async {
    final repo = FakeOrdersRepository()
      ..splitOrders.add(
        baseOrder(table: Table1(id: 't1', tableNo: 1, splitNo: 1)),
      )
      ..splitOrders.add(
        baseOrder(table: Table1(id: 't2', tableNo: 2, splitNo: 1)),
      );

    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    final result = await vm.removeSplitOrdersForTable('1');

    expect(result, true);
    expect(repo.splitOrders.any((o) => o.table.tableNo == 1), false);
    expect(repo.splitOrders.any((o) => o.table.tableNo == 2), true);
  });

  test('getTotalAmountForTable delegates stream to repository', () async {
    final repo = FakeOrdersRepository();

    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    final value = await vm.getTotalAmountForTable('1').first;

    expect(value, 250);
  });

  test('clearTableConfirm deletes orders for the given table', () async {
    final repo = FakeOrdersRepository()
      ..orders.add(baseOrder(table: Table1(id: 't1', tableNo: 1)))
      ..orders.add(baseOrder(table: Table1(id: 't2', tableNo: 2)));

    final tableRepo = FakeTableRepository();

    final container = createTableContainer(repo, tableRepo);
    final vm = container.read(tablesViewmodelProvider.notifier);

    await vm.clearTableConfirm('1');

    expect(repo.deletedOrdersForTable, '1');

    expect(repo.orders.any((o) => o.table.tableNo == 1), false);
    expect(repo.orders.any((o) => o.table.tableNo == 2), true);
  });
}
