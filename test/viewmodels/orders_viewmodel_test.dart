import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/abstract_files/table_repository.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockTableRepository extends Mock implements TableRepository {}

class FakeOrder extends Fake implements Order {}

class FakeTable1 extends Fake implements Table1 {}

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

ProviderContainer createContainer(MockOrderRepository repo) {
  return ProviderContainer(
    overrides: [orderRepositoryProvider.overrideWithValue(repo)],
  );
}

ProviderContainer createTableContainer(
  MockOrderRepository repo,
  MockTableRepository tableRepo,
) {
  return ProviderContainer(
    overrides: [
      orderRepositoryProvider.overrideWithValue(repo),
      tableRepositoryProvider.overrideWithValue(tableRepo),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOrder());
    registerFallbackValue(FakeTable1());
  });

  test('saveOrder calculates amount correctly', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

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

    final captured =
        verify(
              () => repo.saveOrder(captureAny(), isSplit: false),
            ).captured.single
            as Order;

    expect(captured.amount, 240);
  });

  test('completeOrder sets status to completed', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    await vm.completeOrder(baseOrder());

    final captured =
        verify(
              () => repo.saveOrder(captureAny(), isSplit: false),
            ).captured.single
            as Order;

    expect(captured.status, 'completed');
  });

  test('cancelOrder sets status to canceled', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    await vm.cancelOrder(baseOrder());

    final captured =
        verify(
              () => repo.saveOrder(captureAny(), isSplit: false),
            ).captured.single
            as Order;

    expect(captured.status, 'canceled');
  });

  test('restoreOrder sets status to pending', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    await vm.restoreOrder(baseOrder(status: 'canceled'));

    final captured =
        verify(
              () => repo.saveOrder(captureAny(), isSplit: false),
            ).captured.single
            as Order;

    expect(captured.status, 'pending');
  });

  test('repeatOrder resets id and sets status to pending', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    await vm.repeatOrder(baseOrder(id: 'o1', status: 'completed'));

    final captured =
        verify(
              () => repo.saveOrder(captureAny(), isSplit: false),
            ).captured.single
            as Order;

    expect(captured.id, '');
    expect(captured.status, 'pending');
  });

  test('restoreAllOrders restores only canceled orders', () async {
    final repo = MockOrderRepository();

    when(() => repo.getOrdersForTable('1')).thenAnswer(
      (_) async => [baseOrder(id: '1', status: 'canceled'), baseOrder(id: '2')],
    );

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final result = await vm.restoreAllOrders(testTable);

    expect(result, true);
    verify(() => repo.saveOrder(any(), isSplit: false)).called(1);
  });

  test('repeatAllOrders repeats only non-canceled orders', () async {
    final repo = MockOrderRepository();

    when(() => repo.getOrdersForTable('1')).thenAnswer(
      (_) async => [baseOrder(id: '1'), baseOrder(id: '2', status: 'canceled')],
    );

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final result = await vm.repeatAllOrders(testTable);

    expect(result, true);
    verify(() => repo.saveOrder(any(), isSplit: false)).called(1);
  });

  test(
    'repeatAllOrders returns false when no non-canceled orders exist',
    () async {
      final repo = MockOrderRepository();

      when(
        () => repo.getOrdersForTable('1'),
      ).thenAnswer((_) async => [baseOrder(id: '1', status: 'canceled')]);

      when(
        () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
      ).thenAnswer((_) async {});

      final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

      final result = await vm.repeatAllOrders(testTable);

      expect(result, false);
      verifyNever(() => repo.saveOrder(any(), isSplit: false));
    },
  );

  test(
    'restoreAllOrders returns false when no canceled orders exist',
    () async {
      final repo = MockOrderRepository();

      when(
        () => repo.getOrdersForTable('1'),
      ).thenAnswer((_) async => [baseOrder(id: '1')]);

      when(
        () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
      ).thenAnswer((_) async {});

      final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

      final result = await vm.restoreAllOrders(testTable);

      expect(result, false);
      verifyNever(() => repo.saveOrder(any(), isSplit: false));
    },
  );

  test('getBillOrdersForTable aggregates orders', () async {
    final repo = MockOrderRepository();

    when(() => repo.getBillOrdersForTable('1')).thenAnswer(
      (_) => Stream.value([
        baseOrder(amount: 120),
        baseOrder(quantity: 2, amount: 240),
      ]),
    );

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final aggregated = await vm.getBillOrdersForTable('1').first;

    expect(aggregated.single.quantity, 3);
    expect(aggregated.single.amount, 360);
  });

  test('getBillOrdersForTable separates orders with different types', () async {
    final repo = MockOrderRepository();

    when(() => repo.getBillOrdersForTable('1')).thenAnswer(
      (_) => Stream.value([
        baseOrder(
          id: '1',
          type: Type1(id: 't1', type: 'Extra', price: 20),
          amount: 120,
        ),
        baseOrder(
          id: '2',
          type: Type1(id: 't2', type: 'None', price: 0),
        ),
      ]),
    );

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final bill = await vm.getBillOrdersForTable('1').first;

    expect(bill.length, 2);
  });

  test(
    'createSplitOrders creates one split order when quantity is 1',
    () async {
      final repo = MockOrderRepository();

      when(
        () => repo.getBillOrdersForTable('1'),
      ).thenAnswer((_) => Stream.value([baseOrder()]));

      when(() => repo.saveOrder(any(), isSplit: true)).thenAnswer((_) async {});

      final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

      final result = await vm.createSplitOrders('1');

      expect(result, true);
      verify(() => repo.saveOrder(any(), isSplit: true)).called(1);
    },
  );

  test('createSplitOrders splits orders by quantity', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.getBillOrdersForTable('1'),
    ).thenAnswer((_) => Stream.value([baseOrder(quantity: 3)]));

    when(() => repo.saveOrder(any(), isSplit: true)).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final result = await vm.createSplitOrders('1');

    expect(result, true);
    verify(() => repo.saveOrder(any(), isSplit: true)).called(3);
  });

  test('changeOrderSplitNo updates split number correctly', () async {
    final repo = MockOrderRepository();

    when(() => repo.saveOrder(any(), isSplit: true)).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    await vm.changeOrderSplitNo(baseOrder(), 2);

    final captured =
        verify(
              () => repo.saveOrder(captureAny(), isSplit: true),
            ).captured.single
            as Order;

    expect(captured.table.splitNo, 2);
  });

  test('resetSplitNo resets only matching split orders', () async {
    final repo = MockOrderRepository();

    when(() => repo.getSplitOrders('1')).thenAnswer(
      (_) => Stream.value([baseOrder(splitNo: 1), baseOrder(splitNo: 2)]),
    );

    when(() => repo.saveOrder(any(), isSplit: true)).thenAnswer((_) async {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final result = await vm.resetSplitNo('1', '1');

    expect(result, true);
    verify(() => repo.saveOrder(any(), isSplit: true)).called(1);
  });

  test('removeSplitOrdersForTable removes orders for given table', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.removeSplitOrdersForTable('1'),
    ).thenAnswer((_) async => true);

    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    final result = await vm.removeSplitOrdersForTable('1');

    expect(result, true);
    verify(() => repo.removeSplitOrdersForTable('1')).called(1);
  });

  test('getTotalAmountForTable delegates stream to repository', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.getTotalAmountForTable('1', splitNo: '0'),
    ).thenAnswer((_) => Stream.value(250));

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    final value = await vm.getTotalAmountForTable('1').first;

    expect(value, 250);
  });

  test('clearTableConfirm deletes orders for the given table', () async {
    final repo = MockOrderRepository();
    final tableRepo = MockTableRepository();

    when(() => repo.deleteOrdersForTable('1')).thenAnswer((_) async {});

    final container = createTableContainer(repo, tableRepo);
    final vm = container.read(tablesViewmodelProvider.notifier);

    await vm.clearTableConfirm('1');

    verify(() => repo.deleteOrdersForTable('1')).called(1);
  });

  test(
    "getOrdersForSplitTable returns the correct split orders for a table",
    () async {
      final repo = MockOrderRepository();

      when(
        () => repo.getOrdersForSplitTable('1', '1'),
      ).thenAnswer((_) async => [baseOrder(splitNo: 1), baseOrder(splitNo: 1)]);

      final container = createContainer(repo);
      final vm = container.read(ordersViewModelProvider.notifier);

      final orders = await vm.getOrdersForSplitTable(1, 1);

      expect(orders.length, 2);
      expect(orders.any((o) => o.table.splitNo == 0), false);
      expect(orders.any((o) => o.table.splitNo == 1), true);
      expect(orders.any((o) => o.table.splitNo == 2), false);
    },
  );

  test('repeatAllOrders returns false when repeatOrder throws', () async {
    final repo = MockOrderRepository();
    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    when(
      () => repo.getOrdersForTable(any()),
    ).thenAnswer((_) async => [baseOrder()]);

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenThrow(Exception('save failed'));

    final result = await vm.repeatAllOrders(Table1(tableNo: 1, id: 't1'));

    expect(result, false);
  });

  test('restoreAllOrders returns false when restoreOrder throws', () async {
    final repo = MockOrderRepository();
    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    when(
      () => repo.getOrdersForTable(any()),
    ).thenAnswer((_) async => [baseOrder(status: "canceled")]);

    when(
      () => repo.saveOrder(any(), isSplit: any(named: 'isSplit')),
    ).thenThrow(Exception());

    final result = await vm.restoreAllOrders(Table1(tableNo: 1, id: 't1'));

    expect(result, false);
  });

  test('createSplitOrders returns false when saveOrder throws', () async {
    final repo = MockOrderRepository();
    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    when(
      () => repo.getBillOrdersForTable(any()),
    ).thenAnswer((_) => Stream.value([baseOrder(quantity: 2)]));

    when(() => repo.saveOrder(any(), isSplit: true)).thenThrow(Exception());

    final result = await vm.createSplitOrders("1");

    expect(result, false);
  });

  test('changeOrderSplitNo returns false when saveOrder throws', () async {
    final repo = MockOrderRepository();
    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    when(() => repo.saveOrder(any(), isSplit: true)).thenThrow(Exception());

    final result = await vm.changeOrderSplitNo(baseOrder(), 2);

    expect(result, false);
  });

  test('resetSplitNo returns false when saveOrder throws', () async {
    final repo = MockOrderRepository();
    final container = createContainer(repo);
    final vm = container.read(ordersViewModelProvider.notifier);

    when(
      () => repo.getSplitOrders(any()),
    ).thenAnswer((_) => Stream.value([baseOrder()]));

    when(() => repo.saveOrder(any(), isSplit: true)).thenThrow(Exception());

    final result = await vm.resetSplitNo("1", "0");

    expect(result, false);
  });

  test('deleteOrder delegates stream to repository', () async {
    final repo = MockOrderRepository();

    when(
      () => repo.deleteOrder(any(), isSplit: false),
    ).thenAnswer((_) async => {});

    final vm = createContainer(repo).read(ordersViewModelProvider.notifier);

    await vm.deleteOrder(baseOrder());

    verify(() => repo.deleteOrder(any(), isSplit: false)).called(1);
  });
}
