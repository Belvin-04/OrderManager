import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/repositories/abstract_files/remote_data_source/order_remote_data_source.dart';
import 'package:order_manager/repositories/firebase_order_repository.dart';

class MockOrderRemoteDataSource extends Mock implements OrderRemoteDataSource {}

Map<String, dynamic> fakeOrderMap({
  String id = '1',
  int tableNo = 1,
  int splitNo = 0,
  String status = 'pending',
  int amount = 10,
  int qty = 1,
}) => {
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
    repo = FirebaseOrderRepository(remote);
  });

  test('hasAnyOrdersForTable true when match exists', () async {
    when(() => remote.getAllOrders()).thenAnswer(
      (_) async => {'1': fakeOrderMap(), '2': fakeOrderMap(tableNo: 2)},
    );

    final result = await repo.hasAnyOrdersForTable('1');
    expect(result, true);
  });

  test('hasAnyOrdersForTable false when no match exists', () async {
    when(() => remote.getAllOrders()).thenAnswer((_) async => null);

    final result = await repo.hasAnyOrdersForTable('3');
    expect(result, false);
  });

  test('hasPendingOrdersForTable true when pending', () async {
    when(() => remote.queryOrdersByTable(1)).thenAnswer(
      (_) async => {
        '1': {'status': 'pending'},
      },
    );

    final result = await repo.hasPendingOrdersForTable('1');
    expect(result, true);
  });

  test('hasPendingOrdersForTable false when not pending', () async {
    when(() => remote.queryOrdersByTable(1)).thenAnswer((_) async => null);

    final result = await repo.hasPendingOrdersForTable('1');
    expect(result, false);
  });

  test('getOrdersForTable returns empty list when no orders', () async {
    when(() => remote.getAllOrders()).thenAnswer((_) async => null);

    final result = await repo.getOrdersForTable('1');

    expect(result, isEmpty);
  });

  test('getOrdersForTable filters by table', () async {
    when(() => remote.getAllOrders()).thenAnswer(
      (_) async => {'1': fakeOrderMap(), '2': fakeOrderMap(tableNo: 2)},
    );

    final result = await repo.getOrdersForTable('1');
    expect(result.length, 1);
  });

  test('getOrdersByType returns empty list when none found', () async {
    when(() => remote.queryOrdersByType('None')).thenAnswer((_) async => null);

    final result = await repo.getOrdersByType('None');

    expect(result, isEmpty);
  });

  test('getOrdersByType maps results', () async {
    when(
      () => remote.queryOrdersByType('None'),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    final result = await repo.getOrdersByType('None');
    expect(result.length, 1);
  });

  test('getOrdersByItem returns empty list when none found', () async {
    when(() => remote.queryOrdersByItem('Item')).thenAnswer((_) async => null);

    final result = await repo.getOrdersByItem('Item');

    expect(result, isEmpty);
  });

  test('getOrdersByItem maps results', () async {
    when(
      () => remote.queryOrdersByItem('Item'),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    final result = await repo.getOrdersByItem('Item');
    expect(result.length, 1);
  });

  test('getOccupiedTableNos returns empty set when no orders', () async {
    when(() => remote.getAllOrders()).thenAnswer((_) async => null);

    final result = await repo.getOccupiedTableNos();

    expect(result, isEmpty);
  });

  test('getOccupiedTableNos returns unique table numbers', () async {
    when(() => remote.getAllOrders()).thenAnswer(
      (_) async => {
        '1': fakeOrderMap(),
        '2': fakeOrderMap(),
        '3': fakeOrderMap(tableNo: 2),
      },
    );

    final result = await repo.getOccupiedTableNos();
    expect(result, {1, 2});
  });

  test('moveOrders does nothing when no orders exist', () async {
    when(() => remote.getAllOrders()).thenAnswer((_) async => null);

    await repo.moveOrders('1', '2');

    verifyNever(() => remote.updateTableNo(any(), any()));
  });

  test('moveOrders updates only matching tables', () async {
    when(() => remote.getAllOrders()).thenAnswer(
      (_) async => {
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2', tableNo: 2),
      },
    );
    when(() => remote.updateTableNo(any(), any())).thenAnswer((_) async {});

    await repo.moveOrders('1', '5');

    verify(() => remote.updateTableNo('1', 5)).called(1);
    verifyNever(() => remote.updateTableNo('2', any()));
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
    when(() => remote.watchOrders()).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchOrdersByStatus('pending', '1').first;

    expect(result, isEmpty);
  });

  test('watchOrdersByStatus filters', () async {
    when(() => remote.watchOrders()).thenAnswer(
      (_) => Stream.value({'1': fakeOrderMap(), '2': fakeOrderMap(tableNo: 2)}),
    );

    final result = await repo.watchOrdersByStatus('pending', '1').first;
    expect(result.length, 1);
  });

  test('getBillOrdersForTable returns empty list when stream null', () async {
    when(() => remote.watchOrders()).thenAnswer((_) => Stream.value(null));

    final result = await repo.getBillOrdersForTable('1').first;

    expect(result, isEmpty);
  });

  test('getBillOrdersForTable returns pending/completed only', () async {
    when(() => remote.watchOrders()).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(),
        '2': fakeOrderMap(status: 'canceled'),
      }),
    );

    final result = await repo.getBillOrdersForTable('1').first;
    expect(result.length, 1);
  });

  test('getBillTotals sums amount and quantity', () {
    final orders = [fakeOrder(qty: 2), fakeOrder(amount: 20)];

    final totals = repo.getBillTotals(orders);

    expect(totals['amount'], 30);
    expect(totals['quantity'], 3);
  });

  test('removeSplitOrdersForTable returns true when no split orders', () async {
    when(() => remote.getSplitOrdersByTable(1)).thenAnswer((_) async => null);

    final result = await repo.removeSplitOrdersForTable('1');

    expect(result, true);
  });

  test('removeSplitOrdersForTable deletes all split orders', () async {
    when(() => remote.getSplitOrdersByTable(1)).thenAnswer(
      (_) async => {'1': fakeOrderMap(), '2': fakeOrderMap(id: '2')},
    );
    when(() => remote.delete(any(), isSplit: true)).thenAnswer((_) async {});

    final result = await repo.removeSplitOrdersForTable('1');

    expect(result, true);
    verify(() => remote.delete('1', isSplit: true)).called(1);
    verify(() => remote.delete('2', isSplit: true)).called(1);
  });

  test('removeSplitOrdersForTable returns false when delete throws', () async {
    when(
      () => remote.getSplitOrdersByTable(1),
    ).thenAnswer((_) async => {'1': fakeOrderMap()});

    when(() => remote.delete(any(), isSplit: true)).thenThrow(Exception());

    final result = await repo.removeSplitOrdersForTable('1');

    expect(result, false);
  });

  test('deleteOrdersForTable does nothing when no orders found', () async {
    when(() => remote.queryOrdersByTable(1)).thenAnswer((_) async => null);

    await repo.deleteOrdersForTable('1');

    verifyNever(() => remote.delete(any(), isSplit: false));
  });

  test('deleteOrdersForTable deletes all orders for table', () async {
    when(() => remote.queryOrdersByTable(1)).thenAnswer(
      (_) async => {'1': fakeOrderMap(), '2': fakeOrderMap(id: '2')},
    );

    when(() => remote.delete(any(), isSplit: false)).thenAnswer((_) async {});

    await repo.deleteOrdersForTable('1');

    verify(() => remote.delete('1', isSplit: false)).called(1);
    verify(() => remote.delete('2', isSplit: false)).called(1);
  });

  test('getTotalAmountForTable sums main orders', () async {
    when(() => remote.watchOrders()).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2', amount: 20),
        '3': fakeOrderMap(id: '3', tableNo: 2, amount: 50),
      }),
    );

    final result = await repo.getTotalAmountForTable('1').first;

    expect(result, 30);
  });

  test('getTotalAmountForTable ignores canceled orders', () async {
    when(() => remote.watchOrders()).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2', amount: 20, status: 'canceled'),
      }),
    );

    final result = await repo.getTotalAmountForTable('1').first;

    expect(result, 10);
  });

  test('getTotalAmountForTable returns 0 when stream emits null', () async {
    when(() => remote.watchOrders()).thenAnswer((_) => Stream.value(null));

    final result = await repo.getTotalAmountForTable('1').first;

    expect(result, 0);
  });

  test(
    'getTotalAmountForTable uses split orders when splitNo provided',
    () async {
      when(() => remote.watchSplitOrders()).thenAnswer(
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
    when(() => remote.watchSplitOrders()).thenAnswer((_) => Stream.value(null));

    final result = await repo.watchSplitOrders('1').first;

    expect(result, isEmpty);
  });

  test('watchSplitOrders returns only splitNo == 0 orders', () async {
    when(() => remote.watchSplitOrders()).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2', splitNo: 1),
      }),
    );

    final result = await repo.watchSplitOrders('1').first;

    expect(result.length, 1);
    expect(result.first.id, '1');
  });

  test('getSplitOrders returns empty list when no data', () async {
    when(() => remote.watchSplitOrders()).thenAnswer((_) => Stream.value(null));

    final result = await repo.getSplitOrders('1').first;

    expect(result, isEmpty);
  });

  test('getSplitOrders returns all split orders without filtering', () async {
    when(() => remote.watchSplitOrders()).thenAnswer(
      (_) => Stream.value({
        '1': fakeOrderMap(),
        '2': fakeOrderMap(id: '2', splitNo: 1),
      }),
    );

    final result = await repo.getSplitOrders('1').first;

    expect(result.length, 2);
  });
}
