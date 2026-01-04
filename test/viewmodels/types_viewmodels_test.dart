import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:order_manager/models/item.dart';
import 'package:order_manager/models/order.dart';
import 'package:order_manager/models/table.dart';
import 'package:order_manager/models/type.dart';
import 'package:order_manager/providers/providers.dart';
import 'package:order_manager/viewmodels/types_viewmodel.dart';

import '../fake_orders_repository.dart';
import '../fake_type_repository.dart';

ProviderContainer createContainer({
  required FakeTypeRepository typeRepo,
  required FakeOrdersRepository ordersRepo,
}) {
  return ProviderContainer(
    overrides: [
      typeRepositoryProvider.overrideWithValue(typeRepo),
      orderRepositoryProvider.overrideWithValue(ordersRepo),
    ],
  );
}

void main() {
  test('saving new type does not update orders', () async {
    final typeRepo = FakeTypeRepository();
    final ordersRepo = FakeOrdersRepository();

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    final newType = Type1(id: '', type: 'Extra', price: 20);

    await vm.saveType(newType);

    expect(ordersRepo.savedOrders, isEmpty);
  });

  test('updating existing type updates related orders', () async {
    final oldType = Type1(id: 't1', type: 'Extra', price: 20);
    final newType = Type1(id: 't1', type: 'Extra', price: 40);

    final typeRepo = FakeTypeRepository()..types = [oldType];

    final item = Item(id: 'i1', name: 'Burger', price: 100);
    final table = Table1(id: 'tb1', tableNo: 1);

    final order = Order(
      id: 'o1',
      quantity: 2,
      item: item,
      table: table,
      type: oldType,
      status: 'open',
      note: '',
      amount: 240,
    );

    final ordersRepo = FakeOrdersRepository()..orders.add(order);

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(newType);

    expect(ordersRepo.savedOrders.length, 1);
  });

  test('order amount is recalculated when type price changes', () async {
    final oldType = Type1(id: 't1', type: 'Extra', price: 10);
    final newType = Type1(id: 't1', type: 'Extra', price: 30);

    final typeRepo = FakeTypeRepository()..types = [oldType];

    final item = Item(id: 'i1', name: 'Burger', price: 100);
    final table = Table1(id: 'tb1', tableNo: 1);

    final order = Order(
      id: 'o1',
      quantity: 3,
      item: item,
      table: table,
      type: oldType,
      status: 'open',
      note: '',
      amount: 0,
    );

    final ordersRepo = FakeOrdersRepository()..orders.add(order);

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(newType);

    final updated = ordersRepo.savedOrders.single;
    final expected = (item.price + newType.price) * order.quantity;

    expect(updated.amount, expected);
    expect(updated.type, newType);
  });

  test(
    'updating type should not update orders if there are no orders',
    () async {
      final type = Type1(id: 'ty1', type: 'Extra', price: 100);
      final newType = Type1(id: 'ty1', type: 'Extra New', price: 100);
      final typeRepo = FakeTypeRepository()..types = [type];
      final ordersRepo = FakeOrdersRepository();
      final container = createContainer(
        typeRepo: typeRepo,
        ordersRepo: ordersRepo,
      );
      final vm = container.read(typesViewModelProvider.notifier);
      await vm.saveType(newType);
      expect(ordersRepo.savedOrders, isEmpty);
    },
  );

  test('orders with different type are not updated', () async {
    final oldType = Type1(id: 't1', type: 'Extra', price: 10);
    final newType = Type1(id: 't1', type: 'Extra', price: 20);

    final typeRepo = FakeTypeRepository()..types = [oldType];

    final otherType = Type1(id: 't2', type: 'None', price: 0);

    final item = Item(id: 'i1', name: 'Burger', price: 100);
    final table = Table1(id: 'tb1', tableNo: 1);

    final unrelatedOrder = Order(
      id: 'o1',
      quantity: 1,
      item: item,
      table: table,
      type: otherType,
      status: 'open',
      note: '',
      amount: 100,
    );

    final ordersRepo = FakeOrdersRepository()..orders.add(unrelatedOrder);

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.saveType(newType);

    expect(ordersRepo.savedOrders, isEmpty);
  });

  test('deleteType delegates to repository', () async {
    final type = Type1(id: 't1', type: 'Extra', price: 20);

    final typeRepo = FakeTypeRepository()..types = [type];
    final ordersRepo = FakeOrdersRepository();

    final container = createContainer(
      typeRepo: typeRepo,
      ordersRepo: ordersRepo,
    );

    final vm = container.read(typesViewModelProvider.notifier);

    await vm.deleteType(type);

    expect(typeRepo.lastDeletedType, type);
  });
}
