import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/bills_provider.dart';
import 'package:order_manager/providers/order_providers.dart';
import '../test_helper.dart';

ProviderContainer createContainer(MockOrderRepository repo) {
  return ProviderContainer(
    overrides: [orderRepositoryProvider.overrideWithValue(repo)],
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

  test('billOrdersProvider aggregates orders', () async {
    final repo = MockOrderRepository();

    when(() => repo.watchNonCanceledOrdersForTable('1')).thenAnswer(
      (_) => Stream.value([
        baseOrder(amount: 120),
        baseOrder(quantity: 2, amount: 240),
      ]),
    );

    final container = createContainer(repo);

    container.listen(billOrdersProvider('1'), (_, __) {});

    final aggregated = await container.read(billOrdersProvider('1').future);

    expect(aggregated.single.quantity, 3);
    expect(aggregated.single.amount, 360);
  });

  test('billOrdersProvider separates orders with different types', () async {
    final repo = MockOrderRepository();

    when(() => repo.watchNonCanceledOrdersForTable('1')).thenAnswer(
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

    final container = createContainer(repo);

    container.listen(billOrdersProvider('1'), (_, __) {});

    final bill = await container.read(billOrdersProvider('1').future);

    expect(bill.length, 2);
  });
}
