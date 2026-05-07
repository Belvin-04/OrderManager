import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/business_providers.dart';
import 'package:order_manager/providers/firebase_providers.dart';
import 'package:order_manager/providers/order_providers.dart';
import 'package:order_manager/repositories/abstract_files/order_repository.dart';
import 'package:order_manager/repositories/firebase_order_repository.dart';
import 'package:order_manager/utils/selected_business_notifier.dart';

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
  test('cancelledOrdersProvider emits cancelled orders', () async {
    final mockRepository = MockOrderRepository();

    when(
      () => mockRepository.watchOrdersByStatus('canceled', '1'),
    ).thenAnswer((_) => Stream.value(testOrders));

    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    final completer = Completer<List<Order>>();

    final sub = container.listen(cancelledOrdersProvider('1'), (_, next) {
      if (next is AsyncData<List<Order>>) {
        completer.complete(next.value);
      }
    });

    final result = await completer.future;

    expect(result, testOrders);

    sub.close();
  });

  test('pendingOrdersProvider emits pending orders', () async {
    final mockRepository = MockOrderRepository();

    when(
      () => mockRepository.watchOrdersByStatus('pending', '1'),
    ).thenAnswer((_) => Stream.value(testOrders));

    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    final completer = Completer<List<Order>>();

    final sub = container.listen(pendingOrdersProvider('1'), (_, next) {
      if (next is AsyncData<List<Order>>) {
        completer.complete(next.value);
      }
    });

    final result = await completer.future;

    expect(result, testOrders);

    sub.close();
  });

  test('completedOrdersProvider emits completed orders', () async {
    final mockRepository = MockOrderRepository();

    when(
      () => mockRepository.watchOrdersByStatus('completed', '1'),
    ).thenAnswer((_) => Stream.value(testOrders));

    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);

    final completer = Completer<List<Order>>();

    final sub = container.listen(completedOrdersProvider('1'), (_, next) {
      if (next is AsyncData<List<Order>>) {
        completer.complete(next.value);
      }
    });

    final result = await completer.future;

    expect(result, testOrders);

    sub.close();
  });

  test('orderRepositoryProvider returns FirebaseOrderRepository', () {
    final firestore = FakeFirebaseFirestore();
    final container = ProviderContainer(
      overrides: [
        orderRefProvider.overrideWithValue(firestore.collection('orders')),
        splitOrderRefProvider.overrideWithValue(
          firestore.collection('split-orders'),
        ),
        currentBusinessIdProvider.overrideWithValue('business-test'),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(orderRepositoryProvider);

    expect(repo, isA<FirebaseOrderRepository>());
  });

  test('splitOrderRefProvider returns split-orders collection', () {
    final firestore = FakeFirebaseFirestore();

    final container = ProviderContainer(
      overrides: [
        firebaseFirestoreProvider.overrideWithValue(firestore),
        selectedBusinessProvider.overrideWith(SelectedBusinessNotifier.new),
      ],
    );

    addTearDown(container.dispose);

    final ref = container.read(splitOrderRefProvider);

    expect(ref.path, 'split-orders');
  });
}
