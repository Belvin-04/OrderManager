import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/bills_provider.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

final testTable = Table1(id: 't', tableNo: 1);

Order baseOrder({
  String id = '',
  int quantity = 1,
  String status = 'pending',
  int amount = 100,
  int splitNo = 0,
  Table1? table,
  Type1? type,
  Item? item,
}) {
  return Order(
    id: id,
    quantity: quantity,
    item: item ?? Item(id: 'i1', name: 'Burger', price: 100),
    type: type ?? Type1(id: 't1', type: 'None', price: 0),
    table:
        table?.copyWith(splitNo: splitNo) ??
        testTable.copyWith(splitNo: splitNo),
    status: status,
    note: '',
    amount: amount,
  );
}

final testOrders = [
  baseOrder(id: '1', status: 'canceled'),
  baseOrder(id: '2', status: 'canceled'),
];

void main() {
  test('billTotalsProvider returns totals from repository', () {
    final mockRepo = MockOrderRepository();

    final orders = [baseOrder(), baseOrder(amount: 200)];

    when(() => mockRepo.getBillTotals(orders)).thenReturn({'total': 300});

    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
        billOrdersProvider('1').overrideWithValue(AsyncData(orders)),
      ],
    );
    addTearDown(container.dispose);

    final totals = container.read(billTotalsProvider('1'));

    expect(totals, {'total': 300});
    verify(() => mockRepo.getBillTotals(orders)).called(1);
  });

  test('billTotalsProvider returns empty totals when no orders', () {
    final mockRepo = MockOrderRepository();

    when(() => mockRepo.getBillTotals([])).thenReturn({});

    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
        billOrdersProvider('1').overrideWithValue(const AsyncData([])),
      ],
    );
    addTearDown(container.dispose);

    final totals = container.read(billTotalsProvider('1'));

    expect(totals, {});
    verify(() => mockRepo.getBillTotals([])).called(1);
  });
}
