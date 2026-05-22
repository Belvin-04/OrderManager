import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/repositories/firebase_order_repository.dart';
import '../test_helper.dart';

Map<String, dynamic> fakeOrderMap({
  String id = '1',
  int tableNo = 1,
  int splitNo = 0,
  String status = 'pending',
  int amount = 10,
  int qty = 1,
}) => {
  'businessId': 'biz-1',
  'id': id,
  'status': status,
  'amount': amount,
  'quantity': qty,
  'note': '',
  'table': {
    'id': 't',
    'tableNo': tableNo,
    'splitNo': splitNo,
    'position': {'x': 0, 'y': 0},
  },
  'item': {'id': 'i', 'name': 'Item', 'price': 10},
  'type': {'id': 't', 'type': 'None', 'price': 0},
};

Order fakeOrder({
  String id = '',
  int tableNo = 1,
  int amount = 10,
  int qty = 1,
}) => Order.fromMap(
  fakeOrderMap(id: id, tableNo: tableNo, amount: amount, qty: qty),
);

void main() {
  late MockOrderRemoteDataSource remote;
  late FirebaseOrderRepository repo;

  setUp(() {
    remote = MockOrderRemoteDataSource();
    repo = FirebaseOrderRepository(remote, businessId: 'biz-1');
  });

  test('hasAnyOrdersForTable true when match exists', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
        limitToOne: true,
      ),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    final result = await repo.hasAnyOrdersForTable('1');
    expect(result, true);
  });

  test('hasAnyOrdersForTable false when no match exists', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [3],
        isEqualTo: [true],
        limitToOne: true,
      ),
    ).thenAnswer((_) async => null);

    final result = await repo.hasAnyOrdersForTable('3');
    expect(result, false);
  });

  test(
    'hasAnyOrdersForTable calls split orders for table when isSplit is true',
    () async {
      when(
        () => remote.getOrdersBy(
          fields: ['table.tableNo'],
          values: [1],
          isEqualTo: [true],
          isSplit: true,
          limitToOne: true,
        ),
      ).thenAnswer((_) async => null);

      final result = await repo.hasAnyOrdersForTable('1', isSplit: true);

      verify(
        () => remote.getOrdersBy(
          fields: ['table.tableNo'],
          values: [1],
          isEqualTo: [true],
          isSplit: true,
          limitToOne: true,
        ),
      ).called(1);
      expect(result, false);
    },
  );

  test('hasPendingOrdersForTable true when pending', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo', 'status'],
        values: [1, 'pending'],
        isEqualTo: [true, true],
        limitToOne: true,
      ),
    ).thenAnswer(
      (_) async => {
        '1': {'status': 'pending'},
      },
    );

    final result = await repo.hasPendingOrdersForTable('1');
    expect(result, true);
  });

  test('hasPendingOrdersForTable false when not pending', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo', 'status'],
        values: [1, 'pending'],
        isEqualTo: [true, true],
        limitToOne: true,
      ),
    ).thenAnswer((_) async => null);

    final result = await repo.hasPendingOrdersForTable('1');
    expect(result, false);
  });

  test('getOrdersForTable returns empty list when no orders', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => null);

    final result = await repo.getOrdersForTable('1');

    expect(result, isEmpty);
  });

  test('getOrdersForTable maps results', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    final result = await repo.getOrdersForTable('1');
    expect(result.length, 1);
    expect(result.first.table.tableNo, 1);
  });

  test(
    'getNonCanceledOrdersForTable returns empty list when no orders',
    () async {
      when(
        () => remote.getOrdersBy(
          fields: ['table.tableNo', 'status'],
          values: [1, 'canceled'],
          isEqualTo: [true, false],
        ),
      ).thenAnswer((_) async => null);

      final result = await repo.getNonCanceledOrdersForTable('1');

      expect(result, isEmpty);
    },
  );

  test('getNonCanceledOrdersForTable maps results', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, false],
      ),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    final result = await repo.getNonCanceledOrdersForTable('1');
    expect(result.length, 1);
    expect(result.first.status, 'pending');
    expect(result.first.table.tableNo, 1);
  });

  test('getCanceledOrdersForTable returns empty list when no orders', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, true],
      ),
    ).thenAnswer((_) async => null);

    final result = await repo.getCanceledOrdersForTable('1');

    expect(result, isEmpty);
  });

  test('getCanceledOrdersForTable maps results', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, true],
      ),
    ).thenAnswer((_) async => {'1': fakeOrderMap(status: 'canceled')});

    final result = await repo.getCanceledOrdersForTable('1');
    expect(result.length, 1);
    expect(result.first.status, 'canceled');
    expect(result.first.table.tableNo, 1);
  });

  test('getOrdersByType returns empty list when none found', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['type.type'],
        values: ['None'],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => null);

    final result = await repo.getOrdersByType('None');

    expect(result, isEmpty);
  });

  test('getOrdersByType maps results', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['type.type'],
        values: ['None'],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    final result = await repo.getOrdersByType('None');
    expect(result.length, 1);
  });

  test('getOrdersByItem returns empty list when none found', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['item.name'],
        values: ['Item'],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => null);

    final result = await repo.getOrdersByItem('Item');

    expect(result, isEmpty);
  });

  test('getOrdersByItem maps results', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['item.name'],
        values: ['Item'],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    final result = await repo.getOrdersByItem('Item');
    expect(result.length, 1);
  });

  test('getOccupiedTableNos returns empty set when no orders', () async {
    when(
      () => remote.getOrdersBy(fields: [], values: [], isEqualTo: []),
    ).thenAnswer((_) async => null);

    final result = await repo.getOccupiedTableNos();

    expect(result, isEmpty);
  });

  test('getOccupiedTableNos returns unique table numbers', () async {
    when(
      () => remote.getOrdersBy(fields: [], values: [], isEqualTo: []),
    ).thenAnswer(
      (_) async => {
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2'),
        '3': fakeOrderMap(id: '3', tableNo: 2),
      },
    );

    final result = await repo.getOccupiedTableNos();
    expect(result, {1, 2});
  });

  test('moveOrders does nothing when no orders exist', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => null);

    await repo.moveOrders('1', '2');

    verifyNever(() => remote.updateAllTableNo(any(), any()));
  });

  test('moveOrders updates all matching tables returned', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer(
      (_) async => {'1': fakeOrderMap(), '2': fakeOrderMap(id: '2')},
    );
    when(() => remote.updateAllTableNo(any(), any())).thenAnswer((_) async {});

    await repo.moveOrders('1', '5');

    verify(() => remote.updateAllTableNo(['1', '2'], 5)).called(1);
  });

  test('saveOrder uses existing id when provided', () async {
    when(
      () => remote.save(any(), any(), isSplit: false),
    ).thenAnswer((_) async {});

    final order = fakeOrder(id: 'existing');

    await repo.saveOrder(order);

    verifyNever(() => remote.generateId(isSplit: false));
    verify(() => remote.save('existing', any(), isSplit: false)).called(1);
  });

  test('saveOrder generates id when empty', () async {
    when(
      () => remote.generateId(isSplit: false),
    ).thenAnswer((_) async => 'new');
    when(
      () => remote.save(any(), any(), isSplit: false),
    ).thenAnswer((_) async {});

    await repo.saveOrder(fakeOrder());

    verify(() => remote.save('new', any(), isSplit: false)).called(1);
  });

  test('watchOrdersByStatus returns empty list when stream null', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'pending'],
        isEqualTo: [true, true],
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchOrdersByStatus('pending', '1').first;

    expect(result, isEmpty);
  });

  test('watchOrdersByStatus returns orders', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'pending'],
        isEqualTo: [true, true],
      ),
    ).thenAnswer((_) => Stream.value({'1': fakeOrderMap()}));

    final result = await repo.watchOrdersByStatus('pending', '1').first;
    expect(result.length, 1);
    expect(result.first.status, 'pending');
  });

  test('getBillOrdersForTable returns empty list when stream null', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, false],
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchNonCanceledOrdersForTable('1').first;

    expect(result, isEmpty);
  });

  test('getBillOrdersForTable returns non-canceled orders', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, false],
      ),
    ).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2', status: 'completed'),
      }),
    );

    final result = await repo.watchNonCanceledOrdersForTable('1').first;
    expect(result.length, 2);
  });

  test('getBillTotals sums amount and quantity', () {
    final orders = [fakeOrder(qty: 2), fakeOrder(amount: 20)];

    final totals = repo.getBillTotals(orders);

    expect(totals['amount'], 30);
    expect(totals['quantity'], 3);
  });

  test('removeSplitOrdersForTable returns true when no split orders', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
        isSplit: true,
      ),
    ).thenAnswer((_) async => null);

    final result = await repo.removeSplitOrdersForTable('1');

    expect(result, true);
  });

  test('removeSplitOrdersForTable deletes all split orders', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
        isSplit: true,
      ),
    ).thenAnswer(
      (_) async => {'1': fakeOrderMap(), '2': fakeOrderMap(id: '2')},
    );
    when(() => remote.deleteAll(any(), isSplit: true)).thenAnswer((_) async {});

    final result = await repo.removeSplitOrdersForTable('1');

    expect(result, true);
    verify(() => remote.deleteAll(['1', '2'], isSplit: true)).called(1);
  });

  test('removeSplitOrdersForTable returns false when delete throws', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
        isSplit: true,
      ),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    when(() => remote.deleteAll(any(), isSplit: true)).thenThrow(Exception());

    final result = await repo.removeSplitOrdersForTable('1');

    expect(result, false);
  });

  test('deleteOrdersForTable does nothing when no orders found', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) async => null);

    await repo.deleteOrdersForTable('1');

    verifyNever(() => remote.deleteAll(any(), isSplit: false));
  });

  test('deleteOrdersForTable deletes all orders for table', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer(
      (_) async => {'1': fakeOrderMap(), '2': fakeOrderMap(id: '2')},
    );

    when(
      () => remote.deleteAll(any(), isSplit: false),
    ).thenAnswer((_) async {});

    await repo.deleteOrdersForTable('1');

    verify(() => remote.deleteAll(['1', '2'], isSplit: false)).called(1);
  });

  test('getTotalAmountForTable sums main orders', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, false],
      ),
    ).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2', amount: 20),
      }),
    );

    final result = await repo.getTotalAmountForTable('1').first;

    expect(result, 30);
  });

  test('getTotalAmountForTable returns 0 when stream emits null', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, false],
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.getTotalAmountForTable('1').first;

    expect(result, 0);
  });

  test(
    'getTotalAmountForTable uses split orders when splitNo provided',
    () async {
      when(
        () => remote.watchOrders(
          fields: ['table.tableNo', 'table.splitNo', 'status'],
          values: [1, 1, 'canceled'],
          isEqualTo: [true, true, false],
          isSplit: true,
        ),
      ).thenAnswer(
        (_) => Stream.value({
          '1': fakeOrderMap(splitNo: 1, amount: 15),
          '2': fakeOrderMap(id: '2', splitNo: 1, amount: 25),
        }),
      );

      final result = await repo.getTotalAmountForTable('1', splitNo: '1').first;

      expect(result, 40);
    },
  );

  test('watchSplitOrders returns empty list when no data', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'table.splitNo'],
        values: [1, 0],
        isEqualTo: [true, true],
        isSplit: true,
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchUnassignedSplitOrdersForTable('1').first;

    expect(result, isEmpty);
  });

  test('watchSplitOrders returns splitNo == 0 orders '
      'for the particular table number', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'table.splitNo'],
        values: [1, 0],
        isEqualTo: [true, true],
        isSplit: true,
      ),
    ).thenAnswer((_) => Stream.value({'1': fakeOrderMap()}));

    final result = await repo.watchUnassignedSplitOrdersForTable('1').first;

    expect(result.length, 1);
    expect(result.first.id, '1');
  });

  test('getSplitOrders returns empty list when no data', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'table.splitNo'],
        values: [1, 1],
        isEqualTo: [true, true],
        isSplit: true,
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchAssignedSplitOrdersForTable('1', '1').first;

    expect(result, isEmpty);
  });

  test('getSplitOrders returns all split orders', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'table.splitNo'],
        values: [1, 1],
        isEqualTo: [true, true],
        isSplit: true,
      ),
    ).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(splitNo: 1),
        '2': fakeOrderMap(id: '2', splitNo: 1),
      }),
    );

    final result = await repo.watchAssignedSplitOrdersForTable('1', '1').first;

    expect(result.length, 2);
  });

  test(
    'getOrdersForSplitTable returns empty list when remote returns null',
    () async {
      when(
        () => remote.getOrdersBy(
          fields: ['table.tableNo', 'table.splitNo'],
          values: [1, 1],
          isEqualTo: [true, true],
          isSplit: true,
        ),
      ).thenAnswer((_) async => null);

      final result = await repo.getOrdersForSplitTable('1', '1');

      expect(result, isEmpty);
    },
  );

  test('getOrdersForSplitTable returns matching split orders', () async {
    when(
      () => remote.getOrdersBy(
        fields: ['table.tableNo', 'table.splitNo'],
        values: [1, 1],
        isEqualTo: [true, true],
        isSplit: true,
      ),
    ).thenAnswer(
      (_) async => {
        '1': fakeOrderMap(splitNo: 1),
        '2': fakeOrderMap(id: '2', splitNo: 1),
      },
    );

    final result = await repo.getOrdersForSplitTable('1', '1');

    expect(result.length, 2);
    expect(result.map((e) => e.id), {'1', '2'});
  });

  test('watchOrdersForTable returns empty list when raw is null', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchOrdersForTable('1').first;

    expect(result, isEmpty);
  });

  test('watchOrdersForTable returns orders', () async {
    final rawData = {'1': fakeOrderMap(), '2': fakeOrderMap(id: "2")};

    when(
      () => remote.watchOrders(
        fields: ['table.tableNo'],
        values: [1],
        isEqualTo: [true],
      ),
    ).thenAnswer((_) => Stream.value(rawData));

    final result = await repo.watchOrdersForTable('1').first;

    expect(result.length, 2);
  });

  test('watchPendingOrdersExist returns true when match exists', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'pending'],
        isEqualTo: [true, true],
        limitToOne: true,
      ),
    ).thenAnswer((_) => Stream.value({'1': fakeOrderMap()}));

    final result = await repo.watchPendingOrdersExist('1').first;
    expect(result, true);
  });

  test('watchPendingOrdersExist returns false when no match exists', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'pending'],
        isEqualTo: [true, true],
        limitToOne: true,
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchPendingOrdersExist('1').first;
    expect(result, false);
  });

  test('watchCompletedOrdersExist returns true when match exists', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'completed'],
        isEqualTo: [true, true],
        limitToOne: true,
      ),
    ).thenAnswer((_) => Stream.value({'1': fakeOrderMap(status: 'completed')}));

    final result = await repo.watchCompletedOrdersExist('1').first;
    expect(result, true);
  });

  test(
    'watchCompletedOrdersExist returns false when no match exists',
    () async {
      when(
        () => remote.watchOrders(
          fields: ['table.tableNo', 'status'],
          values: [1, 'completed'],
          isEqualTo: [true, true],
          limitToOne: true,
        ),
      ).thenAnswer((_) => Stream.value(null));

      final result = await repo.watchCompletedOrdersExist('1').first;
      expect(result, false);
    },
  );

  test('watchCanceledOrdersExist returns true when match exists', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, true],
        limitToOne: true,
      ),
    ).thenAnswer((_) => Stream.value({'1': fakeOrderMap(status: 'canceled')}));

    final result = await repo.watchCanceledOrdersExist('1').first;
    expect(result, true);
  });

  test('watchCanceledOrdersExist returns false when no match exists', () async {
    when(
      () => remote.watchOrders(
        fields: ['table.tableNo', 'status'],
        values: [1, 'canceled'],
        isEqualTo: [true, true],
        limitToOne: true,
      ),
    ).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchCanceledOrdersExist('1').first;
    expect(result, false);
  });

  group('saveOrders', () {
    test('does nothing when empty', () async {
      await repo.saveOrders([]);
      verifyNever(() => remote.saveAll(any(), isSplit: any(named: 'isSplit')));
    });

    test('saves orders and generates ids if empty', () async {
      when(
        () => remote.generateId(isSplit: false),
      ).thenAnswer((_) async => 'gen-1');
      when(
        () => remote.saveAll(any(), isSplit: false),
      ).thenAnswer((_) async {});

      final orders = [fakeOrder(), fakeOrder(id: 'existing-id')];

      await repo.saveOrders(orders);

      verify(() => remote.generateId(isSplit: false)).called(1);
      verify(() => remote.saveAll(any(), isSplit: false)).called(1);
    });
  });

  group('deleteOrders', () {
    test('does nothing when empty', () async {
      await repo.deleteOrders([], isSplit: false);
      verifyNever(
        () => remote.deleteAll(any(), isSplit: any(named: 'isSplit')),
      );
    });

    test('deletes all orders', () async {
      when(
        () => remote.deleteAll(any(), isSplit: true),
      ).thenAnswer((_) async {});

      final orders = [fakeOrder(id: 'id-1'), fakeOrder(id: 'id-2')];

      await repo.deleteOrders(orders, isSplit: true);

      verify(() => remote.deleteAll(['id-1', 'id-2'], isSplit: true)).called(1);
    });
  });

  group('deleteOrder', () {
    test('calls remote delete with correct id and isSplit', () async {
      when(
        () => remote.delete(any(), isSplit: any(named: 'isSplit')),
      ).thenAnswer((_) async {});

      final order = fakeOrder(id: 'order-to-delete');

      await repo.deleteOrder(order, isSplit: true);

      verify(() => remote.delete('order-to-delete', isSplit: true)).called(1);
    });
  });
}
